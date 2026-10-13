import 'package:flutter/foundation.dart';

import 'app_storage.dart';

/// 打卡服务：跨页面共享的签到日期集合（YYYY-MM-DD），持久化 key `shengqi-checkin`。
///
/// 连续天数按「今天已签则以今天、否则以昨天」为基准向前连续计数；
/// 时钟可注入（默认 [DateTime.now]），便于单元测试固定日期。
/// 存储不可用时优雅降级（读取空、写入跳过），与 AppStorage 策略一致。
class CheckinService extends ChangeNotifier {
  CheckinService({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// 已签到日期集合，格式 YYYY-MM-DD（本地日期）。
  final Set<String> dates = <String>{};

  /// 今天是否已签到。
  bool get checkedToday => dates.contains(dateKey(_clock()));

  /// 连续签到天数：以今天（若已签）或昨天为基准向前连续计数。
  int get streak {
    var day = dateKey(_clock());
    if (!dates.contains(day)) {
      day = dateKey(_clock().subtract(const Duration(days: 1)));
    }
    var count = 0;
    while (dates.contains(day)) {
      count++;
      day = dateKey(parseDate(day).subtract(const Duration(days: 1)));
    }
    return count;
  }

  /// 从本地存储恢复签到集合。
  Future<void> load() async {
    final list = await AppStorage.readJsonListOfMaps(AppStorage.keyCheckin);
    if (list == null) return;
    dates
      ..clear()
      ..addAll(list
          .map((Map<String, dynamic> j) => (j['date'] as String?) ?? '')
          .where((String d) => d.isNotEmpty));
    notifyListeners();
  }

  /// 签到（今日已签则幂等无操作），成功后持久化。
  Future<void> checkIn() async {
    if (checkedToday) return;
    dates.add(dateKey(_clock()));
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    await AppStorage.writeJsonList(
      AppStorage.keyCheckin,
      dates.map((String d) => <String, dynamic>{'date': d}).toList(),
    );
  }

  /// 本地日期 → YYYY-MM-DD。
  static String dateKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  /// YYYY-MM-DD → 本地日期（用于日历向前推进）。
  static DateTime parseDate(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
