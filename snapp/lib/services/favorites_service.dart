import 'package:flutter/foundation.dart';

import 'app_storage.dart';

/// 收藏服务：跨页面共享的收藏场景 ID 列表（scene-detail / now_playing_card /
/// favorites 页三处统一读写），持久化 key `shengqi-favorites`。
///
/// 存储不可用时优雅降级（读取空、写入跳过），与 AppStorage 策略一致。
class FavoritesService extends ChangeNotifier {
  List<String> ids = <String>[];

  /// 从本地存储恢复收藏列表。
  Future<void> load() async {
    final list = await AppStorage.readJsonListOfMaps(AppStorage.keyFavorites);
    if (list == null) return;
    ids = list
        .map((Map<String, dynamic> j) => (j['id'] as String?) ?? '')
        .where((String id) => id.isNotEmpty)
        .toList();
    notifyListeners();
  }

  bool isFav(String id) => ids.contains(id);

  /// 切换收藏状态并持久化。
  Future<void> toggle(String id) async {
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    await AppStorage.writeJsonList(
      AppStorage.keyFavorites,
      ids.map((String id) => <String, dynamic>{'id': id}).toList(),
    );
  }
}
