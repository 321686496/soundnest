// 声栖 · 新建场景页 / 声音库回归测试。
//
// 回归背景：两页的 TextField 曾因缺少 Material 祖先在打开时整页爆红
// （"No Material widget found. TextField widgets require a Material widget ancestor"）。
// 此测试经真实路由进入页面并聚焦输入框，防止该崩溃回归。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:snapp/app/app.dart';
import 'package:snapp/pages/library/library_page.dart';
import 'package:snapp/services/achievement_service.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/checkin_service.dart';
import 'package:snapp/services/custom_scene_service.dart';
import 'package:snapp/services/favorites_service.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/stats_service.dart';
import 'package:snapp/theme/app_theme.dart';
import 'package:snapp/theme/theme_extension.dart';
import 'package:snapp/theme/theme_notifier.dart';
import 'package:snapp/widgets/tab_bar.dart';

void main() {
  testWidgets('opening /scene-edit/new and typing in name field does not throw',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildRoot());
    await tester.pumpAndSettle();

    // 场景 tab → 「我的场景」右上「新建」按钮（context.push('/scene-edit/new')）。
    await tester.tap(
      find.descendant(of: find.byType(AppTabBar), matching: find.text('场景')),
    );
    await tester.pumpAndSettle();
    // 按钮在长页面底部，先滚动到可视区再点击。
    await tester.ensureVisible(find.text('新建'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建'));
    await tester.pumpAndSettle();

    // 名称输入框存在且可聚焦输入（缺 Material 祖先时会在此抛异常）。
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '雨夜阅读');
    await tester.pump();
    expect(find.text('雨夜阅读'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library search field accepts input without Material error',
      (WidgetTester tester) async {
    final colors = appColorsFor('morandi', 'flat', Brightness.light);
    await tester.pumpWidget(
      ChangeNotifierProvider<PlayerService>.value(
        value: PlayerService(engine: SimulatedAudioEngine()),
        child: MaterialApp(theme: buildAppTheme(colors), home: const LibraryPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '雨声');
    await tester.pump();
    // 输入值限定在 TextField 内断言（网格里另有名为「雨声」的声音卡片）。
    expect(
      find.descendant(of: find.byType(TextField), matching: find.text('雨声')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

/// 组装完整 Root（与 widget_test.dart 的注入一致）。
Root _buildRoot() {
  final stats = StatsService();
  final player = PlayerService(stats: stats);
  final customScenes = CustomSceneService();
  return Root(
    notifier: ThemeNotifier(),
    player: player,
    favorites: FavoritesService(),
    checkin: CheckinService(),
    customScenes: customScenes,
    stats: stats,
    achievement: AchievementService(
      player: player,
      checkin: CheckinService(),
      customScenes: customScenes,
      stats: stats,
      themeNotifier: ThemeNotifier(),
    ),
    onboarded: true,
  );
}
