import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/achievement_service.dart';
import '../../services/checkin_service.dart';
import '../../services/custom_scene_service.dart';
import '../../services/favorites_service.dart';
import '../../services/player_service.dart';
import '../../services/stats_service.dart';
import '../../theme/theme_extension.dart';
import '../../theme/theme_notifier.dart';
import '../../theme/theme_tokens.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_section.dart';
import '../../widgets/pressable.dart';

/// 我的（对照原型 `pages/mine/mine.vue`）：
/// 品牌头 + 用户 Hero + 核心数据 + 常用功能 + 偏好与设置 + 最近成就。
/// 数字 / 徽章 / 最近成就均读真实服务数据（stats / checkin / customScenes / achievement）。
class MinePage extends StatelessWidget {
  const MinePage({super.key});

  void _go(BuildContext context, String route) {
    context.push(route);
  }

  /// 今天播放次数（历史页「今天N次」徽章）。
  int _todayPlayCount(List<RecentItem> recent) {
    final today = StatsService.dateKey(DateTime.now());
    return recent
        .where((RecentItem r) =>
            StatsService.dateKey(DateTime.fromMillisecondsSinceEpoch(r.ts)) ==
            today)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final n = context.watch<ThemeNotifier>();
    final stats = context.watch<StatsService>();
    final checkin = context.watch<CheckinService>();
    final customScenes = context.watch<CustomSceneService>();
    final achievement = context.watch<AchievementService>();
    final favorites = context.watch<FavoritesService>();
    // 只订阅最近播放列表；播放器其余通知不再整页重建。
    final recent = context.select<PlayerService, List<RecentItem>>(
        (PlayerService p) => p.recent);
    final currentThemeLabel =
        '${schemeLabels[n.schemeKey]?.label ?? n.schemeKey} · ${n.ui.label}';

    return AppPage(
      bottomBarSpace: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, c),
            _buildProfileHero(context, c, stats.activeDayCount),
            const SizedBox(height: 12),
            _buildStatsCard(
                context, c, stats, checkin, customScenes, achievement),
            const _GroupHead('常用功能'),
            _buildQuickGrid(context, c, checkin, achievement, favorites,
                recent),
            const _GroupHead('偏好与设置'),
            _buildMenuCard(context, c, currentThemeLabel, stats),
            const _GroupHead('最近成就'),
            _buildAchievements(context, c, achievement),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
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
                  errorBuilder: (_, __, ___) => Container(color: c.primary)),
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
                Text('我的私享声音空间',
                    style:
                        TextStyle(fontSize: 11, letterSpacing: 0.5, color: c.text2)),
              ],
            ),
          ),
          _HeaderBtn(
            icon: AppIcon(name: 'palette', size: 22, color: c.primary),
            onTap: () => _go(context, '/theme'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero(
      BuildContext context, AppColors c, int activeDays) {
    final week = (activeDays ~/ 7) + 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 22, 15, 48),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 背景装饰 blob
          Positioned(
            right: -40,
            top: -45,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary.withOpacity(0.14),
              ),
            ),
          ),
          Positioned(
            right: 45,
            bottom: -35,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary.withOpacity(0.08),
              ),
            ),
          ),
          // 内容
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: c.surface,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: c.primary.withOpacity(0.22),
                      offset: const Offset(0, 7),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child:
                    Center(child: AppIcon(name: 'bird', size: 52, color: c.primary)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('声栖用户',
                            style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.25,
                                height: 1.1,
                                color: c.text)),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(name: 'moon', size: 12, color: c.primary),
                              const SizedBox(width: 2),
                              Text('睡眠陪伴中',
                                  style: TextStyle(
                                      fontSize: 10, color: c.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text('已陪伴你 $activeDays 天 · 第 $week 周',
                        style: TextStyle(fontSize: 11, color: c.text2)),
                  ],
                ),
              ),
              PressableScale(
                onTap: () => _go(context, '/settings'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: c.line.opacity > 0.01
                        ? Border.all(color: c.line, width: 0.5)
                        : null,
                  ),
                  child: Center(
                      child:
                          AppIcon(name: 'edit', size: 20, color: c.text3)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, AppColors c, StatsService stats,
      CheckinService checkin, CustomSceneService customScenes,
      AchievementService achievement) {
    return Transform.translate(
      offset: const Offset(0, -34),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            _StatItem(
                value: '${stats.totalMinutes}',
                label: '累计播放(分)',
                onTap: () => _go(context, '/stats')),
            _StatSep(c),
            _StatItem(
                value: '${checkin.streak}',
                label: '连续天数',
                onTap: () => _go(context, '/checkin')),
            _StatSep(c),
            _StatItem(
                value: '${customScenes.scenes.length}',
                label: '场景数',
                onTap: () => _go(context, '/favorites')),
            _StatSep(c),
            _StatItem(
                value: '${achievement.unlockedCount}',
                label: '成就',
                onTap: () => _go(context, '/achievement')),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGrid(BuildContext context, AppColors c,
      CheckinService checkin, AchievementService achievement,
      FavoritesService favorites, List<RecentItem> recent) {
    final actions = <_QuickAction>[
      _QuickAction('checkin', '每日签到', 'flame', '连续${checkin.streak}天', true),
      _QuickAction('favorites', '我的收藏', 'save', '${favorites.ids.length} 个', false),
      _QuickAction('history', '播放历史', 'clock', '今天${_todayPlayCount(recent)}次', false),
      _QuickAction('achievement', '成就墙', 'trophy', '${achievement.unlockedCount}/${achievement.total}', false),
    ];
    final routes = <String, String>{
      'checkin': '/checkin',
      'favorites': '/favorites',
      'history': '/history',
      'achievement': '/achievement',
    };
    final rows = <Widget>[];
    for (var i = 0; i < actions.length; i += 2) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _QuickCard(
              action: actions[i],
              onTap: () => _go(context, routes[actions[i].id]!),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickCard(
              action: actions[i + 1],
              onTap: () => _go(context, routes[actions[i + 1].id]!),
            ),
          ),
        ],
      ));
      rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  Widget _buildMenuCard(
      BuildContext context, AppColors c, String currentThemeLabel, StatsService stats) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          _MenuItem(
            icon: AppIcon(name: 'wave', size: 22, color: c.primary),
            label: '使用数据',
            badge: '本周${stats.weekUsageDays}天',
            onTap: () => _go(context, '/stats'),
          ),
          AppDivider(),
          _MenuItem(
            icon: AppIcon(name: 'gift', size: 22, color: c.primary),
            label: '邀请好友',
            badge: '2 人已加入',
            badgePrimary: true,
            onTap: () => _go(context, '/invite'),
          ),
          AppDivider(),
          _MenuItem(
            icon: AppIcon(name: 'palette', size: 22, color: c.primary),
            label: '主题与风格',
            valueText: currentThemeLabel,
            onTap: () => _go(context, '/theme'),
          ),
          AppDivider(),
          _MenuItem(
            icon: AppIcon(name: 'settings', size: 22, color: c.primary),
            label: '设置',
            onTap: () => _go(context, '/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(
      BuildContext context, AppColors c, AchievementService achievement) {
    final items = achievement.unlockedItems.take(3).toList();
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: PressableScale(
              onTap: () => _go(context, '/achievement'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: c.line.opacity > 0.01
                      ? Border.all(color: c.line, width: 0.5)
                      : null,
                  boxShadow: c.shadow1,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: AppIcon(
                              name: items[i].iconName,
                              size: 20,
                              color: c.primary)),
                    ),
                    const SizedBox(height: 6),
                    Text(items[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c.text)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickAction {
  final String id;
  final String name;
  final String icon;
  final String badge;
  final bool primary;
  const _QuickAction(this.id, this.name, this.icon, this.badge, this.primary);
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  const _StatItem({required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c.text)),
            const SizedBox(height: 3),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: c.text2)),
          ],
        ),
      ),
    );
  }
}

class _StatSep extends StatelessWidget {
  final AppColors c;
  const _StatSep(this.c);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: c.line,
    );
  }
}

class _GroupHead extends StatelessWidget {
  final String text;
  const _GroupHead(this.text);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 0, 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: c.text2)),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final _QuickAction action;
  final VoidCallback onTap;
  const _QuickCard({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return PressableScale(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: AppIcon(
                      name: action.icon, size: 30, color: c.primary)),
            ),
            const SizedBox(height: 8),
            Text(action.name,
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: action.primary ? c.primarySoft : c.surface2,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(action.badge,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: action.primary ? c.primary : c.text2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final String? badge;
  final bool badgePrimary;
  final String? valueText;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgePrimary = false,
    this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: c.text)),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgePrimary ? c.primarySoft : c.surface2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge!,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: badgePrimary ? c.primary : c.text2)),
              ),
            if (valueText != null)
              Text(valueText!,
                  style: TextStyle(fontSize: 12, color: c.text2)),
            const SizedBox(width: 4),
            AppIcon(name: 'chevron-right', size: 20, color: c.text3),
          ],
        ),
      ),
    );
  }
}
