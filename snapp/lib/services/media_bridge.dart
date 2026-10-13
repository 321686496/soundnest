import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_controller/media_controller.dart';

import '../data/scene_models.dart';
import '../data/seed_data.dart' show homeScenes;
import 'custom_scene_service.dart';
import 'player_service.dart';

/// 播放状态的不可变快照（去重推送用）。
@immutable
class _MediaSnapshot {
  const _MediaSnapshot({
    required this.title,
    required this.artist,
    required this.isPlaying,
    required this.color1,
    required this.color2,
    required this.sceneId,
  });

  final String title;
  final String artist;
  final bool isPlaying;
  final String color1;
  final String color2;
  final String sceneId;

  String get key => '$title|$artist|$isPlaying|$color1|$color2|$sceneId';
}

/// 声栖 · OHOS 媒体桥。
///
/// 双向桥接 [PlayerService] 与原生 [MediaController]：
/// - 下行：监听播放状态（场景名/音轨摘要/播放态/渐变主色），去重后推送
///   原生 → AVSession（通知栏播放条）+ 桌面音乐卡片；
/// - 上行：接收通知栏/卡片播控命令（play/pause/playPause/playNext/
///   playPrevious）→ 控制 [PlayerService]；无音轨时按最近播放恢复场景。
///
/// 非 OHOS 平台原生通道缺失，所有调用在插件内静默降级，桥为空转。
class MediaBridge {
  MediaBridge({CustomSceneService? customScenes})
      : _customScenes = customScenes;

  /// 默认渐变主色（品牌深森林绿，取自原型 uni.scss 品牌色系）。
  static const String _fallbackColor1 = '#3D6B5E';
  static const String _fallbackColor2 = '#2C4B41';

  static final RegExp _hexPattern = RegExp(r'#([0-9A-Fa-f]{6})');

  final CustomSceneService? _customScenes;

  PlayerService? _player;
  _MediaSnapshot? _last;

  /// 最近列表的稳定序快照：连续 next/prev 期间沿用首次的顺序。
  ///
  /// [PlayerService.applyScene] 会把刚播场景顶到最近记录首位（pushRecent），
  /// 若每次都按实时列表计算，连续切换会在两个场景间来回摆动、无法循环。
  /// 集合内容未变（仅顺序重排）时沿用快照，保证循环语义。
  List<String> _stableRecentIds = const <String>[];

  /// 挂载播放服务并建立双向桥接。
  ///
  /// 须在 [PlayerService.loadRecent] 完成后调用（卡片恢复依赖最近记录）。
  void attach(PlayerService player) {
    if (_player != null) return;
    _player = player;
    unawaited(MediaController.init());
    MediaController.commands.listen(_onCommand);
    player.addListener(_onPlayerChanged);
    _onPlayerChanged();
  }

  /* ------------------------------ 状态下行 ------------------------------ */

  void _onPlayerChanged() {
    final player = _player;
    if (player == null) return;
    final snapshot = _snapshotOf(player);
    if (_last != null && _last!.key == snapshot.key) return;
    _last = snapshot;
    unawaited(MediaController.updatePlayback(
      title: snapshot.title,
      artist: snapshot.artist,
      isPlaying: snapshot.isPlaying,
      color1: snapshot.color1,
      color2: snapshot.color2,
      sceneId: snapshot.sceneId,
    ));
  }

  _MediaSnapshot _snapshotOf(PlayerService player) {
    final scene = player.currentScene;
    final hasTracks = player.tracks.isNotEmpty;
    return _MediaSnapshot(
      title: scene?.name ?? '声栖',
      artist: hasTracks
          ? player.tracks.map((PlayerTrack t) => t.name).join(' · ')
          : '白噪音 · 混音助眠',
      isPlaying: hasTracks && player.isPlaying,
      color1: _gradientColor(scene?.gradient, 0, _fallbackColor1),
      color2: _gradientColor(scene?.gradient, 1, _fallbackColor2),
      sceneId: scene?.id ?? '',
    );
  }

  /// 解析原型 gradient 字符串（`linear-gradient(135deg, #A, #B)`）中的主色。
  static String _gradientColor(String? gradient, int index, String fallback) {
    if (gradient == null) return fallback;
    final matches = _hexPattern.allMatches(gradient).toList();
    if (matches.isEmpty) return fallback;
    final i = index.clamp(0, matches.length - 1);
    return '#${matches[i].group(1)}';
  }

  /* ------------------------------ 命令上行 ------------------------------ */

  void _onCommand(String method) {
    switch (method) {
      case 'play':
        if (_player?.isPlaying != true) _toggle();
        break;
      case 'pause':
        if (_player?.isPlaying == true) _toggle();
        break;
      case 'playPause':
        _toggle();
        break;
      case 'playNext':
        _shiftRecent(1);
        break;
      case 'playPrevious':
        _shiftRecent(-1);
        break;
    }
  }

  void _toggle() {
    final player = _player;
    if (player == null) return;
    if (player.tracks.isEmpty) {
      // 通知栏/卡片恢复播放：无音轨时按最近记录恢复场景；
      // 无任何最近记录时退回首个预设场景，保证播控可用。
      if (_restoreRecentScene() == null) {
        player.applyScene(homeScenes.first);
      }
      return;
    }
    player.togglePlay();
  }

  /// 恢复最近一次播放的场景（内置预设 + 自定义场景都参与查找）。
  Scene? _restoreRecentScene() {
    final player = _player;
    if (player == null || player.recent.isEmpty) return null;
    final scene = _resolveScene(player.recent.first.sceneId);
    if (scene != null) {
      player.applyScene(scene);
      return scene;
    }
    return null;
  }

  /// 在最近播放列表中循环切换场景并应用。
  void _shiftRecent(int direction) {
    final player = _player;
    if (player == null || player.recent.isEmpty) {
      _toggle();
      return;
    }
    final ids =
        player.recent.map((RecentItem r) => r.sceneId).toSet().toList();
    // 集合未变（仅被 pushRecent 重排）时沿用稳定序快照。
    final sameSet = _stableRecentIds.length == ids.length &&
        ids.every((String id) => _stableRecentIds.contains(id));
    if (!sameSet) {
      _stableRecentIds = List<String>.of(ids);
    }
    final stable = _stableRecentIds;
    final currentId = player.currentScene?.id ?? stable.first;
    final index = stable.indexOf(currentId);
    // 当前场景不在最近列表（如刚创建未入列）时从头切换。
    final next = (index < 0 ? 0 : index + direction) % stable.length;
    final scene = _resolveScene(stable[next]);
    if (scene != null) {
      player.applyScene(scene);
    }
  }

  Scene? _resolveScene(String id) {
    for (final Scene s in homeScenes) {
      if (s.id == id) return s;
    }
    return _customScenes?.findById(id);
  }
}
