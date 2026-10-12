// 声栖 · 应用外壳冒烟测试。
//
// 验证 Root（外壳 + 悬浮 TabBar + go_router 路由）能在默认主题下正常 pump，且可经
// 底部 TabBar 切换 tab 页。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snapp/app/app.dart';
import 'package:snapp/theme/app_theme.dart';
import 'package:snapp/theme/theme_extension.dart';
import 'package:snapp/pages/onboarding/onboarding_page.dart';
import 'package:snapp/services/achievement_service.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/checkin_service.dart';
import 'package:snapp/services/custom_scene_service.dart';
import 'package:snapp/services/favorites_service.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';
import 'package:snapp/services/stats_service.dart';
import 'package:snapp/theme/theme_notifier.dart';
import 'package:snapp/widgets/tab_bar.dart';

void main() {
  testWidgets('Root shell renders floating tab bar with four tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildRoot());
    expect(tester.takeException(), isNull);

    expect(find.byType(AppTabBar), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppTabBar), matching: find.text('首页')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(AppTabBar), matching: find.text('场景')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(AppTabBar), matching: find.text('发现')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(AppTabBar), matching: find.text('我的')),
      findsOneWidget,
    );
  });

  testWidgets('tapping a tab bar item does not throw', (WidgetTester tester) async {
    await tester.pumpWidget(_buildRoot());

    await tester.tap(
      find.descendant(of: find.byType(AppTabBar), matching: find.text('我的')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('first launch shows onboarding, finish enters shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildRoot(onboarded: false));

    // 未引导：home 为引导页，无 TabBar
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(AppTabBar), findsNothing);

    // 「跳过」完成引导 → 切换主界面
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(AppTabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping 下一步 advances the onboarding slide',
      (WidgetTester tester) async {
    final colors = appColorsFor('morandi', 'flat', Brightness.light);
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(colors),
      home: OnboardingPage(onDone: () {}),
    ));

    expect(find.text('欢迎来到声栖'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('自由混音'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('安心入眠'), findsOneWidget);
    expect(find.text('开始体验'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sleep timer fade shows gentle badge without modal',
      (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    final root = Root(
      notifier: ThemeNotifier(),
      player: player,
      favorites: FavoritesService(),
      checkin: CheckinService(),
      customScenes: CustomSceneService(),
      stats: StatsService(),
      achievement: AchievementService(
        player: player,
        checkin: CheckinService(),
        customScenes: CustomSceneService(),
        stats: StatsService(),
        themeNotifier: ThemeNotifier(),
      ),
      onboarded: true,
    );
    await tester.pumpWidget(root);
    player.applyScene(findScene('deep-sleep')); // 有场景 → PlayBar 显示
    player.fadeMinutes = 1;
    player.setTimer(1); // fadeSeconds>=remaining → 立即进入淡出态
    await tester.pump();
    expect(find.textContaining('入眠中'), findsWidgets);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
    // 让倒计时走完以取消 pending 周期计时器，避免测试收场报错。
    await tester.pump(const Duration(seconds: 90));
    expect(tester.takeException(), isNull);
  });
}

/// 组装完整 Root（含 stats / achievement 服务，与 main.dart 注入一致）。
Root _buildRoot({bool onboarded = true}) {
  final stats = StatsService();
  final player = PlayerService(stats: stats);
  final checkin = CheckinService();
  final customScenes = CustomSceneService();
  return Root(
    notifier: ThemeNotifier(),
    player: player,
    favorites: FavoritesService(),
    checkin: checkin,
    customScenes: customScenes,
    stats: stats,
    achievement: AchievementService(
      player: player,
      checkin: checkin,
      customScenes: customScenes,
      stats: stats,
      themeNotifier: ThemeNotifier(),
    ),
    onboarded: onboarded,
  );
}