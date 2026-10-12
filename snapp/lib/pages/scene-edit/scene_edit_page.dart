import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/scene_models.dart';
import '../../data/sound_models.dart';
import '../../data/seed_data.dart';
import '../../services/custom_scene_service.dart';
import '../../services/player_service.dart';
import '../../theme/theme_extension.dart';
import '../../utils/style_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_section.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/mix_track.dart';
import '../../widgets/nav_bar.dart';
import '../../widgets/segmented.dart';
import '../../widgets/sound_card.dart';

/// 新建 / 编辑场景（对照原型 `pages/scene-edit/scene-edit.vue`）：
/// 名称输入 + 当前配方概览 + 声音库选择 + 音量调节 + 底部操作条。
/// 保存写入 [CustomSceneService]（持久化 `shengqi-scenes`），编辑态回填对应自定义场景。
class SceneEditPage extends StatefulWidget {
  const SceneEditPage({super.key});

  @override
  State<SceneEditPage> createState() => _SceneEditPageState();
}

class _SceneEditPageState extends State<SceneEditPage> {
  static const int _maxTracks = 6;

  final TextEditingController _nameCtrl = TextEditingController();
  bool _isEdit = false;
  String _editingId = '';
  String _activeCat = 'all';
  List<PlayerTrack> _tracks = <PlayerTrack>[];
  bool _argsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;
    // 路径参数：/scene-edit/:sceneId（'new' 表示新建）。
    final id = GoRouterState.of(context).params['sceneId'];
    if (id != null && id.isNotEmpty && id != 'new') {
      final scene = context.read<CustomSceneService>().findById(id);
      if (scene != null) {
        _isEdit = true;
        _editingId = scene.id;
        _nameCtrl.text = scene.name;
        _tracks = scene.soundIds.map((String sid) {
          final s = _findSound(sid);
          return PlayerTrack(
            id: sid,
            name: s?.name ?? sid,
            iconName: s?.iconName ?? 'wave',
            color: s?.color ?? '#8296A8',
          );
        }).toList();
      }
    }
  }

  Sound? _findSound(String id) {
    for (final s in sounds) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<Sound> get _filteredSounds {
    if (_activeCat == 'all') return sounds;
    return sounds.where((Sound s) => s.category == _activeCat).toList();
  }

  int get _totalPercent =>
      _tracks.fold(0, (int sum, PlayerTrack t) => sum + t.volume);

  void _toggleSound(Sound s) {
    final idx = _tracks.indexWhere((PlayerTrack t) => t.id == s.id);
    if (idx >= 0) {
      setState(() => _tracks.removeAt(idx));
      return;
    }
    if (_tracks.length >= _maxTracks) {
      showAppToast(context, '已达混音上限($_maxTracks路)');
      return;
    }
    setState(() {
      _tracks.add(PlayerTrack(
        id: s.id,
        name: s.name,
        iconName: s.iconName,
        color: s.color,
      ));
    });
  }

  void _toggleMute(String id) {
    setState(() {
      for (final t in _tracks) {
        if (t.id == id) t.muted = !t.muted;
      }
    });
  }

  void _removeTrack(String id) {
    setState(() => _tracks = _tracks.where((PlayerTrack x) => x.id != id).toList());
  }

  void _cancel() => Navigator.maybePop(context);

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      showAppToast(context, '请输入场景名称');
      return;
    }
    if (_tracks.isEmpty) {
      showAppToast(context, '请至少添加一种声音');
      return;
    }
    final id = _isEdit ? _editingId : 'custom-${DateTime.now().millisecondsSinceEpoch}';
    final first = _tracks.first;
    final scene = Scene(
      id: id,
      name: _nameCtrl.text.trim(),
      category: 'custom',
      desc: '自定义混音场景',
      iconName: first.iconName,
      gradient: first.color,
      image: '',
      soundIds: _tracks.map((PlayerTrack t) => t.id).toList(),
      isPreset: false,
    );
    final service = context.read<CustomSceneService>();
    if (_isEdit) {
      await service.update(scene);
    } else {
      await service.add(scene);
    }
    if (!mounted) return;
    showAppToast(context, _isEdit ? '场景已更新' : '场景已创建');
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.maybePop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return AppPage(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: NavBar(title: _isEdit ? '编辑场景' : '新建场景'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  const AppSectionTitle('场景名称'),
                  _buildNameField(c),
                  const SizedBox(height: 15),
                  _buildRecipeOverview(c),
                  const SizedBox(height: 15),
                  _buildSoundLibrary(c),
                  const SizedBox(height: 15),
                  _buildVolumeSection(c),
                ],
              ),
            ),
          ),
          _buildFooter(c),
        ],
      ),
    );
  }

  Widget _buildNameField(AppColors c) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: c.sunken,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line, width: 0.5),
      ),
      child: Row(
        children: [
          AppIcon(name: 'edit', size: 20, color: c.primary),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              maxLength: 20,
              style: TextStyle(fontSize: 14, color: c.text),
              cursorColor: c.primary,
              decoration: InputDecoration(
                hintText: '给场景取个名字，如「雨天阅读」',
                hintStyle: TextStyle(fontSize: 14, color: c.text3),
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeOverview(AppColors c) {
    final head = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        const AppSectionTitle('当前配方'),
        const Spacer(),
        if (_tracks.isNotEmpty)
          Text('${_tracks.length} 路 / $_maxTracks 路',
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w600, color: c.primary)),
      ],
    );
    if (_tracks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          head,
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            child: Column(
              children: [
                AppIcon(name: 'wave', size: 40, color: c.text3),
                const SizedBox(height: 7),
                Text('还没有添加声音，去下方挑选吧',
                    style: TextStyle(fontSize: 12.5, color: c.text2)),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        head,
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _tracks.map((PlayerTrack t) {
            final color = hexToColor(t.color) ?? c.primary;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(name: t.iconName, size: 18, color: c.onCover),
                  const SizedBox(width: 4),
                  Text(t.name,
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600, color: c.onCover)),
                  const SizedBox(width: 2),
                  Text('${t.volume}%',
                      style: TextStyle(fontSize: 10, color: c.onCoverSoft)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 9),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('总占比', style: TextStyle(fontSize: 11.5, color: c.text2)),
              const SizedBox(width: 7),
              Text('$_totalPercent%',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: c.primary)),
              const Spacer(),
              Text('下方滑动可调整各路音量',
                  style: TextStyle(fontSize: 10.5, color: c.text3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoundLibrary(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('声音库'),
        Segmented(
          options: soundCategories
              .map((SoundCategoryItem s) => SegmentOption(s.key, s.label))
              .toList(),
          value: _activeCat,
          onChanged: (String k) => setState(() => _activeCat = k),
        ),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _filteredSounds.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                SizedBox(
                  width: 82,
                  child: SoundCard(
                    name: _filteredSounds[i].name,
                    type: _filteredSounds[i].type,
                    iconName: _filteredSounds[i].iconName,
                    color: _filteredSounds[i].color,
                    isActive:
                        _tracks.any((PlayerTrack t) => t.id == _filteredSounds[i].id),
                    onTap: () => _toggleSound(_filteredSounds[i]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeSection(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('调节音量比例'),
        if (_tracks.isNotEmpty) ...[
          for (final t in _tracks)
            MixTrack(
              name: t.name,
              iconName: t.iconName,
              color: t.color,
              volume: t.volume,
              isMuted: t.muted,
              onVolumeChange: (int v) {
                setState(() => t.volume = v);
              },
              onMute: () => _toggleMute(t.id),
              onRemove: () => _removeTrack(t.id),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
            child: Text('* 原型演示：滑块仅做视觉示意，拖动不改变真实比例',
                style: TextStyle(fontSize: 10, color: c.text3)),
          ),
        ] else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: Text('暂无音量轨道',
                  style: TextStyle(fontSize: 12, color: c.text3)),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        boxShadow: c.shadow2,
      ),
      padding: EdgeInsets.fromLTRB(13, 10, 13, 10 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _cancel,
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: c.primary.withOpacity(0.55)),
                ),
                child: Text('取消',
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: c.primary)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _save,
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('保存',
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: c.onPrimary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
