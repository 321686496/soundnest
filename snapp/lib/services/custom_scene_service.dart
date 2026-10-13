import 'package:flutter/foundation.dart';

import '../data/scene_models.dart';
import 'app_storage.dart';

/// 自定义场景服务：跨页面共享的用户创建场景列表，持久化 key `shengqi-scenes`。
///
/// 场景复用 [Scene] 模型（[Scene.isPreset] 为 false）；支持新增 / 更新 / 删除。
/// 存储不可用时优雅降级（读取空、写入跳过），与 AppStorage 策略一致。
class CustomSceneService extends ChangeNotifier {
  CustomSceneService();

  /// 用户自定义场景列表（不含内置预设场景）。
  final List<Scene> scenes = <Scene>[];

  /// 从本地存储恢复自定义场景列表。
  Future<void> load() async {
    final list = await AppStorage.readJsonListOfMaps(AppStorage.keyScenes);
    if (list == null) return;
    scenes
      ..clear()
      ..addAll(list
          .map((Map<String, dynamic> j) => Scene.fromJson(j))
          .where((Scene s) => s.id.isNotEmpty));
    notifyListeners();
  }

  /// 按 id 查找自定义场景；不存在返回 null。
  Scene? findById(String id) {
    for (final s in scenes) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// 新增自定义场景并持久化。
  Future<void> add(Scene scene) async {
    scenes.add(scene);
    notifyListeners();
    await _persist();
  }

  /// 按 id 更新自定义场景（不存在则追加），并持久化。
  Future<void> update(Scene scene) async {
    final idx = scenes.indexWhere((Scene s) => s.id == scene.id);
    if (idx >= 0) {
      scenes[idx] = scene;
    } else {
      scenes.add(scene);
    }
    notifyListeners();
    await _persist();
  }

  /// 按 id 删除自定义场景并持久化。
  Future<void> delete(String id) async {
    scenes.removeWhere((Scene s) => s.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    await AppStorage.writeJsonList(
      AppStorage.keyScenes,
      scenes.map((Scene s) => s.toJson()).toList(),
    );
  }
}
