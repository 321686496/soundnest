import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/shell_tabs.dart';
import '../../data/scene_models.dart';
import '../../data/seed_data.dart';
import '../../services/custom_scene_service.dart';
import '../../services/player_service.dart';
import '../../services/scene_service.dart';
import '../../theme/theme_extension.dart';
import '../../utils/style_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_section.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pressable.dart';
import '../../widgets/scene_card.dart';

/// 场景页（对照原型 `pages/scene/scene.vue`）：
/// 品牌头部 + 为你推荐/最近播放卡 + 分类精选卡 + 我的场景卡。
class ScenePage extends StatefulWidget {
  const ScenePage({super.key});

  @override
  State<ScenePage> createState() => _ScenePageState();
}

class _ScenePageState extends State<ScenePage> {
  String _activeTag = 'all';

  static const Map<String, String> _prefLabelMap = <String, String>{
    'sleep': '助眠',
    'focus': '专注',
    'relax': '放松',
    'nature': '自然',
  };

  void _onShow() {
    final player = context.read<PlayerService>();
    setState(() {
      if (player.pendingSceneCategory != 'all' &&
          player.pendingSceneCategory.isNotEmpty) {
        _activeTag = player.pendingSceneCategory;
        player.pendingSceneCategory = 'all';
      }
    });
  }

  /// 模拟 onShow：Shell 切到本 tab 时刷新（含 pendingSceneCategory 交接）。
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabs = Provider.of<ShellTabNotifier>(context);
    if (tabs.index == 1) _onShow();
  }

  List<Scene> get _recommended => getRecommended(
      simulatedPrefs,
      context
          .read<PlayerService>()
          .recent
          .map((RecentItem r) => RecentHit(r.sceneId))
          .toList());

  List<Scene> get _featuredScenes => getCategoryScenes(_activeTag, 3);

  void _openDetail(String sceneId) {
    context.push('/scene-detail/$sceneId');
  }

  void _playScene(Scene scene) {
    context.read<PlayerService>().applyScene(scene);
    showAppToast(context, '已开始播放');
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) context.read<ShellTabNotifier>().go(0);
    });
  }

  void _playMyScene(Scene scene) {
    context.read<PlayerService>().applyScene(scene);
    showAppToast(context, '已开始播放「${scene.name}」');
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) context.read<ShellTabNotifier>().go(0);
    });
  }

  Future<void> _deleteScene(Scene scene) async {
    final c = Theme.of(context).appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('删除场景',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
        content: Text('确定删除「${scene.name}」吗？删除后不可恢复。',
            style: TextStyle(fontSize: 13.5, color: c.text2)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消',
                style: TextStyle(fontSize: 14, color: c.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('删除',
                style: TextStyle(fontSize: 14, color: c.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<CustomSceneService>().delete(scene.id);
    if (mounted) showAppToast(context, '已删除「${scene.name}」');
  }

  /// 声音 id → 图标名（找不到回退 wave）。
  List<String> _soundIconsOf(Scene scene) => scene.soundIds.map((String id) {
        for (final s in sounds) {
          if (s.id == id) return s.iconName;
        }
        return 'wave';
      }).toList();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    // 只订阅实际展示字段：最近播放列表、当前场景 id。播放器其余通知不再整页重建。
    final recent = context.select<PlayerService, List<RecentItem>>(
        (PlayerService p) => p.recent);
    final currentSceneId = context.select<PlayerService, String?>(
        (PlayerService p) => p.currentScene?.id);

    return AppPage(
      bottomBarSpace: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(c),
            _GroupCard(
              children: [
                _CardHead(icon: 'flame', title: '为你推荐'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _recommended.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        _RecCard(
                          scene: _recommended[i],
                          onTap: () => _openDetail(_recommended[i].id),
                        ),
                      ],
                    ],
                  ),
                ),
                if (recent.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 3),
                    child: AppDivider(),
                  ),
                  const SizedBox(height: 10),
                  const _CardHead(icon: 'clock', title: '最近播放'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < recent.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          _RecentCard(
                            item: recent[i],
                            onTap: () => _openDetail(recent[i].sceneId),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
            _GroupCard(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      for (final tag in sceneCategories)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _TagChip(
                            label: tag.label,
                            icon: tag.icon,
                            active: _activeTag == tag.key,
                            onTap: () => setState(() => _activeTag = tag.key),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(1, 6, 0, 9),
                  child: Row(
                    children: [
                      const _CardHead(icon: 'mountain', title: '精选场景'),
                      const Spacer(),
                      PressableScale(
                        onTap: () => context.push('/scene-all'),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Text('查看全部',
                                  style: TextStyle(
                                      fontSize: 11.5, color: c.text2)),
                              const SizedBox(width: 1),
                              AppIcon(name: 'chevron-right', size: 14, color: c.text2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _FeaturedGrid(
                  scenes: _featuredScenes,
                  currentSceneId: currentSceneId,
                  onTap: (Scene s) => _openDetail(s.id),
                  onPlay: _playScene,
                ),
              ],
            ),
            _GroupCard(
              children: [
                Row(
                  children: [
                    const _CardHead(icon: 'mixer', title: '我的场景'),
                    const Spacer(),
                    PressableScale(
                      onTap: _createScene,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: c.line.opacity > 0.01
                              ? Border.all(color: c.line, width: 0.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            AppIcon(name: 'mixer', size: 16, color: c.primary),
                            const SizedBox(width: 4),
                            Text('新建',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: c.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                for (final my in context.watch<CustomSceneService>().scenes)
                  SceneCard(
                    name: my.name,
                    soundCount: my.soundIds.length,
                    soundIcons: _soundIconsOf(my),
                    bgColor: my.gradient,
                    isPreset: false,
                    active: currentSceneId == my.id,
                    bottomMargin: true,
                    onTap: () => _editScene(my),
                    onShare: () => _deleteScene(my),
                    onPlay: () => _playMyScene(my),
                  ),
                if (context.watch<CustomSceneService>().scenes.isEmpty)
                  _buildMySceneEmpty(c),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: c.primary.withOpacity(0.22),
                  offset: const Offset(0, 4),
                  blurRadius: 11,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/brand/logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: c.primary)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('声栖',
                    style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        height: 1.1,
                        color: c.text)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text('今晚想听什么？',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.5,
                              color: c.text2)),
                    ),
                    const SizedBox(width: 4),
                    for (final p in simulatedPrefs)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.primarySoft,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(name: 'flame', size: 12, color: c.primary),
                              const SizedBox(width: 2),
                              Text(_prefLabelMap[p] ?? p,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: c.primary)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _HeaderBtn(
            icon: AppIcon(name: 'mixer', size: 22, color: c.primary),
            onTap: _createScene,
          ),
          const SizedBox(width: 8),
          _HeaderBtn(
            icon: AppIcon(name: 'palette', size: 22, color: c.primary),
            onTap: () => context.push('/theme'),
          ),
        ],
      ),
    );
  }

  Widget _buildMySceneEmpty(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
                child: AppIcon(name: 'mountain', size: 52, color: c.primary)),
          ),
          const SizedBox(height: 6),
          Text('还没有自定义场景',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 3),
          Text('点击右上角「新建」即可创建，或在首页混音后保存',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: c.text2)),
        ],
      ),
    );
  }

  void _createScene() {
    context.push('/scene-edit/new');
  }

  void _editScene(Scene scene) {
    context.push('/scene-edit/${scene.id}');
  }
}

class _HeaderBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: c.line.opacity > 0.01
              ? Border.all(color: c.line, width: 0.5)
              : null,
          boxShadow: c.shadow1,
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}

/// 分组大卡（原型 `.group-card`）。
class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// 卡片内小节头（图标 + 标题，`.card-head`）。
class _CardHead extends StatelessWidget {
  final String icon;
  final String title;
  const _CardHead({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          AppIcon(name: icon, size: 16, color: c.primary),
          const SizedBox(width: 5),
          Text(title,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: c.text2)),
        ],
      ),
    );
  }
}

/// 推荐卡（宽 120，封面高 70 + 原因徽章）。
class _RecCard extends StatelessWidget {
  final Scene scene;
  final VoidCallback onTap;
  const _RecCard({required this.scene, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MiniCover(
              gradientCss: scene.gradient,
              image: scene.image,
              height: 70,
              iconSize: 40,
              icon: scene.iconName,
              child: Positioned(
                left: 5,
                bottom: 5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(name: 'flame', size: 12, color: c.primary),
                      const SizedBox(width: 2),
                      Text('常听偏好',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: c.primary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(scene.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: c.text)),
            Text(scene.desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: c.text2)),
          ],
        ),
      ),
    );
  }
}

/// 最近播放卡（宽 90，封面高 55）。
class _RecentCard extends StatelessWidget {
  final RecentItem item;
  final VoidCallback onTap;
  const _RecentCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final scene = findScene(item.sceneId);
    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MiniCover(
              gradientCss: scene.gradient.isNotEmpty ? scene.gradient : item.gradient,
              image: scene.image,
              height: 55,
              iconSize: 34,
              icon: item.iconName,
            ),
            const SizedBox(height: 5),
            Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: c.text)),
            Text(PlayerService.recentTimeLabel(item.ts),
                style: TextStyle(fontSize: 10.5, color: c.text2)),
          ],
        ),
      ),
    );
  }
}

/// 小封面：渐变底（或封面图）+ 居中图标 + 可选叠加层。
class _MiniCover extends StatelessWidget {
  final String gradientCss;
  final String image;
  final double height;
  final double iconSize;
  final String icon;
  final Widget? child;

  const _MiniCover({
    required this.gradientCss,
    required this.image,
    required this.height,
    required this.iconSize,
    required this.icon,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final g = parseCssGradient(gradientCss);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: g == null
            ? null
            : LinearGradient(begin: g.begin, end: g.end, colors: g.colors),
        color: g == null ? c.surface2 : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (image.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  sceneImageAsset(image),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          AppIcon(name: icon, size: iconSize, color: c.onCoverSoft),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// 分类 chip（原型 `.tag-item`）。
class _TagChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool active;
  final VoidCallback onTap;
  const _TagChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? c.primarySoft : c.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? c.primary.withOpacity(0.3) : c.line,
            width: 0.5,
          ),
          boxShadow: active ? null : c.shadow1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(name: icon, size: 14, color: active ? c.primary : c.text2),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? c.primary : c.text2)),
          ],
        ),
      ),
    );
  }
}

/// 精选场景双列网格（复用首页布局方式）。
class _FeaturedGrid extends StatelessWidget {
  final List<Scene> scenes;
  final String? currentSceneId;
  final void Function(Scene) onTap;
  final void Function(Scene) onPlay;

  const _FeaturedGrid({
    required this.scenes,
    required this.currentSceneId,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < scenes.length; i += 2) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SceneCard(
              name: scenes[i].name,
              soundCount: scenes[i].soundIds.length,
              soundIcons: _presetIconList(i),
              bgColor: scenes[i].gradient,
              cover: scenes[i].image,
              isPreset: scenes[i].isPreset,
              isGrid: true,
              active: currentSceneId == scenes[i].id,
              onTap: () => onTap(scenes[i]),
              onPlay: () => onPlay(scenes[i]),
            ),
          ),
          const SizedBox(width: 8),
          if (i + 1 < scenes.length)
            Expanded(
              child: SceneCard(
                name: scenes[i + 1].name,
                soundCount: scenes[i + 1].soundIds.length,
                soundIcons: _presetIconList(i + 1),
                bgColor: scenes[i + 1].gradient,
                cover: scenes[i + 1].image,
                isPreset: scenes[i + 1].isPreset,
                isGrid: true,
                active: currentSceneId == scenes[i + 1].id,
                onTap: () => onTap(scenes[i + 1]),
                onPlay: () => onPlay(scenes[i + 1]),
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ));
      rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }

  List<String> _presetIconList(int index) =>
      scenes[index].soundIds.map((String id) {
        for (final s in sounds) {
          if (s.id == id) return s.iconName;
        }
        return 'wave';
      }).toList();
}
