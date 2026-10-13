import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储统一入口（对应原型 `uni.getStorageSync/setStorageSync`）。
///
/// 所有 key 与原型保持一致（`shengqi-*`）。平台插件缺失时优雅降级：
/// 读取返回空值、写入静默跳过，不向上抛异常（与 ThemePrefs 策略一致）。
class AppStorage {
  AppStorage._();

  static const String keyTheme = 'shengqi-theme';
  static const String keyRecent = 'shengqi-recent';
  static const String keyReminder = 'shengqi-reminder';
  static const String keyFavorites = 'shengqi-favorites';
  static const String keyCheckin = 'shengqi-checkin';
  static const String keyScenes = 'shengqi-scenes';
  static const String keyStats = 'shengqi-stats';
  static const String keyPlaySettings = 'shengqi-play-settings';
  static const String keyOnboarded = 'shengqi-onboarded';
  static const String keyThemeVisits = 'shengqi-theme-visits';
  static const String keyAchievements = 'shengqi-achievements';

  static Future<SharedPreferences?> _instance() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('AppStorage: shared_preferences unavailable: $e');
      return null;
    }
  }

  static Future<String?> getString(String key) async {
    final p = await _instance();
    return p?.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final p = await _instance();
    await p?.setString(key, value);
  }

  /// 读取 JSON 字符串并反序列化为 List<dynamic>；损坏/缺失返回 null。
  static Future<List<dynamic>?> readJsonList(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final v = jsonDecode(raw);
      return v is List ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// 读取 JSON 字符串并反序列化为 `Map<String, dynamic>` 对象列表；
  /// 非对象元素被过滤。损坏/缺失返回 null。
  ///
  /// 供各 service 的 `load()` 使用，避免在每个调用方重复
  /// `.whereType<Map<dynamic,dynamic>>().map(... cast<String,dynamic> ...)`。
  static Future<List<Map<String, dynamic>>?> readJsonListOfMaps(
      String key) async {
    final list = await readJsonList(key);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }

  static Future<void> writeJsonList(String key, List<Map<String, dynamic>> list) async {
    await setString(key, jsonEncode(list));
  }
}
