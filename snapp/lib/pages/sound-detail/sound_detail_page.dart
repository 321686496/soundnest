import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/sound_models.dart';
import '../../data/seed_data.dart';
import '../../services/player_service.dart';
import '../../theme/theme_extension.dart';
import '../../utils/style_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_section.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/nav_bar.dart';
import '../../widgets/pressable.dart';

/// 声音详情页（Flutter 侧新增，无原型对应页）：
/// 浮动渐变 Hero（与场景详情 Hero 同视觉语言）+ 规格参数 + 适用场景 +
/// 试听 / 加入混音（真实生效）。路由 /sound/:soundId。
class SoundDetailPage extends StatefulWidget {
  const SoundDetailPage({super.key});

  @override
  State<SoundDetailPage> createState() => _SoundDetailPageState();
}

class _SoundDetailPageState extends State<SoundDetailPage> {
  String _soundId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 路径参数：/sound/:soundId。
    if (_soundId.isEmpty) {
      _soundId = GoRouterState.of(context).params['soundId'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    // 只订阅「该声音是否已在混音」；其余播放器通知不重建整页。
    final player = context.read<PlayerService>();
    final sound = player.findSound(_soundId) ?? sounds.first;
    final inMix = context.select<PlayerService, bool>(
        (PlayerService p) => p.tracks.any((PlayerTrack t) => t.id == sound.id));

    return AppPage(
      bottomBarSpace: true,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: NavBar(title: '声音详情'),
            ),
            _SoundHero(sound: sound),
            _buildSection(c, '规格参数', _SpecCard(sound: sound)),
            _buildSection(c, '适用场景', _TagsCard(sound: sound)),
            _buildSection(c, '', _ActionRow(sound: sound, inMix: inMix)),
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
}

/// 浮动渐变 Hero：声音 gradient 底 + 图标圆底光晕 + 名称/类型/描述。
class _SoundHero extends StatelessWidget {
  const _SoundHero({required this.sound});
  final Sound sound;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final g = parseCssGradient(sound.gradient);
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
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: Colors.white.withOpacity(0.22),
                    blurRadius: 24,
                    spreadRadius: 8),
                BoxShadow(
                    color: Colors.white.withOpacity(0.10),
                    blurRadius: 52,
                    spreadRadius: 20),
              ],
            ),
            alignment: Alignment.center,
            child: AppIcon(name: sound.iconName, size: 96, color: c.onCover),
          ),
          const SizedBox(height: 14),
          Text(sound.name,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: c.onCover)),
          const SizedBox(height: 4),
          Text(sound.type,
              style: TextStyle(fontSize: 11.5, color: c.onCoverSoft)),
          const SizedBox(height: 10),
          Text(sound.desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, height: 1.6, color: c.onCoverSoft)),
        ],
      ),
    );
  }
}

/// 规格参数五行表（迁自音疗库底部弹层 _MetaRow）。
class _SpecCard extends StatelessWidget {
  const _SpecCard({required this.sound});
  final Sound sound;

  static const List<String> _labels = <String>[
    '时长', '采样率', '音质', '循环片段', '来源',
  ];

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final values = <String>[
      sound.duration, sound.sampleRate, sound.quality, sound.loopLength, sound.source,
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == _labels.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: c.line, width: 0.5)),
              ),
              child: Row(
                children: [
                  Text(_labels[i],
                      style: TextStyle(fontSize: 12, color: c.text2)),
                  const Spacer(),
                  Flexible(
                    child: Text(values[i],
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: c.text)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 适用场景标签（primarySoft 胶囊）。
class _TagsCard extends StatelessWidget {
  const _TagsCard({required this.sound});
  final Sound sound;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: sound.scenes
            .map((String tag) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(tag,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: c.primary)),
                ))
            .toList(),
      ),
    );
  }
}

/// 操作行：试听（主钮）+ 加入混音（次钮，已在混音中呈禁用态）。
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.sound, required this.inMix});
  final Sound sound;
  final bool inMix;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Row(
      children: [
        Expanded(
          child: PressableScale(
            onTap: () {
              context.read<PlayerService>().playSound(sound);
              showAppToast(context, '正在试听 ${sound.name}');
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(999),
                boxShadow: c.shadow1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(name: 'play', size: 20, color: c.onPrimary),
                  const SizedBox(width: 5),
                  Text('试听',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: c.onPrimary)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PressableScale(
            onTap: inMix
                ? null
                : () {
                    final ok = context.read<PlayerService>().addTrack(sound);
                    showAppToast(context, ok ? '已加入混音' : '最多支持 6 路混音');
                  },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: inMix ? c.sunken : null,
                borderRadius: BorderRadius.circular(999),
                border: inMix
                    ? null
                    : Border.all(color: c.primary.withOpacity(0.55)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                      name: inMix ? 'check' : 'mixer',
                      size: 20,
                      color: inMix ? c.text3 : c.primary),
                  const SizedBox(width: 5),
                  Text(inMix ? '已在混音中' : '加入混音',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: inMix ? c.text3 : c.primary)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
