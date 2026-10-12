import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/shell_tabs.dart';
import '../../data/scene_models.dart';
import '../../data/seed_data.dart';
import '../../services/player_service.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/nav_bar.dart';
import '../../widgets/scene_card.dart';
import '../../widgets/segmented.dart';

/// 全部场景（对照原型 `pages/scene-all/scene-all.vue`）：
/// NavBar + 分类分段 + 双列场景网格。
class SceneAllPage extends StatefulWidget {
  const SceneAllPage({super.key});

  @override
  State<SceneAllPage> createState() => _SceneAllPageState();
}

class _SceneAllPageState extends State<SceneAllPage> {
  String _activeTag = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 查询参数：/scene-all?category=sleep（深链可携带初始分类）。
    final cat = GoRouterState.of(context).queryParams['category'];
    if (cat != null && cat.isNotEmpty && _activeTag == 'all') _activeTag = cat;
  }

  List<Scene> get _filteredScenes {
    if (_activeTag == 'all') return homeScenes;
    return homeScenes.where((Scene s) => s.category == _activeTag).toList();
  }

  List<String> _soundIconsOf(Scene scene) => scene.soundIds.map((String id) {
        for (final s in sounds) {
          if (s.id == id) return s.iconName;
        }
        return 'wave';
      }).toList();

  void _openDetail(Scene scene) {
    context.push('/scene-detail/${scene.id}');
  }

  void _playScene(Scene scene) {
    context.read<PlayerService>().applyScene(scene);
    showAppToast(context, '已开始播放');
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) context.read<ShellTabNotifier>().go(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 只订阅当前场景 id；播放器其余通知不再整页重建。
    final currentSceneId = context.select<PlayerService, String?>(
        (PlayerService p) => p.currentScene?.id);
    final scenes = _filteredScenes;
    return AppPage(
      bottomBarSpace: true,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NavBar(title: '全部场景'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Segmented(
                options: sceneCategories
                    .map((SceneCategoryItem s) => SegmentOption(s.key, s.label))
                    .toList(),
                value: _activeTag,
                onChanged: (String k) => setState(() => _activeTag = k),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (var i = 0; i < scenes.length; i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SceneCard(
                              name: scenes[i].name,
                              soundCount: scenes[i].soundIds.length,
                              soundIcons: _soundIconsOf(scenes[i]),
                              bgColor: scenes[i].gradient,
                              cover: scenes[i].image,
                              isPreset: scenes[i].isPreset,
                              isGrid: true,
                              active: currentSceneId == scenes[i].id,
                              onTap: () => _openDetail(scenes[i]),
                              onPlay: () => _playScene(scenes[i]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (i + 1 < scenes.length)
                            Expanded(
                              child: SceneCard(
                                name: scenes[i + 1].name,
                                soundCount: scenes[i + 1].soundIds.length,
                                soundIcons: _soundIconsOf(scenes[i + 1]),
                                bgColor: scenes[i + 1].gradient,
                                cover: scenes[i + 1].image,
                                isPreset: scenes[i + 1].isPreset,
                                isGrid: true,
                                active: currentSceneId == scenes[i + 1].id,
                                onTap: () => _openDetail(scenes[i + 1]),
                                onPlay: () => _playScene(scenes[i + 1]),
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
