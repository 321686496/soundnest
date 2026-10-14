import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/scene_models.dart';
import '../../data/seed_data.dart';
import '../../data/sound_models.dart';
import '../../services/player_service.dart';
import '../../theme/theme_extension.dart';
import '../../utils/style_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pressable.dart';
import '../../widgets/scene_card.dart';

/// 发现页（对照原型 `pages/discover/discover.vue`）：
/// 品牌头部 + 今日推荐 Hero + 场景推荐 + 声音精选 + 场景故事。
/// PlayBar 由外层 Shell 在本 tab 挂载。
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverTag {
  final String id;
  final String label;
  final String icon;
  const _DiscoverTag(this.id, this.label, this.icon);
}

class _Story {
  final String id;
  final String title;
  final String text;
  final String scene;
  final String sceneId;
  final String iconName;
  final String gradient;
  const _Story(this.id, this.title, this.text, this.scene, this.sceneId,
      this.iconName, this.gradient);
}

class _DiscoverPageState extends State<DiscoverPage> {
  static final FeaturedScene _hero = featuredScenes.first;

  static const List<_DiscoverTag> _tags = <_DiscoverTag>[
    _DiscoverTag('all', '全部', 'wave'),
    _DiscoverTag('sleep', '助眠', 'moon'),
    _DiscoverTag('focus', '专注', 'flame'),
    _DiscoverTag('relax', '放松', 'forest'),
    _DiscoverTag('nature', '自然', 'mountain'),
  ];

  /// 精选场景网格：按热度（播放量）降序，排除今日推荐 hero。
  List<FeaturedScene> get _filteredFeatured =>
      getHotScenes(_activeTag, excludeId: _hero.id);

  static const List<_Story> _stories = <_Story>[
    _Story('st1', '雨夜书桌', '城市夜晚，雨滴敲打窗棂，世界安静下来，只有翻书声与雨声相伴',
        '雨夜入眠', 'rainy-night', 'rain', 'linear-gradient(135deg,#5F7A92,#B97A48)'),
    _Story('st2', '海边初醒', '清晨的海风裹着潮声，把梦一点点吹散，你在晨光里慢慢清醒',
        '海边日落', 'seaside-sunset', 'wave-ocean', 'linear-gradient(135deg,#4E7182,#8E9E96)'),
    _Story('st3', '林中漫步', '踩过松软的落叶，溪水在不远处低语，整个世界只剩下自然的呼吸',
        '自然放松', 'nature-relax', 'forest', 'linear-gradient(135deg,#5F8296,#7E9A74)'),
  ];

  String _activeTag = 'all';

  /// 精选场景 → 播放器所需 Scene（补全 category / isPreset，均视为预设）。
  Scene _toScene(FeaturedScene f) => Scene(
        id: f.id,
        name: f.name,
        category: featuredSceneCategory[f.id] ?? 'relax',
        desc: f.desc,
        iconName: f.iconName,
        gradient: f.gradient,
        image: _imageOf(f.id),
        soundIds: f.soundIds,
        isPreset: true,
      );

  String _imageOf(String id) {
    for (final s in homeScenes) {
      if (s.id == id) return s.image;
    }
    return '';
  }

  List<String> _soundNames(List<String> ids) => ids.map((String id) {
        for (final s in sounds) {
          if (s.id == id) return s.name;
        }
        return id;
      }).toList();

  void _goDetail(String sceneId) {
    context.push('/scene-detail/$sceneId');
  }

  void _playScene(String sceneId) {
    for (final f in featuredScenes) {
      if (f.id == sceneId) {
        context.read<PlayerService>().applyScene(_toScene(f));
        showAppToast(context, '已开始播放「${f.name}」');
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    // 只订阅当前场景 id；播放器其余通知不再整页重建。
    final currentSceneId = context.select<PlayerService, String?>(
        (PlayerService p) => p.currentScene?.id);
    final heroSoundNames = _soundNames(_hero.soundIds);

    return AppPage(
      bottomBarSpace: true,
      child: SingleChildScrollView(
        // 尾部让位加在滚动内容内部：内容从悬浮 TabBar/PlayBar 下方滑过，
        // 滚到底时最后一条内容完整越过悬浮区（见 AppPage.reservedBottomInset）。
        padding: EdgeInsets.only(bottom: AppPage.reservedBottomInset(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(c),
            _GroupCard(children: [
              const _CardHead(icon: 'flame', title: '今日推荐'),
              _buildHero(c, heroSoundNames),
            ]),
            _GroupCard(children: [
              _buildTagFilter(c),
              Padding(
                padding: const EdgeInsets.fromLTRB(1, 0, 0, 9),
                child: Row(
                  children: [
                    const _CardHead(icon: 'mountain', title: '精选场景'),
                    const Spacer(),
                    PressableScale(
                      onTap: () => context.push('/scene-all'),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Text('查看全部',
                                style: TextStyle(
                                    fontSize: 11.5, color: c.text2)),
                            const SizedBox(width: 1),
                            AppIcon(
                                name: 'chevron-right',
                                size: 14,
                                color: c.text2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_filteredFeatured.isNotEmpty)
                _FeaturedGrid(
                  scenes: _filteredFeatured,
                  currentSceneId: currentSceneId,
                  soundNamesOf: _soundNames,
                  onTap: (FeaturedScene s) => _goDetail(s.id),
                  onPlay: (FeaturedScene s) => _playScene(s.id),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 30),
                  child: Center(
                    child: Text('暂无此类场景',
                        style: TextStyle(fontSize: 12.5, color: c.text2)),
                  ),
                ),
            ]),
            _GroupCard(children: [
              const _CardHead(icon: 'white-noise', title: '声音精选'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < featuredSounds.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _FeaturedSoundItem(
                        sound: featuredSounds[i].sound,
                        hot: featuredSounds[i].hot,
                        onTap: () => showAppToast(
                            context, '${featuredSounds[i].sound.name} 已加入混音'),
                      ),
                    ],
                  ],
                ),
              ),
            ]),
            _GroupCard(children: [
              const _CardHead(icon: 'moon', title: '场景故事'),
              for (var i = 0; i < _stories.length; i++)
                _StoryItem(
                  story: _stories[i],
                  onTap: () => _goDetail(_stories[i].sceneId),
                ),
            ]),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/brand/logo.jpg',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(width: 42, height: 42, color: c.primary)),
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
                Text('今天想探索什么？',
                    style: TextStyle(fontSize: 11, color: c.text2)),
              ],
            ),
          ),
          _HeaderBtn(
            icon: AppIcon(name: 'palette', size: 22, color: c.primary),
            onTap: () => context.push('/theme'),
          ),
          const SizedBox(width: 8),
          _HeaderBtn(
            icon: AppIcon(name: 'wave', size: 22, color: c.primary),
            onTap: () => context.push('/library'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(AppColors c, List<String> heroSounds) {
    final g = parseCssGradient(_hero.gradient);
    return GestureDetector(
      onTap: () => _goDetail(_hero.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: g == null
                  ? null
                  : LinearGradient(
                      begin: g.begin, end: g.end, colors: g.colors),
              color: g == null ? c.primary : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppIcon(
                    name: _hero.iconName,
                    size: 72,
                    color: Colors.white.withOpacity(0.95)),
                Positioned(
                  left: 5,
                  bottom: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(name: 'play', size: 12, color: c.primary),
                        const SizedBox(width: 3),
                        Text(_hero.playCount,
                            style: TextStyle(
                                fontSize: 10, color: c.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_hero.name,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: c.text)),
                const SizedBox(height: 4),
                Text(_hero.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11, height: 1.5, color: c.text2)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: heroSounds
                      .map((String s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: c.primarySoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon(
                                    name: 'play',
                                    size: 14,
                                    color: c.primary),
                                const SizedBox(width: 2),
                                Text(s,
                                    style: TextStyle(
                                        fontSize: 10, color: c.primary)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 6),
                PressableScale(
                  onTap: () => _playScene(_hero.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: c.shadow2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('立即体验',
                            style: TextStyle(
                                fontSize: 12, color: c.onPrimary)),
                        const SizedBox(width: 2),
                        AppIcon(
                            name: 'chevron-right',
                            size: 16,
                            color: c.onPrimary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagFilter(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tag in _tags)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: PressableScale(
                  onTap: () => setState(() => _activeTag = tag.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _activeTag == tag.id
                          ? c.primarySoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: _activeTag == tag.id
                          ? Border.all(
                              color: c.primary.withOpacity(0.3), width: 0.5)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(
                            name: tag.icon,
                            size: 14,
                            color: _activeTag == tag.id
                                ? c.primary
                                : c.text2),
                        const SizedBox(width: 4),
                        Text(tag.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: _activeTag == tag.id
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: _activeTag == tag.id
                                    ? c.primary
                                    : c.text2)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(11),
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

class _FeaturedSoundItem extends StatelessWidget {
  final Sound sound;
  final int hot;
  final VoidCallback onTap;
  const _FeaturedSoundItem({
    required this.sound,
    required this.hot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 11),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hexToColor(sound.color) ?? c.primary,
              ),
              child: Center(
                child: AppIcon(name: sound.iconName, size: 34, color: c.onCover),
              ),
            ),
            const SizedBox(height: 6),
            Text(sound.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.text)),
            Text('热度 $hot',
                style: TextStyle(fontSize: 10, color: c.text3)),
          ],
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final _Story story;
  final VoidCallback onTap;
  const _StoryItem({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final g = parseCssGradient(story.gradient);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: g == null
                    ? null
                    : LinearGradient(
                        begin: g.begin, end: g.end, colors: g.colors),
                color: g == null ? c.primary : null,
              ),
              child: Center(
                child:
                    AppIcon(name: story.iconName, size: 28, color: c.onCover),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.text)),
                  const SizedBox(height: 2),
                  Text(story.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5, height: 1.5, color: c.text2)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      AppIcon(name: 'wave', size: 14, color: c.primary),
                      const SizedBox(width: 4),
                      Text(story.scene,
                          style: TextStyle(
                              fontSize: 10.5, color: c.primary)),
                    ],
                  ),
                ],
              ),
            ),
            AppIcon(name: 'chevron-right', size: 18, color: c.text3),
          ],
        ),
      ),
    );
  }
}

/// 精选场景双列网格。
class _FeaturedGrid extends StatelessWidget {
  final List<FeaturedScene> scenes;
  final String? currentSceneId;
  final List<String> Function(List<String>) soundNamesOf;
  final void Function(FeaturedScene) onTap;
  final void Function(FeaturedScene) onPlay;

  const _FeaturedGrid({
    required this.scenes,
    required this.currentSceneId,
    required this.soundNamesOf,
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
          Expanded(child: _cell(i)),
          const SizedBox(width: 8),
          if (i + 1 < scenes.length)
            Expanded(child: _cell(i + 1))
          else
            const Expanded(child: SizedBox()),
        ],
      ));
      rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }

  Widget _cell(int index) {
    final f = scenes[index];
    return SceneCard(
      name: f.name,
      soundCount: f.soundIds.length,
      soundIcons: <String>[f.iconName],
      bgColor: f.gradient,
      isPreset: true,
      isGrid: true,
      soundLabel: soundNamesOf(f.soundIds).join(' + '),
      active: currentSceneId == f.id,
      onTap: () => onTap(f),
      onPlay: () => onPlay(f),
    );
  }
}
