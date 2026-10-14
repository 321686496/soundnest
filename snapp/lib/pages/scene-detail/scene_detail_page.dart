import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/scene_models.dart';
import '../../services/favorites_service.dart';
import '../../services/player_service.dart';
import '../../services/scene_service.dart';
import '../../theme/theme_extension.dart';
import '../../utils/style_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_section.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/mix_track.dart';
import '../../widgets/nav_bar.dart';
import '../../widgets/pressable.dart';

/// 场景详情（对照原型 `pages/scene-detail/scene-detail.vue`）：
/// 通栏渐变 Hero（播放主控）+ 场景故事 + 声音配方 + 预设方案 +
/// 操作行 + 分享预览；定时 / 混音为底部 Sheet。
class SceneDetailPage extends StatefulWidget {
  const SceneDetailPage({super.key});

  @override
  State<SceneDetailPage> createState() => _SceneDetailPageState();
}

class _SceneDetailPageState extends State<SceneDetailPage> {
  String _sceneId = '';
  String _activePreset = '标准';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 路径参数：/scene-detail/:sceneId。
    if (_sceneId.isEmpty) {
      _sceneId = GoRouterState.of(context).params['sceneId'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    // 只订阅本页真正展示的字段：当前场景 id、播放态；其余播放器通知不再整页重建。
    final currentSceneId = context.select<PlayerService, String?>(
        (PlayerService p) => p.currentScene?.id);
    final isPlaying = context.select<PlayerService, bool>(
        (PlayerService p) => p.isPlaying);
    final player = context.read<PlayerService>();
    final fav = context.watch<FavoritesService>();
    final scene = findScene(_sceneId);
    final recipe = buildRecipe(scene);
    final presets = buildPresets(scene);
    final isFavorited = fav.isFav(scene.id);
    final isCurrent = currentSceneId == scene.id;
    final isThisPlaying = isCurrent && isPlaying;
    final g = parseCssGradient(scene.gradient);

    return AppPage(
      bottomBarSpace: true,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NavBar(title: '场景详情'),
            ),
            _buildHero(c, scene, isThisPlaying, player),
            _buildSection(c, '场景故事', _StoryCard(scene: scene)),
            _buildSection(
              c,
              '声音配方',
              _RecipeCard(
                recipe: recipe,
                soundIds: scene.soundIds,
                c: c,
                onOpenSound: (String id) => context.push('/sound/$id'),
              ),
            ),
            _buildSection(
              c,
              '预设方案',
              Column(
                children: [
                  for (final preset in presets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PresetCard(
                        name: preset.name,
                        badgeColor: preset.badgeColor,
                        ratios: preset.ratios,
                        active: _activePreset == preset.name,
                        onTap: () {
                          setState(() => _activePreset = preset.name);
                          showAppToast(context, '已切换「${preset.name}」方案');
                        },
                      ),
                    ),
                ],
              ),
            ),
            _buildSection(c, '', _ActionRow(isFavorited: isFavorited,
                onEdit: _editScene,
                onFav: () {
                  fav.toggle(scene.id);
                  showAppToast(context, isFavorited ? '已取消收藏' : '已收藏');
                },
                onShare: () => showAppToast(context, '已生成分享卡片'))),
            _buildSection(
              c,
              '分享预览',
              _ShareCard(scene: scene, g: g),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(AppColors c, String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: AppSectionTitle(title),
            ),
          child,
        ],
      ),
    );
  }

  /// 通栏 Hero：渐变底 + 圆环图标 + 波浪 + 主播放钮 + 定时/混音 chips。
  Widget _buildHero(
    AppColors c,
    Scene scene,
    bool isThisPlaying,
    PlayerService player,
  ) {
    final g = parseCssGradient(scene.gradient);
    // hero 定时 chip 独立订阅定时分钟，其余播放器通知不 rebuild 整块 hero。
    final timerMinutes = context.select<PlayerService, int>(
        (PlayerService p) => p.timerMinutes);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        gradient: g == null
            ? null
            : LinearGradient(begin: g.begin, end: g.end, colors: g.colors),
        color: g == null ? c.primary : null,
        borderRadius: BorderRadius.circular(28),
        boxShadow: c.shadow3,
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: Colors.white.withOpacity(0.20),
                    blurRadius: 26,
                    spreadRadius: 10),
                BoxShadow(
                    color: Colors.white.withOpacity(0.10),
                    blurRadius: 56,
                    spreadRadius: 22),
              ],
            ),
            alignment: Alignment.center,
            child: AppIcon(name: scene.iconName, size: 120, color: c.onCover),
          ),
          const SizedBox(height: 16),
          Text(scene.name,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: c.onCover)),
          const SizedBox(height: 6),
          Text(
            scene.desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.6, color: c.onCoverSoft),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _HeroWave(playing: isThisPlaying)),
              PressableScale(
                onTap: () => _onHeroPlay(player, scene),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[c.primary, c.primaryStrong],
                    ),
                    boxShadow: <BoxShadow>[
                      ...c.shadow3,
                      BoxShadow(
                          color: c.primarySoft,
                          blurRadius: 28,
                          spreadRadius: 8),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(
                      name: isThisPlaying ? 'pause' : 'play',
                      size: 64,
                      color: c.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroChip(
                icon: AppIcon(name: 'timer', size: 20,
                    color: timerMinutes > 0 ? c.primaryStrong : c.onCover),
                label: timerMinutes > 0 ? '$timerMinutes分' : '定时',
                on: timerMinutes > 0,
                onTap: () => _openTimerSheet(),
              ),
              const SizedBox(width: 10),
              _HeroChip(
                icon: AppIcon(name: 'shuffle', size: 20, color: c.onCover),
                label: '混音',
                onTap: () => _openMixSheet(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onHeroPlay(PlayerService player, Scene scene) {
    if (player.currentScene?.id != scene.id) {
      player.applyScene(scene);
      showAppToast(context, '已开始播放');
      return;
    }
    if (!player.togglePlay()) {
      showAppToast(context, '暂无音轨，去编辑配方添加声音');
    }
  }

  void _editScene() {
    context.push('/scene-edit/$_sceneId');
  }

  void _openTimerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => const _TimerSheet(),
    );
  }

  void _openMixSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) => const _MixSheet(),
    );
  }
}

/* ------------------------------ Hero 子件 ------------------------------ */

/// Hero 波浪（5 根 on-cover 白杆，播放呼吸 / 暂停静止 40%）。
class _HeroWave extends StatefulWidget {
  final bool playing;
  const _HeroWave({required this.playing});

  @override
  State<_HeroWave> createState() => _HeroWaveState();
}

class _HeroWaveState extends State<_HeroWave> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  static const List<double> _heights = <double>[26, 48, 75, 48, 26];

  @override
  void initState() {
    super.initState();
    _update(widget.playing);
  }

  @override
  void didUpdateWidget(_HeroWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) _update(widget.playing);
  }

  void _update(bool playing) {
    if (playing) {
      _ctrl.repeat();
    } else {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return SizedBox(
      height: 44,
      child: Row(
        children: List<Widget>.generate(_heights.length, (int i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (BuildContext context, _) {
              final phase = (_ctrl.value * 2 - i * 0.12) % 1.0;
              final scale =
                  widget.playing ? 0.6 + 0.4 * (1 - (2 * phase - 1).abs()) : 0.6;
              return Opacity(
                opacity: widget.playing ? 1 : 0.4,
                child: Container(
                  width: 4,
                  height: _heights[i],
                  margin: const EdgeInsets.only(right: 5),
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    heightFactor: scale,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: c.onCover,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _HeroChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.on = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: on ? Colors.white.withOpacity(0.92) : Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: on ? c.primaryStrong : c.onCover)),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ 分区卡片 ------------------------------ */

class _StoryCard extends StatelessWidget {
  final Scene scene;
  const _StoryCard({required this.scene});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('"${scene.desc}"',
                  style: TextStyle(
                    fontSize: 14,
                    color: c.text,
                    fontStyle: FontStyle.italic,
                    height: 1.7,
                    letterSpacing: 0.25,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final List<RecipeItem> recipe;
  final List<String> soundIds;
  final AppColors c;
  final void Function(String soundId) onOpenSound;

  const _RecipeCard({
    required this.recipe,
    required this.soundIds,
    required this.c,
    required this.onOpenSound,
  });

  @override
  Widget build(BuildContext context) {
    // buildRecipe 按 scene.soundIds 顺序 1:1 构造（scene_service.dart），
    // recipe[i] ↔ soundIds[i]，联动按下标取 id。
    final player = context.read<PlayerService>();
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          for (var i = 0; i < recipe.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            PressableScale(
              onTap: () => onOpenSound(soundIds[i]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: AppIcon(
                            name: recipe[i].icon, size: 18, color: c.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(recipe[i].name,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: c.text)),
                      ),
                      Text('${recipe[i].percent}%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.text2)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 8,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Container(color: c.sunken),
                          Builder(builder: (BuildContext context) {
                            final snd = player.findSound(soundIds[i]);
                            final g =
                                snd == null ? null : parseCssGradient(snd.gradient);
                            return FractionallySizedBox(
                              widthFactor: recipe[i].percent / 100,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: g == null
                                      ? null
                                      : LinearGradient(
                                          begin: g.begin,
                                          end: g.end,
                                          colors: g.colors),
                                  color: g == null
                                      ? hexToColor(recipe[i].color) ?? c.primary
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String name;
  final String badgeColor;
  final List<PresetRatio> ratios;
  final bool active;
  final VoidCallback onTap;
  const _PresetCard({
    required this.name,
    required this.badgeColor,
    required this.ratios,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final g = parseCssGradient(badgeColor);
    return PressableScale(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active
                ? c.primary.withOpacity(0.7)
                : (c.line.opacity > 0.01 ? c.line : Colors.transparent),
            width: 0.5,
          ),
          boxShadow: <BoxShadow>[
            ...c.shadow2,
            if (active)
              BoxShadow(color: c.primarySoft2, offset: Offset.zero, blurRadius: 0,
                  spreadRadius: 1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: g == null
                        ? null
                        : LinearGradient(begin: g.begin, end: g.end, colors: g.colors),
                    color: g == null ? c.primary : null,
                  ),
                  child: Text(name,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: c.onCover)),
                ),
                if (active)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon(name: 'check', size: 16, color: c.primary),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < ratios.length; i++) ...[
                  Text('${ratios[i].name} ${ratios[i].value}%',
                      style: TextStyle(fontSize: 12, color: c.text2)),
                  if (i < ratios.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(' · ',
                          style: TextStyle(fontSize: 12, color: c.text3)),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool isFavorited;
  final VoidCallback onEdit;
  final VoidCallback onFav;
  final VoidCallback onShare;
  const _ActionRow({
    required this.isFavorited,
    required this.onEdit,
    required this.onFav,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: AppIcon(name: 'edit', size: 20, color: c.primary),
            label: '编辑配方',
            onTap: onEdit,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: AppIcon(
                name: 'heart',
                size: 20,
                color: isFavorited ? c.primary : c.text3),
            label: isFavorited ? '已收藏' : '收藏',
            onTap: onFav,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: AppIcon(name: 'share', size: 20, color: c.primary),
            label: '分享',
            onTap: onShare,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(22),
          border: c.line.opacity > 0.01
              ? Border.all(color: c.line, width: 0.5)
              : null,
          boxShadow: c.shadow1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: c.primary)),
          ],
        ),
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final Scene scene;
  final CssGradient? g;
  const _ShareCard({required this.scene, required this.g});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      color: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: g == null
                      ? null
                      : LinearGradient(begin: g!.begin, end: g!.end, colors: g!.colors),
                  color: g == null ? c.primary : null,
                ),
                alignment: Alignment.center,
                child: AppIcon(name: scene.iconName, size: 28, color: c.onCover),
              ),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scene.name,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                  const SizedBox(height: 3),
                  Text('累计播放 1,284 次 · 收藏 326 次',
                      style: TextStyle(fontSize: 11, color: c.text2)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('"每晚听着雨声入眠，是我给自己最温柔的仪式"',
              style: TextStyle(
                  fontSize: 13, height: 1.6, fontStyle: FontStyle.italic, color: c.text)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line, width: 0.5)),
            ),
            child: Text('— 声栖 · 用声音构建你的宁静空间',
                style: TextStyle(fontSize: 11, letterSpacing: 0.25, color: c.text2)),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ 底部 Sheet ------------------------------ */

/// 共用 Sheet 外壳（顶角 28 + shadow-4 + 顶描边）。
class _SheetShell extends StatelessWidget {
  final String title;
  final String? badge;
  final List<Widget> children;
  const _SheetShell({required this.title, this.badge, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: c.shadow4,
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: c.sunken,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                          color: c.text)),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(badge!,
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: c.primary)),
                  ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Transform.translate(
                    offset: const Offset(9, 0),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: AppIcon(name: 'close', size: 18, color: c.text3),
                    ),
                  ),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TimerSheet extends StatelessWidget {
  const _TimerSheet();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    // 只订阅定时分钟；每秒倒计时/音量等不重建此弹层。
    final timerMinutes = context.select<PlayerService, int>(
        (PlayerService p) => p.timerMinutes);
    return _SheetShell(
      title: '睡眠定时',
      children: [
        const SizedBox(height: 12),
        Row(
          children: [15, 30, 45, 60].map((int m) {
            final on = timerMinutes == m;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  final player = context.read<PlayerService>();
                  final willCancel = timerMinutes == m;
                  player.setTimer(m);
                  showAppToast(context, willCancel ? '已取消定时' : '定时 $m 分钟');
                },
                child: Container(
                  height: 44,
                  margin: EdgeInsets.only(right: m == 60 ? 0 : 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? c.primary : c.surface2,
                    borderRadius: BorderRadius.circular(999),
                    border: on || c.line.opacity <= 0.01
                        ? null
                        : Border.all(color: c.line, width: 0.5),
                    boxShadow: on ? c.shadow1 : null,
                  ),
                  child: Text('$m分钟',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: on ? c.onPrimary : c.text)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text('再次点选同一时长即可取消定时',
              style: TextStyle(fontSize: 11, color: c.text3)),
        ),
      ],
    );
  }
}

class _MixSheet extends StatelessWidget {
  const _MixSheet();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    // 只订阅音轨列表；其余播放器通知不重建弹层。
    final tracks = context.select<PlayerService, List<PlayerTrack>>(
        (PlayerService p) => p.tracks);
    return _SheetShell(
      title: '当前混音',
      badge: tracks.isNotEmpty ? '${tracks.length}/6 路' : null,
      children: [
        Flexible(
          child: tracks.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: tracks.length,
                  itemBuilder: (BuildContext context, int i) {
                    final player = context.read<PlayerService>();
                    final t = tracks[i];
                    return MixTrack(
                      name: t.name,
                      iconName: t.iconName,
                      color: t.color,
                      volume: t.volume,
                      isMuted: t.muted,
                      onVolumeChange: (int v) => player.setTrackVolume(t.id, v),
                      onMute: () => player.toggleTrackMute(t.id),
                      onRemove: () => player.removeTrack(t.id),
                    );
                  },
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('暂无音轨，点上方播放键开始混音',
                        style: TextStyle(fontSize: 12.5, color: c.text2)),
                  ),
                ),
        ),
      ],
    );
  }
}
