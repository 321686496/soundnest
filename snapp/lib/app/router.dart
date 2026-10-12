import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/achievement/achievement_page.dart';
import '../pages/checkin/checkin_page.dart';
import '../pages/favorites/favorites_page.dart';
import '../pages/history/history_page.dart';
import '../pages/invite/invite_page.dart';
import '../pages/library/library_page.dart';
import '../pages/onboarding/onboarding_page.dart';
import '../pages/player/player_page.dart';
import '../pages/scene-all/scene_all_page.dart';
import '../pages/scene-detail/scene_detail_page.dart';
import '../pages/scene-edit/scene_edit_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/stats/stats_page.dart';
import '../pages/theme/theme_page.dart';
import 'shell.dart';

/// 引导完成标记的可监听状态：[GoRouter] 经 `refreshListenable` 订阅它，
/// 首次启动未完成引导时由 `redirect` 强制停留在 `/onboarding`。
class OnboardState extends ChangeNotifier {
  bool _onboarded;
  OnboardState({required bool onboarded}) : _onboarded = onboarded;

  bool get onboarded => _onboarded;

  /// 引导完成：置位并通知路由重算（写存储标记的动作由调用方负责）。
  void complete() {
    if (_onboarded) return;
    _onboarded = true;
    notifyListeners();
  }
}

/// 应用路由表（对照原型 `pages.json`，一一对应，go_router 声明式实现）。
///
/// 4 个 tab 页（首页 / 场景 / 发现 / 我的）的真实切换由 [ShellWidget] 内的
/// IndexedStack + [ShellTabNotifier] 管理（对应原型 `uni.switchTab`），
/// 只占根路由 `/`；其余页面为 push 路由。
///
/// 带参页面改用路径 / 查询参数（可深链、类型安全）：
/// `/scene-detail/:sceneId`、`/scene-edit/:sceneId`（`new` 表示新建）、
/// `/scene-all?category=sleep`。
///
/// [onOnboardDone]：引导完成回调（Root 传入，负责写 `shengqi-onboarded`
/// 存储标记并调用 [OnboardState.complete] 放行主壳）。
GoRouter buildRouter(OnboardState onboard, {required VoidCallback onOnboardDone}) => GoRouter(
      initialLocation: onboard.onboarded ? '/' : '/onboarding',
      refreshListenable: onboard,
      debugLogDiagnostics: kDebugMode,
      redirect: (BuildContext context, GoRouterState state) {
        final location = state.location;
        if (!onboard.onboarded) {
          return location == '/onboarding' ? null : '/onboarding';
        }
        return location == '/onboarding' ? '/' : null;
      },
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, __) => const ShellWidget()),
        GoRoute(
          path: '/onboarding',
          builder: (BuildContext context, GoRouterState _) => OnboardingPage(
            onDone: onOnboardDone,
          ),
        ),
        GoRoute(path: '/library', builder: (_, __) => const LibraryPage()),
        GoRoute(path: '/theme', builder: (_, __) => const ThemePage()),
        GoRoute(
            path: '/achievement',
            builder: (_, __) => const AchievementPage()),
        GoRoute(path: '/invite', builder: (_, __) => const InvitePage()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        GoRoute(path: '/checkin', builder: (_, __) => const CheckinPage()),
        GoRoute(path: '/stats', builder: (_, __) => const StatsPage()),
        GoRoute(path: '/favorites', builder: (_, __) => const FavoritesPage()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
        GoRoute(path: '/scene-all', builder: (_, __) => const SceneAllPage()),
        GoRoute(
          path: '/scene-detail/:sceneId',
          builder: (_, __) => const SceneDetailPage(),
        ),
        GoRoute(
          path: '/scene-edit/:sceneId',
          builder: (_, __) => const SceneEditPage(),
        ),
        // 完整播放页：从底部滑入 + 淡入（原 PlayBar 的 PageRouteBuilder 转场迁移至此）。
        GoRoute(
          path: '/player',
          pageBuilder: (_, __) => CustomTransitionPage<void>(
            key: UniqueKey(),
            transitionDuration: const Duration(milliseconds: 320),
            reverseTransitionDuration: const Duration(milliseconds: 240),
            child: const PlayerPage(),
            transitionsBuilder:
                (BuildContext _, Animation<double> anim, __, Widget child) {
              final curved =
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
              return FadeTransition(
                opacity: Tween<double>(begin: 0.6, end: 1).animate(curved),
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 1), end: Offset.zero)
                      .animate(curved),
                  child: child,
                ),
              );
            },
          ),
        ),
      ],
    );
