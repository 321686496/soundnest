import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_storage.dart';
import 'scene_service.dart';

/// 最爱场景排行条目。
class TopSceneStat {
  const TopSceneStat(this.name, this.count, this.percent);
  final String name;
  final int count;

  /// 相对第一名占比（0-100）。
  final int percent;
}

/// 统计服务：累计播放次数 / 各场景播放量 / 每日播放分布 / 活跃天数，
/// 持久化 key `shengqi-stats`（JSON 对象字符串）。
///
/// 由 [PlayerService.applyScene] 调用 [recordPlay] 自动记录；
/// 存储不可用时优雅降级，与 AppStorage 策略一致。
class StatsService extends ChangeNotifier {
  StatsService({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// 累计播放次数。
  int totalPlays = 0;

  /// 各场景播放次数（sceneId → count）。
  final Map<String, int> playCountsByScene = <String, int>{};

  /// 每日播放次数（YYYY-MM-DD → count）。
  final Map<String, int> dailyPlayCounts = <String, int>{};

  /// 活跃日期集合（YYYY-MM-DD，至少播放一次）。
  final Set<String> activeDays = <String>{};

  /// 近 7 日播放次数（今天 → 前 6 天，数组 [0]=今天）。
  List<int> get weekPlays {
    final out = <int>[];
    var day = _clock();
    for (var i = 0; i < 7; i++) {
      out.add(dailyPlayCounts[dateKey(day)] ?? 0);
      day = day.subtract(const Duration(days: 1));
    }
    return out;
  }

  /// 本周（近 7 日）有播放的天数。
  int get weekUsageDays => weekPlays.where((int c) => c > 0).length;

  /// 近 7 日累计播放次数（视作分钟数，与 mine 页「累计播放(分)」口径一致）。
  int get weekTotalMinutes => weekPlays.fold(0, (int sum, int c) => sum + c);

  /// 累计播放次数 → 累计分钟（每次播放计 1 分钟，模拟口径）。
  int get totalMinutes => totalPlays;

  /// 累计活跃天数（不同日期各计 1 天）。
  int get activeDayCount => activeDays.length;

  /// 播放量最高的场景 id；无记录返回 null。
  String? get favoriteSceneId {
    String? best;
    var max = 0;
    playCountsByScene.forEach((String id, int count) {
      if (count > max) {
        max = count;
        best = id;
      }
    });
    return best;
  }

  /// 最爱场景名（无记录返回空串）。
  String get favoriteSceneName {
    final id = favoriteSceneId;
    if (id == null) return '';
    return findScene(id).name;
  }

  /// 播放量 Top3（按次数降序，相对占比）。
  List<TopSceneStat> get topScenes {
    final entries = playCountsByScene.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));
    final top = entries.take(3).toList();
    final max = top.isEmpty ? 0 : top.first.value;
    return top
        .map((MapEntry<String, int> e) => TopSceneStat(
              findScene(e.key).name,
              e.value,
              max == 0 ? 0 : ((e.value / max) * 100).round(),
            ))
        .toList();
  }

  /// 累计分钟 → 「Xh Ym」/「Ym」显示文本。
  static String formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// 记录一次播放（sceneId 来自场景）。由 PlayerService.applyScene 调用。
  Future<void> recordPlay(String sceneId) async {
    final now = _clock();
    totalPlays++;
    playCountsByScene[sceneId] = (playCountsByScene[sceneId] ?? 0) + 1;
    final key = dateKey(now);
    dailyPlayCounts[key] = (dailyPlayCounts[key] ?? 0) + 1;
    activeDays.add(key);
    notifyListeners();
    await _persist();
  }

  /// 从本地存储恢复统计。
  Future<void> load() async {
    final raw = await AppStorage.getString(AppStorage.keyStats);
    if (raw == null || raw.isEmpty) return;
    try {
      final j = jsonDecode(raw);
      if (j is! Map) return;
      final map = j.cast<String, dynamic>();
      totalPlays = (map['totalPlays'] as num?)?.toInt() ?? 0;
      final byScene = map['playCountsByScene'];
      if (byScene is Map) {
        playCountsByScene
          ..clear()
          ..addAll(byScene.cast<String, num>().map(
              (String k, num v) => MapEntry(k, v.toInt())));
      }
      final daily = map['dailyPlayCounts'];
      if (daily is Map) {
        dailyPlayCounts
          ..clear()
          ..addAll(daily.cast<String, num>().map(
              (String k, num v) => MapEntry(k, v.toInt())));
      }
      final days = map['activeDays'];
      if (days is List) {
        activeDays.clear();
        activeDays.addAll(days.whereType<String>());
      }
      notifyListeners();
    } catch (_) {
      // 数据损坏：保持空态
    }
  }

  Future<void> _persist() async {
    await AppStorage.setString(
      AppStorage.keyStats,
      jsonEncode(<String, dynamic>{
        'totalPlays': totalPlays,
        'playCountsByScene': playCountsByScene,
        'dailyPlayCounts': dailyPlayCounts,
        'activeDays': activeDays.toList(),
      }),
    );
  }

  /// 本地日期 → YYYY-MM-DD。
  static String dateKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';
}
