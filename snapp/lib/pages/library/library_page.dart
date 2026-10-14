import 'package:flutter/material.dart';

import '../../data/sound_models.dart';
import '../../data/seed_data.dart';
import '../../theme/theme_extension.dart';
import '../../utils/style_utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/nav_bar.dart';
import '../../widgets/pressable.dart';
import '../../widgets/segmented.dart';
import '../../widgets/sound_card.dart';

/// 声音库（对照原型 `pages/library/library.vue`）：
/// 搜索栏 + 分类分段 + 声音网格 + 声音详情底部弹窗。
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _keyword = '';
  String _activeCat = 'all';
  Sound? _selected;

  final TextEditingController _searchCtrl = TextEditingController();

  List<Sound> get _filteredSounds {
    final kw = _keyword.trim().toLowerCase();
    return sounds.where((Sound s) {
      final matchCat = _activeCat == 'all' || s.category == _activeCat;
      final matchKw = kw.isEmpty ||
          s.name.toLowerCase().contains(kw) ||
          s.desc.toLowerCase().contains(kw) ||
          s.type.toLowerCase().contains(kw);
      return matchCat && matchKw;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDetail(Sound sound) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _SoundDetailSheet(sound: sound),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final list = _filteredSounds;
    return AppPage(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: NavBar(title: '声音库'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(c),
                  const SizedBox(height: 13),
                  Segmented(
                    options: soundCategories
                        .map((SoundCategoryItem s) =>
                            SegmentOption(s.key, s.label))
                        .toList(),
                    value: _activeCat,
                    onChanged: (String k) => setState(() => _activeCat = k),
                  ),
                  const SizedBox(height: 13),
                  if (list.isNotEmpty) ...[
                    ..._soundRows(list),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text('共 ${list.length} 个声音 · 点按查看详情',
                            style:
                                TextStyle(fontSize: 11, color: c.text3)),
                      ),
                    ),
                  ] else
                    const EmptyState(
                        icon: 'wave', title: '未找到相关声音', desc: '换个关键词试试吧'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppColors c) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.sunken,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line, width: 0.5),
      ),
      child: Row(
        children: [
          const _SearchIcon(),
          const SizedBox(width: 8),
          Expanded(
            // TextField 需要 Material 祖先（同 scene_edit 页，容器无 Scaffold Material）。
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (String v) => setState(() => _keyword = v),
                style: TextStyle(fontSize: 13, color: c.text),
                cursorColor: c.primary,
                decoration: InputDecoration(
                  hintText: '搜索声音或场景',
                  hintStyle: TextStyle(fontSize: 13, color: c.text3),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          if (_keyword.isNotEmpty)
            PressableScale(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _keyword = '');
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c.surface2,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppIcon(name: 'close', size: 20, color: c.text2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 3 列网格（82px 定宽卡片 + spaceBetween，与原型 auto-fill 164rpx 一致）。
  List<Widget> _soundRows(List<Sound> list) {
    final rows = <Widget>[];
    for (var i = 0; i < list.length; i += 3) {
      final cells = <Widget>[];
      for (var j = 0; j < 3; j++) {
        final idx = i + j;
        if (idx < list.length) {
          cells.add(SizedBox(
            width: 82,
            child: SoundCard(
              name: list[idx].name,
              type: list[idx].type,
              iconName: list[idx].iconName,
              color: list[idx].color,
              isActive: _selected?.id == list[idx].id,
              onTap: () => _openDetail(list[idx]),
            ),
          ));
        } else {
          cells.add(const SizedBox(width: 82));
        }
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cells,
        ),
      ));
    }
    return rows;
  }
}

/// 搜索放大镜（原型自绘 circle + handle）。
class _SearchIcon extends StatelessWidget {
  const _SearchIcon();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return SizedBox(
      width: 15,
      height: 15,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.text3, width: 1.5),
              ),
            ),
          ),
          Positioned(
            right: 0.5,
            bottom: 1.5,
            child: Transform.rotate(
              angle: -45 * 3.141592653589793 / 180,
              child: Container(
                width: 1.5,
                height: 6,
                decoration: BoxDecoration(
                  color: c.text3,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 元数据行。
class _MetaRow {
  final String label;
  final String value;
  const _MetaRow(this.label, this.value);
}

/// 声音详情底部弹窗（Hero + 元数据表 + 适用场景 + 操作）。
class _SoundDetailSheet extends StatelessWidget {
  final Sound sound;
  const _SoundDetailSheet({required this.sound});

  static const List<_MetaRow> _metaBase = <_MetaRow>[
        _MetaRow('时长', ''),
        _MetaRow('采样率', ''),
        _MetaRow('音质', ''),
        _MetaRow('循环片段', ''),
        _MetaRow('来源', ''),
      ];

  List<_MetaRow> get _metaRows {
    final values = <String>[
      sound.duration, sound.sampleRate, sound.quality, sound.loopLength, sound.source,
    ];
    return List<_MetaRow>.generate(
        _metaBase.length, (int i) => _MetaRow(_metaBase[i].label, values[i]));
    }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final g = parseCssGradient(sound.gradient);
    return SafeArea(
      top: false,
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: c.shadow4,
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: c.sunken,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text('声音详情',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.15,
                            color: c.text)),
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
              const SizedBox(height: 4),
              // Hero：声音渐变资产作底，浮层文字走 on-cover token
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: g == null
                      ? null
                      : LinearGradient(
                          begin: g.begin, end: g.end, colors: g.colors),
                  color: g == null ? c.primary : null,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.18),
                      ),
                      child: Center(
                        child: AppIcon(
                            name: sound.iconName,
                            size: 64,
                            color: c.onCover),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(sound.name,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: c.onCover)),
                    const SizedBox(height: 2),
                    Text(sound.type,
                        style: TextStyle(
                            fontSize: 11, color: c.onCoverSoft)),
                    const SizedBox(height: 6),
                    Text(sound.desc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: c.onCoverSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 元数据表
              for (var i = 0; i < _metaRows.length; i++)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  decoration: BoxDecoration(
                    border: i == _metaRows.length - 1
                        ? null
                        : Border(
                            bottom: BorderSide(color: c.line, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Text(_metaRows[i].label,
                          style:
                              TextStyle(fontSize: 12, color: c.text2)),
                      const Spacer(),
                      Flexible(
                        child: Text(_metaRows[i].value,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: c.text)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text('适用场景',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: c.text2)),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sound.scenes
                    .map((String tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 4),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PressableScale(
                      onTap: () =>
                          showAppToast(context, '正在播放 ${sound.name}'),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(name: 'play', size: 20, color: c.onPrimary),
                            const SizedBox(width: 5),
                            Text('播放',
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
                      onTap: () {
                        Navigator.of(context).pop();
                        showAppToast(context, '${sound.name} 已加入混音');
                      },
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: c.primary.withOpacity(0.55)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(name: 'mixer', size: 20, color: c.primary),
                            const SizedBox(width: 5),
                            Text('加入混音',
                                style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: c.primary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
