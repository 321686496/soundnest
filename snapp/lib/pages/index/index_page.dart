import 'package:flutter/material.dart' hide Banner;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/shell_tabs.dart';
import '../../data/banner_models.dart';
import '../../data/scene_models.dart';
import '../../data/seed_data.dart';
import '../../services/banner_service.dart';
import '../../services/player_service.dart';
import '../../services/scene_service.dart';
import '../../services/stats_service.dart';
import '../../theme/theme_extension.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_page.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/brand_bar.dart';
import '../../widgets/pressable.dart';
import '../../widgets/scene_card.dart';
import '../../widgets/segmented.dart';

/// 一键播 chip 定义（id, 回退分类, 图标）。
class _QuickChipDef {
  final String id;
  final String fallback;
  final String icon;
  const _QuickChipDef(this.id, this.fallback, this.icon);
}

/// 首页（对照原型 `pages/index/index.vue`）：
/// 品牌行 → 一键播 chips → 分类分段 + 场景网格。
/// 首页不渲染大主控卡，播放主控统一走全局悬浮 PlayBar（对其他 tab 一致）。
class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  String _activeCat = 'all';
  List<Scene> _gridScenes = <Scene>[];

  /// 一键播 chip：优先按场景 id 解析（findScene 找不到回退首条）。
  static const List<_QuickChipDef> _quickChipDefs = <_QuickChipDef>[
    _QuickChipDef('deep-sleep', 'sleep', 'moon'),
    _QuickChipDef('focus-white-noise', 'focus', 'white-noise'),
    _QuickChipDef('forest-stream', 'nature', 'stream'),
  ];

  @override
  void initState() {
    super.initState();
    _gridScenes = getCategoryScenes(_activeCat, 20);
  }

  void _refreshGrid() {
    setState(() => _gridScenes = getCategoryScenes(_activeCat, 20));
  }

  void _openDetail(Scene scene) {
    context.push('/scene-detail/${scene.id}');
  }

  void _onBannerTap(Banner b, PlayerService player) {
    if (b.kind == BannerKind.play && b.sceneId != null) {
      player.applyScene(findScene(b.sceneId!));
    } else if (b.kind == BannerKind.navigate && b.route != null) {
      if (b.route == '/scene-detail' && b.sceneId != null) {
        context.push('/scene-detail/${b.sceneId}');
      } else {
        context.push(b.route!);
      }
    }
  }

  void _playScene(Scene scene, PlayerService player) {
    if (player.currentScene?.id == scene.id) {
      player.togglePlay();
    } else {
      player.applyScene(scene);
    }
  }

  void _goSceneFlow(PlayerService player) {
    player.pendingSceneCategory = _activeCat;
    context.read<ShellTabNotifier>().go(1);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    // 只订阅首页真正展示的字段：最近播放列表、当前场景 id。播放器其余通知
    // （音量/静音/睡眠定时每秒 tick）不再整页重建。
    final recent = context.select<PlayerService, List<RecentItem>>(
        (PlayerService p) => p.recent);
    final currentSceneId = context.select<PlayerService, String?>(
        (PlayerService p) => p.currentScene?.id);
    final player = context.read<PlayerService>();
    final stats = context.read<StatsService>();
    final banners = buildBanners(
      hour: DateTime.now().hour,
      recent: recent,
      stats: stats,
    );

    return AppPage(
      bottomBarSpace: true,
      child: SingleChildScrollView(
        // 尾部让位加在滚动内容内部：内容从悬浮 TabBar/PlayBar 下方滑过，
        // 滚到底时最后一条内容完整越过悬浮区（见 AppPage.reservedBottomInset）。
        padding: EdgeInsets.only(bottom: AppPage.reservedBottomInset(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandBar(),
            const SizedBox(height: 12),
            if (banners.isNotEmpty)
              BannerCarousel(
                banners: banners,
                onTapBanner: (Banner b) => _onBannerTap(b, player),
              ),
            const SizedBox(height: 4),

            // ③ 场景流
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickChipDefs.map((_QuickChipDef d) {
                      final Scene scene = findScene(d.id);
                      return PressableScale(
                        onTap: () => player.applyScene(scene),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: c.line.opacity > 0.01
                                ? Border.all(color: c.line, width: 0.5)
                                : null,
                            boxShadow: c.shadow1,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(name: d.icon, size: 18, color: c.primary),
                              const SizedBox(width: 5),
                              Text(
                                scene.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                  color: c.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('场景',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: c.text2)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _goSceneFlow(player),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text('更多',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: c.primary)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Segmented(
                    options: sceneCategories
                        .map((SceneCategoryItem s) =>
                            SegmentOption(s.key, s.label))
                        .toList(),
                    value: _activeCat,
                    onChanged: (String k) {
                      setState(() => _activeCat = k);
                      _refreshGrid();
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_gridScenes.isNotEmpty)
                    _SceneGrid(
                      scenes: _gridScenes,
                      currentSceneId: currentSceneId,
                      onTap: _openDetail,
                      onPlay: _playScene,
                    )
                  else
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 30),
                      child: Center(
                        child: Text('暂无此类场景',
                            style: TextStyle(fontSize: 12.5, color: c.text2)),
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

/// 双列网格（Row 成对布局，卡片高度自适应内容，避免 GridView 定高溢出）。
class _SceneGrid extends StatelessWidget {
  final List<Scene> scenes;
  final String? currentSceneId;
  final void Function(Scene) onTap;
  final void Function(Scene, PlayerService) onPlay;

  const _SceneGrid({
    required this.scenes,
    required this.currentSceneId,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < scenes.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SceneCard(
                name: scenes[i].name,
                soundCount: scenes[i].soundIds.length,
                soundIcons: <String>[scenes[i].iconName],
                bgColor: scenes[i].gradient,
                cover: scenes[i].image,
                isPreset: scenes[i].isPreset,
                isGrid: true,
                active: currentSceneId == scenes[i].id,
                onTap: () => onTap(scenes[i]),
                onPlay: () => onPlay(scenes[i], context.read<PlayerService>()),
              ),
            ),
            const SizedBox(width: 12),
            if (i + 1 < scenes.length)
              Expanded(
                child: SceneCard(
                  name: scenes[i + 1].name,
                  soundCount: scenes[i + 1].soundIds.length,
                  soundIcons: <String>[scenes[i + 1].iconName],
                  bgColor: scenes[i + 1].gradient,
                  cover: scenes[i + 1].image,
                  isPreset: scenes[i + 1].isPreset,
                  isGrid: true,
                  active: currentSceneId == scenes[i + 1].id,
                  onTap: () => onTap(scenes[i + 1]),
                  onPlay: () =>
                      onPlay(scenes[i + 1], context.read<PlayerService>()),
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
      rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}
