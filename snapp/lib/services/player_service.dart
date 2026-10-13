import 'dart:async';

import 'package:background_task/background_task.dart';
import 'package:flutter/foundation.dart';
import '../data/scene_models.dart';
import '../data/seed_data.dart';
import '../data/sound_models.dart';
import 'app_storage.dart';
import 'audio_engine.dart';
import 'stats_service.dart';

/// 单条音轨（对应原型 usePlayer 的 `Track`）。
class PlayerTrack {
  final String id;
  final String name;
  final String iconName;
  final String color;
  int volume;
  bool muted;

  PlayerTrack({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    this.volume = 50,
    this.muted = false,
  });
}

/// 最近播放记录（对应原型 `RecentItem`，storage key `shengqi-recent`）。
class RecentItem {
  final String sceneId;
  final String name;
  final String iconName;
  final String gradient;
  final int ts;

  const RecentItem({
    required this.sceneId,
    required this.name,
    required this.iconName,
    required this.gradient,
    required this.ts,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sceneId': sceneId,
        'name': name,
        'iconName': iconName,
        'gradient': gradient,
        'ts': ts,
      };

  static RecentItem fromJson(Map<String, dynamic> j) => RecentItem(
        sceneId: j['sceneId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        iconName: j['iconName'] as String? ?? 'moon',
        gradient: j['gradient'] as String? ?? '',
        ts: (j['ts'] as num?)?.toInt() ?? 0,
      );
}

/// 声栖 · 共享播放状态（`composables/usePlayer.ts` 的 ChangeNotifier 移植）。
///
/// 模块级单例语义经 Provider 全局注入实现：首页大播放卡 / 场景网格 /
/// 底部 PlayBar 读写同一状态。音频引擎经 [AudioEngine] 接入：有合成资产的
/// 音轨走真实播放，其余静默模拟；平台插件缺失时引擎整体降级为静默。
class PlayerService extends ChangeNotifier {
  PlayerService({StatsService? stats, AudioEngine? engine})
      : _stats = stats,
        _engine = engine ?? JustAudioEngine();

  static const int _recentMax = 10;

  /// 统计服务（可选注入）：每次应用场景时记录一次播放。
  final StatsService? _stats;

  /// 音频引擎（注入或默认 just_audio；测试环境自动降级为静默）。
  final AudioEngine _engine;

  Scene? currentScene;
  List<PlayerTrack> tracks = <PlayerTrack>[];
  bool isPlaying = false;
  int timerMinutes = 0;
  int fadeMinutes = 2;
  bool showTimerPanel = false;
  bool showMixPanel = false;

  /// 睡眠定时剩余秒数（>0 表示倒计时进行中；0 表示未启用）。
  int remainingSeconds = 0;

  /// 播放锁（PlayBar / 播放页共享）：仅 UI 态 + toast，不改变播放行为。
  bool isLocked = false;

  Timer? _countdownTimer;

  /// 是否处于睡眠倒计时末段「渐隐淡出」阶段（UI 据此做柔和提示）。
  bool _fading = false;

  /// 每轨淡出起点基准音量（0–1，muted 轨按 0）；取消时据此恢复。
  final Map<String, double> _fadeBase = <String, double>{};

  /// 历史最高同时加载音轨数（成就「混音大师」数据源）。
  int maxTrackCount = 0;

  /// 是否曾在 22:00-02:00 时段播放（成就「午夜电台」数据源）。
  bool nightPlayRecorded = false;

  /// 定时器是否完整走完一次（成就「初次入眠」数据源，由播放页定时完成时置 true）。
  bool timerCompleted = false;

  /// 场景页交接：首页「更多」带入的分类（v1 pendingSceneCategory 流程）
  String pendingSceneCategory = 'all';

  /// 最近播放（内存态 + 本地持久化）
  List<RecentItem> recent = <RecentItem>[];

  /// 应用启动时恢复最近播放记录。
  Future<void> loadRecent() async {
    final list = await AppStorage.readJsonListOfMaps(AppStorage.keyRecent);
    if (list == null) return;
    recent = list.map((Map<String, dynamic> j) => RecentItem.fromJson(j)).toList();
    notifyListeners();
  }

  Sound? findSound(String id) {
    for (final s in sounds) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// 应用场景：按 soundIds 重建音轨并开始播放，同时写入最近记录并上报统计。
  void applyScene(Scene scene) {
    currentScene = scene;
    tracks = scene.soundIds.map((String id) {
      final s = findSound(id);
      return PlayerTrack(
        id: s?.id ?? id,
        name: s?.name ?? id,
        iconName: s?.iconName ?? 'wave',
        color: s?.color ?? '#8296A8',
      );
    }).toList();
    if (tracks.length > maxTrackCount) maxTrackCount = tracks.length;
    final now = DateTime.now();
    if (now.hour >= 22 || now.hour < 2) nightPlayRecorded = true;
    isPlaying = true;
    // 引擎侧：清空旧轨，按合成资产逐个加载（无资产音轨保持静默）。
    unawaited(_engine.disposeAll());
    for (final PlayerTrack t in tracks) {
      unawaited(_engine.loadTrack(t.id, audioAssetFor(t.id)));
    }
    unawaited(_engine.play());
    // OHOS：开始播放即申请 audioPlayback 长时任务（退后台持续播放 + 通知栏播放条）。
    unawaited(BackgroundTask.start());
    pushRecent(scene);
    _stats?.recordPlay(scene.id);
    notifyListeners();
  }

  /// 播放/暂停；无音轨时返回 false，由调用方 toast 提示。
  bool togglePlay() {
    if (tracks.isEmpty) return false;
    isPlaying = !isPlaying;
    if (isPlaying) {
      unawaited(_engine.play());
      // 恢复播放 → 重新申请长时任务。
      unawaited(BackgroundTask.start());
    } else {
      unawaited(_engine.pause());
      // 暂停播放(系统无音频在跑) → 释放长时任务，避免被系统以"未在播放"取消。
      unawaited(BackgroundTask.stop());
    }
    notifyListeners();
    return true;
  }

  void setTrackVolume(String id, int volume) {
    for (final t in tracks) {
      if (t.id == id) {
        t.volume = volume.clamp(0, 100).toInt();
        unawaited(_engine.setVolume(id, t.volume / 100));
        break;
      }
    }
    // 原地改了 track 对象，需重建列表实例，否则 context.select((p)=>p.tracks)
    // 按引用比较不会触发重建，界面读不到新音量。
    tracks = List<PlayerTrack>.of(tracks);
    notifyListeners();
  }

  void toggleTrackMute(String id) {
    for (final t in tracks) {
      if (t.id == id) {
        t.muted = !t.muted;
        unawaited(_engine.setMute(id, t.muted));
        break;
      }
    }
    // 同 setTrackVolume：重建列表实例使 select((p)=>p.tracks) 生效。
    tracks = List<PlayerTrack>.of(tracks);
    notifyListeners();
  }

  void removeTrack(String id) {
    tracks = tracks.where((PlayerTrack t) => t.id != id).toList();
    unawaited(_engine.disposeTrack(id));
    if (tracks.isEmpty) {
      isPlaying = false;
      // 全部音轨移除 → 无音频可播，释放长时任务。
      unawaited(BackgroundTask.stop());
    }
    notifyListeners();
  }

  /// 定时：重复点击同一时长则取消（启用/取消真实倒计时）。
  void setTimer(int minutes) {
    if (timerMinutes == minutes) {
      stopCountdown();
      timerMinutes = 0;
      notifyListeners();
      return;
    }
    timerMinutes = minutes;
    startCountdown(minutes);
  }

  /// 启动睡眠倒计时：每秒递减；进入最后 fade 段将逐轨音量平滑降到 0，
  /// 到点暂停停止并解锁「初次入眠」成就数据源。
  void startCountdown(int minutes) {
    _countdownTimer?.cancel();
    if (minutes <= 0) {
      remainingSeconds = 0;
      _fading = false;
      _fadeBase.clear();
      return;
    }
    remainingSeconds = minutes * 60;
    _fading = false;
    // 清理淡出残留：把每轨引擎音量恢复基准，避免「淡出中改长时长」残留低音量/pop。
    _restoreTrackVolumes();
    // 淡出持续时长 = min(fadeMinutes, timerMinutes) 分钟（超短定时也整体淡出）。
    final fadeSeconds = (fadeMinutes < minutes ? fadeMinutes : minutes) * 60;
    // 淡出窗口覆盖整个倒计时（如 1 分钟定时 + 1 分钟淡入）→ 立即进入淡出。
    if (fadeSeconds >= remainingSeconds) {
      _fading = true;
      _enterFade();
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      remainingSeconds--;
      if (fadeSeconds > 0 && remainingSeconds <= fadeSeconds && !_fading) {
        _fading = true;
        _enterFade();
      }
      if (_fading) {
        final progress =
            1 - (remainingSeconds.clamp(0, fadeSeconds) / fadeSeconds);
        for (final PlayerTrack t in tracks) {
          final base = _fadeBase[t.id] ?? (t.muted ? 0 : t.volume / 100);
          unawaited(_engine.setVolume(t.id, base * (1 - progress)));
        }
      }
      if (remainingSeconds <= 0) {
        remainingSeconds = 0;
        timerMinutes = 0;
        _countdownTimer?.cancel();
        _countdownTimer = null;
        _fading = false;
        _fadeBase.clear();
        isPlaying = false;
        timerCompleted = true;
        // 淡出后暂停引擎（原实现缺失，避免静默常驻）。
        unawaited(_engine.pause());
        // 恢复每轨引擎基准音量：下次重新播放从基准发声，而非从 0（静音）开始。
        _restoreTrackVolumes();
        // 睡眠定时到点停止播放 → 释放长时任务。
        unawaited(BackgroundTask.stop());
      }
      notifyListeners();
    });
  }

  /// 进入淡出段时记录每轨基准音量作为渐变起点。
  void _enterFade() {
    _fadeBase.clear();
    for (final PlayerTrack t in tracks) {
      _fadeBase[t.id] = t.muted ? 0 : t.volume / 100;
    }
  }

  /// 把每轨引擎音量恢复到其原始基准（muted 轨按 0），弃置淡出残留。
  void _restoreTrackVolumes() {
    for (final PlayerTrack t in tracks) {
      unawaited(_engine.setVolume(t.id, t.muted ? 0 : t.volume / 100));
    }
  }

  /// 取消睡眠倒计时并清零剩余秒数；恢复淡出前的每轨基准音量。
  void stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    remainingSeconds = 0;
    _fading = false;
    for (final MapEntry<String, double> e in _fadeBase.entries) {
      unawaited(_engine.setVolume(e.key, e.value));
    }
    _fadeBase.clear();
  }

  /// 播放锁切换（toast 由调用方展示）。
  void toggleLock() {
    isLocked = !isLocked;
    notifyListeners();
  }

  /// 定时显示标签：倒计时进行中显示 `mm:ss`，否则显示 `n分钟`。
  String get timerLabel {
    if (remainingSeconds > 0) {
      final m = remainingSeconds ~/ 60;
      final s = remainingSeconds % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    if (timerMinutes > 0) return '$timerMinutes分钟';
    return '';
  }

  /// 当前是否处于淡出段（进入最后 min(fadeMinutes, timerMinutes) 分钟）。
  bool get fading => _fading;

  void setFadeMinutes(int minutes) {
    if (fadeMinutes == minutes) return;
    fadeMinutes = minutes;
    notifyListeners();
  }

  void setShowTimerPanel(bool v) {
    if (showTimerPanel == v) return;
    showTimerPanel = v;
    if (v) showMixPanel = false;
    notifyListeners();
  }

  void setShowMixPanel(bool v) {
    if (showMixPanel == v) return;
    showMixPanel = v;
    if (v) showTimerPanel = false;
    notifyListeners();
  }

  /* ------------------------- 最近使用（本地存储） ------------------------- */

  void pushRecent(Scene scene) {
    final list =
        recent.where((RecentItem i) => i.sceneId != scene.id).toList();
    list.insert(
      0,
      RecentItem(
        sceneId: scene.id,
        name: scene.name,
        iconName: scene.iconName,
        gradient: scene.gradient,
        ts: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    recent = list.take(_recentMax).toList();
    AppStorage.writeJsonList(
        AppStorage.keyRecent, recent.map((RecentItem r) => r.toJson()).toList());
  }

  /// 清空最近播放记录（历史页「清空历史」），写回存储。
  void clearRecent() {
    recent = <RecentItem>[];
    AppStorage.writeJsonList(AppStorage.keyRecent, const <Map<String, dynamic>>[]);
    notifyListeners();
  }

  /// 时间标签：刚刚 / n分钟前 / n小时前 / 昨晚 / n天前
  static String recentTimeLabel(int ts) {
    final diff = DateTime.now().millisecondsSinceEpoch - ts;
    final m = (diff / 60000).floor();
    if (m < 1) return '刚刚';
    if (m < 60) return '$m分钟前';
    final h = (m / 60).floor();
    if (h < 8) return '$h小时前';
    if (h < 24) return '昨晚';
    final d = (h / 24).floor();
    return '$d天前';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    unawaited(_engine.disposeAll());
    super.dispose();
  }
}
