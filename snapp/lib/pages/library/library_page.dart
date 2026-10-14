import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/sound_models.dart';
import '../../data/seed_data.dart';
import '../../theme/theme_extension.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/nav_bar.dart';
import '../../widgets/pressable.dart';
import '../../widgets/segmented.dart';
import '../../widgets/sound_card.dart';

/// 声音库（对照原型 `pages/library/library.vue`）：
/// 搜索栏 + 分类分段 + 声音网格，点按声音卡跳转声音详情页。
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
    context.push('/sound/${sound.id}');
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
