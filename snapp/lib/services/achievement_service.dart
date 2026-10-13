import 'dart:async';

import 'package:flutter/foundation.dart';

import '../theme/theme_notifier.dart';
import '../theme/theme_tokens.dart';
import 'app_storage.dart';
import 'checkin_service.dart';
import 'custom_scene_service.dart';
import 'player_service.dart';
import 'stats_service.dart';

/// 成就条目模型（对照原型 `pages/achievement/achievement.vue` 的 `Achievement`）。
class Achievement {
  final String id;
  final String name;
  final String desc;
  final String iconName;
  final bool unlocked;

  /// 解锁日期（YYYY-MM-DD，未解锁为 null）。
  final String? date;

  const Achievement({
    required this.id,
    required this.name,
    required this.desc,
    required this.iconName,
    required this.unlocked,
    this.date,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'date': date};
}

/// 成就服务：8 项成就（对照原型），`unlocked` 由真实数据评估得出。
///
/// 构造时订阅各数据源（播放 / 打卡 / 自定义场景 / 统计 / 主题）的变更，
/// 任一状态变化即重新 [evaluate]，新解锁项持久化 key `shengqi-achievements`。
class AchievementService extends ChangeNotifier {
  AchievementService({
    required PlayerService player,
    required CheckinService checkin,
    required CustomSceneService customScenes,
    required StatsService stats,
    required ThemeNotifier themeNotifier,
  })  : _player = player,
        _checkin = checkin,
        _customScenes = customScenes,
        _stats = stats,
        _themeNotifier = themeNotifier {
    player.addListener(evaluate);
    checkin.addListener(evaluate);
    customScenes.addListener(evaluate);
    stats.addListener(evaluate);
    themeNotifier.addListener(evaluate);
  }

  final PlayerService _player;
  final CheckinService _checkin;
  final CustomSceneService _customScenes;
  final StatsService _stats;
  final ThemeNotifier _themeNotifier;

  /// 成就定义（id / 名称 / 描述 / 图标，与原型一致）。
  static const List<Achievement> _defs = <Achievement>[
    Achievement(id: 'a1', name: '初次入眠', desc: '首次使用定时器完成播放', iconName: 'moon', unlocked: false),
    Achievement(id: 'a2', name: '连续七天', desc: '连续 7 天使用白噪音', iconName: 'flame', unlocked: false),
    Achievement(id: 'a3', name: '声音调音师', desc: '创建 5 个自定义场景', iconName: 'mixer', unlocked: false),
    Achievement(id: 'a4', name: '分享达人', desc: '成功邀请 3 位好友', iconName: 'share', unlocked: false),
    Achievement(id: 'a5', name: '百日坚持', desc: '累计使用 100 天', iconName: 'check', unlocked: false),
    Achievement(id: 'a6', name: '午夜电台', desc: '在 22:00-02:00 期间使用', iconName: 'clock', unlocked: false),
    Achievement(id: 'a7', name: '混音大师', desc: '同时加载 6 路音轨', iconName: 'mixer', unlocked: false),
    Achievement(id: 'a8', name: '审美家', desc: '切换过所有主题风格', iconName: 'palette', unlocked: false),
  ];

  /// 已解锁 id → 解锁日期。
  final Map<String, String> _datesById = <String, String>{};

  /// 全部成就（含解锁状态与日期）。
  late List<Achievement> items = _buildItems();

  int get unlockedCount => _datesById.length;
  int get total => _defs.length;
  int get progressPercent =>
      total == 0 ? 0 : ((unlockedCount / total) * 100).round();

  /// 已解锁成就（按解锁日期降序，供「最近获得」）。
  List<Achievement> get unlockedItems {
    final out = items.where((Achievement a) => a.unlocked).toList()
      ..sort((Achievement a, Achievement b) {
        final da = a.date ?? '';
        final db = b.date ?? '';
        return db.compareTo(da);
      });
    return out;
  }

  List<Achievement> _buildItems() => _defs
      .map((Achievement d) => Achievement(
            id: d.id,
            name: d.name,
            desc: d.desc,
            iconName: d.iconName,
            unlocked: _datesById.containsKey(d.id),
            date: _datesById[d.id],
          ))
      .toList();

  /// 从本地存储恢复已解锁成就。
  Future<void> load() async {
    final list =
        await AppStorage.readJsonListOfMaps(AppStorage.keyAchievements);
    if (list == null) return;
    _datesById.clear();
    for (final Map<String, dynamic> entry in list) {
      final id = entry['id'] as String?;
      final date = entry['date'] as String?;
      if (id != null && id.isNotEmpty && date != null && date.isNotEmpty) {
        _datesById[id] = date;
      }
    }
    items = _buildItems();
    notifyListeners();
  }

  /// 重新评估全部未解锁成就：条件满足即解锁并记录日期。
  void evaluate() {
    var changed = false;
    final now = _dateKey(DateTime.now());
    for (final a in _defs) {
      if (_datesById.containsKey(a.id)) continue;
      if (_isMet(a.id)) {
        _datesById[a.id] = now;
        changed = true;
      }
    }
    if (!changed) return;
    items = _buildItems();
    notifyListeners();
    unawaited(_persist());
  }

  bool _isMet(String id) {
    switch (id) {
      case 'a1':
        return _player.timerCompleted;
      case 'a2':
        return _checkin.streak >= 7;
      case 'a3':
        return _customScenes.scenes.length >= 5;
      case 'a4':
        return false; // 邀请：无真实邀请数据，保持锁定
      case 'a5':
        return _stats.activeDayCount >= 100;
      case 'a6':
        return _player.nightPlayRecorded;
      case 'a7':
        return _player.maxTrackCount >= 6;
      case 'a8':
        return schemeKeys
            .every((String k) => _themeNotifier.visitedSchemes.contains(k));
      default:
        return false;
    }
  }

  Future<void> _persist() async {
    await AppStorage.writeJsonList(
      AppStorage.keyAchievements,
      _datesById.entries
          .map((MapEntry<String, String> e) =>
              <String, dynamic>{'id': e.key, 'date': e.value})
          .toList(),
    );
  }

  @override
  void dispose() {
    _player.removeListener(evaluate);
    _checkin.removeListener(evaluate);
    _customScenes.removeListener(evaluate);
    _stats.removeListener(evaluate);
    _themeNotifier.removeListener(evaluate);
    super.dispose();
  }

  /// 本地日期 → YYYY-MM-DD。
  static String _dateKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';
}
