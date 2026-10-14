import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/achievement_service.dart';
import '../services/app_storage.dart';
import '../services/checkin_service.dart';
import '../services/custom_scene_service.dart';
import '../services/favorites_service.dart';
import '../services/player_service.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extension.dart';
import '../theme/theme_notifier.dart';
import 'router.dart';
import 'shell.dart';
import 'shell_tabs.dart';

/// 应用根组件。
///
/// 主题经 [ThemeNotifier] 驱动：配色 / UI 风格 / 明暗改变时，`Consumer`
/// 重建 [MaterialApp.router] 并注入新的 [ThemeData]，全局即时生效。
/// 播放状态经 [PlayerService] 全局共享（首页主控卡 / 场景网格 / PlayBar）。
/// 页面路由由 [GoRouter] 声明式承载（见 [buildRouter]），4 个 tab 页在
/// [ShellWidget] 内以 IndexedStack 保活切换。
/// [onboarded]：首启引导状态（main 读取 `shengqi-onboarded` 传入），转成
/// [OnboardState] 交给路由 redirect 守卫；引导完成后写标记并自动进入主壳。
class Root extends StatefulWidget {
  final ThemeNotifier notifier;
  final PlayerService player;
  final FavoritesService favorites;
  final CheckinService checkin;
  final CustomSceneService customScenes;
  final StatsService stats;
  final AchievementService achievement;
  final bool onboarded;

  /// 初始路由覆盖（测试装配用，生产不传走默认 `/`）。
  final String? initialLocation;
  const Root({
    super.key,
    required this.notifier,
    required this.player,
    required this.favorites,
    required this.checkin,
    required this.customScenes,
    required this.stats,
    required this.achievement,
    this.onboarded = true,
    this.initialLocation,
  });

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  late final OnboardState _onboard =
      OnboardState(onboarded: widget.onboarded);
  late final GoRouter _router = buildRouter(
    _onboard,
    onOnboardDone: _finishOnboarding,
    initialLocation: widget.initialLocation,
  );

  /// 引导完成：写存储标记（不可用时静默跳过）并通知路由守卫放行主壳。
  void _finishOnboarding() {
    AppStorage.setString(AppStorage.keyOnboarded, 'true');
    _onboard.complete();
  }

  @override
  void dispose() {
    _onboard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>.value(value: widget.notifier),
        ChangeNotifierProvider<PlayerService>.value(value: widget.player),
        ChangeNotifierProvider<FavoritesService>.value(value: widget.favorites),
        ChangeNotifierProvider<CheckinService>.value(value: widget.checkin),
        ChangeNotifierProvider<CustomSceneService>.value(value: widget.customScenes),
        ChangeNotifierProvider<StatsService>.value(value: widget.stats),
        ChangeNotifierProvider<AchievementService>.value(value: widget.achievement),
        ChangeNotifierProvider<ShellTabNotifier>(create: (_) => ShellTabNotifier()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (BuildContext context, ThemeNotifier n, Widget? _) {
          final colors = appColorsFor(n.schemeKey, n.ui.key, n.resolvedBrightness);
          return MaterialApp.router(
            title: '声栖',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(colors),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
