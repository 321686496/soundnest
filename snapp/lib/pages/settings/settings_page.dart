import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_storage.dart';
import '../../theme/theme_extension.dart';
import '../../theme/theme_notifier.dart';
import '../../theme/theme_tokens.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_section.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/nav_bar.dart';

/// 设置（对照原型 `pages/settings/settings.vue`）：
/// 播放设置 / 提醒设置（shengqi-reminder 单一数据源）/ 关于。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _reminderKey = 'shengqi-reminder';
  static const String _defaultTime = '22:30';

  bool _autoResume = true;
  double _fadeDuration = 1;
  int _maxTracks = 6;
  bool _reminderOn = false;
  String _reminderTime = _defaultTime;

  @override
  void initState() {
    super.initState();
    _loadReminder();
    _loadPlaySettings();
  }

  Future<void> _loadPlaySettings() async {
    final raw = await AppStorage.getString(AppStorage.keyPlaySettings);
    if (raw != null && raw.isNotEmpty) {
      try {
        final v = jsonDecode(raw);
        if (v is Map) {
          if (v['autoResume'] is bool) _autoResume = v['autoResume'] as bool;
          if (v['fadeDuration'] is num) {
            _fadeDuration = (v['fadeDuration'] as num).toDouble();
          }
          if (v['maxTracks'] is int) _maxTracks = v['maxTracks'] as int;
        }
      } catch (_) {
        // 读取失败回退默认
      }
    }
    if (mounted) setState(() {});
  }

  void _persistPlaySettings() {
    AppStorage.setString(
      AppStorage.keyPlaySettings,
      jsonEncode(<String, dynamic>{
        'autoResume': _autoResume,
        'fadeDuration': _fadeDuration,
        'maxTracks': _maxTracks,
      }),
    );
  }

  Future<void> _loadReminder() async {
    final raw = await AppStorage.getString(_reminderKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final v = jsonDecode(raw);
        if (v is Map) {
          _reminderOn = v['on'] == true;
          final t = v['time'];
          if (t is String && RegExp(r'^\d{2}:\d{2}$').hasMatch(t)) {
            _reminderTime = t;
          }
        }
      } catch (_) {
        // 读取失败回退默认
      }
    }
    if (mounted) setState(() {});
  }

  void _persistReminder() {
    // 单对象经 JSON 字符串落库（AppStorage 列表接口面向数组，这里直接存串）。
    AppStorage.setString(_reminderKey,
        jsonEncode(<String, dynamic>{'on': _reminderOn, 'time': _reminderTime}));
  }

  void _onReminderChanged(bool v) {
    setState(() => _reminderOn = v);
    _persistReminder();
  }

  Future<void> _openTimePicker() async {
    final parts = _reminderTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 22,
      minute: int.tryParse(parts[1]) ?? 30,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (BuildContext context, Widget? child) {
        final n = context.watch<ThemeNotifier>();
        final colors = appColorsFor(n.schemeKey, n.ui.key, n.resolvedBrightness);
        return Theme(
          data: buildLocalDialogTheme(context, colors),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final t =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _reminderTime = t);
      _persistReminder();
    }
  }

  Future<void> _openChoiceSheet(
      String title, List<String> options, String current, ValueChanged<String> onPick) async {
    final c = Theme.of(context).appColors;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(title,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((String v) {
              final active = v == current;
              return GestureDetector(
                onTap: () {
                  onPick(v);
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? c.primarySoft : c.surface2,
                    borderRadius: BorderRadius.circular(999),
                    border: active
                        ? Border.all(color: c.primary, width: 1)
                        : (c.line.opacity > 0.01
                            ? Border.all(color: c.line, width: 0.5)
                            : null),
                  ),
                  child: Text(v,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                          color: active ? c.primary : c.text2)),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final n = context.watch<ThemeNotifier>();
    final switchColor = schemePrimary(n.schemeKey, n.resolvedBrightness);
    final currentThemeLabel =
        '${schemeLabels[n.schemeKey]?.label ?? n.schemeKey} · ${n.ui.label}';

    return AppPage(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NavBar(title: '设置'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionTitle('播放设置'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        _SwitchRow(
                          icon: AppIcon(name: 'play', size: 20, color: c.primary),
                          label: '启动时自动恢复播放',
                          desc: '打开 App 时自动恢复上次的声音组合',
                          value: _autoResume,
                          switchColor: switchColor,
                          onChanged: (bool v) {
                            setState(() => _autoResume = v);
                            _persistPlaySettings();
                          },
                        ),
                        const AppDivider(),
                        _ValueRow(
                          icon: AppIcon(name: 'wave', size: 20, color: c.primary),
                          label: '淡入淡出时长',
                          desc: '播放/停止时的过渡时间',
                          value: '$_fadeDuration s',
                          onTap: () => _openChoiceSheet(
                              '淡入淡出时长',
                              <String>['0.5', '1', '1.5', '2']
                                  .map((String v) => '${v}s')
                                  .toList(),
                              '$_fadeDuration s',
                              (String v) {
                                setState(() => _fadeDuration =
                                    double.parse(v.replaceAll('s', '')));
                                _persistPlaySettings();
                              }),
                        ),
                        const AppDivider(),
                        _ValueRow(
                          icon: AppIcon(name: 'mixer', size: 20, color: c.primary),
                          label: '混音轨数上限',
                          desc: '同时播放的声音数量上限',
                          value: '$_maxTracks 路',
                          onTap: () => _openChoiceSheet(
                              '混音轨数上限',
                              <String>['4', '6', '8']
                                  .map((String v) => '$v 路')
                                  .toList(),
                              '$_maxTracks 路',
                              (String v) {
                                setState(() => _maxTracks =
                                    int.parse(v.replaceAll('路', '').trim()));
                                _persistPlaySettings();
                              }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const AppSectionTitle('提醒设置'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        _SwitchRow(
                          icon: AppIcon(name: 'moon', size: 20, color: c.primary),
                          label: '每日助眠提醒',
                          desc: _reminderOn ? '在设定时间提醒你开始放松' : '已关闭',
                          value: _reminderOn,
                          switchColor: switchColor,
                          onChanged: _onReminderChanged,
                        ),
                        if (_reminderOn) ...[
                          const AppDivider(),
                          _ValueRow(
                            icon: AppIcon(
                                name: 'timer', size: 20, color: c.primary),
                            label: '提醒时间',
                            value: _reminderTime,
                            onTap: _openTimePicker,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const AppSectionTitle('关于'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        _ValueRow(
                          icon: AppIcon(
                              name: 'palette', size: 20, color: c.primary),
                          label: '当前主题',
                          value: currentThemeLabel,
                          valueIsTheme: true,
                          onTap: () => context.push('/theme'),
                        ),
                        const AppDivider(),
                        _ValueRow(
                          icon: AppIcon(
                              name: 'mountain', size: 20, color: c.primary),
                          label: '版本',
                          value: 'v1.0.0',
                          showChevron: false,
                        ),
                        const AppDivider(),
                        _ValueRow(
                          icon: AppIcon(
                              name: 'close', size: 20, color: c.primary),
                          label: '清除缓存',
                          value: '12.3 MB',
                          onTap: () => showAppToast(context, '缓存已清除'),
                        ),
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

/// 构建时间选择弹窗的主题（跟随当前配色）。
ThemeData buildLocalDialogTheme(BuildContext context, AppColors colors) {
  final base = Theme.of(context);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(primary: colors.primary),
    dialogTheme: DialogTheme(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );
}

class _SettingIcon extends StatelessWidget {
  final Widget child;
  const _SettingIcon({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: c.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Center(child: child),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String desc;
  final bool value;
  final Color switchColor;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.desc,
    required this.value,
    required this.switchColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      child: Row(
        children: [
          _SettingIcon(child: icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(fontSize: 11, color: c.text2)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              activeColor: switchColor,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String? desc;
  final String value;
  final bool valueIsTheme;
  final bool showChevron;
  final VoidCallback? onTap;
  const _ValueRow({
    required this.icon,
    required this.label,
    required this.value,
    this.desc,
    this.valueIsTheme = false,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        child: Row(
          children: [
            _SettingIcon(child: icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.text)),
                  if (desc != null) ...[
                    const SizedBox(height: 2),
                    Text(desc!,
                        style: TextStyle(fontSize: 11, color: c.text2)),
                  ],
                ],
              ),
            ),
            Text(value,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: valueIsTheme ? c.primary : c.text2)),
            if (showChevron) ...[
              const SizedBox(width: 4),
              AppIcon(name: 'chevron-right', size: 20, color: c.text3),
            ],
          ],
        ),
      ),
    );
  }
}
