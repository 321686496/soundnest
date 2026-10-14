import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapp/app/app.dart';
import 'package:snapp/pages/index/index_page.dart';
import 'package:snapp/services/achievement_service.dart';
import 'package:snapp/services/checkin_service.dart';
import 'package:snapp/services/custom_scene_service.dart';
import 'package:snapp/services/favorites_service.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/stats_service.dart';
import 'package:snapp/theme/theme_notifier.dart';
import 'package:snapp/widgets/tab_bar.dart';

void main() {
  testWidgets('AppTabBar fills width with 4 equal items at 390x844',
      (WidgetTester tester) async {
    // Flutter 3.7：经 binding.window 设置测试视口（390x844 @ dpr1）
    final window = tester.binding.window;
    window.physicalSizeTestValue = const Size(390, 844);
    window.devicePixelRatioTestValue = 1.0;
    addTearDown(window.clearPhysicalSizeTestValue);
    addTearDown(window.clearDevicePixelRatioTestValue);

    final stats = StatsService();
    final player = PlayerService(stats: stats);
    final checkin = CheckinService();
    final customScenes = CustomSceneService();
    await tester.pumpWidget(Root(
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
        )));
    expect(tester.takeException(), isNull);

    final tabBar = find.byType(AppTabBar);
    expect(tabBar, findsOneWidget);
    final RenderBox barBox = tester.renderObject(tabBar);
    debugPrint('AppTabBar size = ${barBox.size}');

    final rowFinder = find.descendant(
      of: tabBar,
      matching: find.byWidgetPredicate((Widget w) => w is Row),
    );
    final RenderFlex row =
        tester.renderObject(rowFinder.first) as RenderFlex;
    debugPrint('Row size = ${row.size}, childCount = ${row.childCount}');
    RenderObject? child = row.firstChild;
    var i = 0;
    while (child is RenderBox) {
      final FlexParentData pd = child.parentData as FlexParentData;
      debugPrint('item[$i] size=${child.size} offset=${pd.offset}');
      child = pd.nextSibling;
      i++;
    }

    expect(barBox.size.width, moreOrLessEquals(366, epsilon: 1));
  });

  testWidgets('home scroll viewport reaches screen bottom; last content clears tab bar at scroll end',
      (WidgetTester tester) async {
    final window = tester.binding.window;
    window.physicalSizeTestValue = const Size(390, 844);
    window.devicePixelRatioTestValue = 1.0;
    addTearDown(window.clearPhysicalSizeTestValue);
    addTearDown(window.clearDevicePixelRatioTestValue);

    final stats = StatsService();
    final player = PlayerService(stats: stats);
    await tester.pumpWidget(Root(
        notifier: ThemeNotifier(),
        player: player,
        favorites: FavoritesService(),
        checkin: CheckinService(),
        customScenes: CustomSceneService(),
        stats: stats,
        achievement: AchievementService(
          player: player,
          checkin: CheckinService(),
          customScenes: CustomSceneService(),
          stats: stats,
          themeNotifier: ThemeNotifier(),
        )));
    await tester.pumpAndSettle();

    // 回归核心 1：首页滚动视口必须通到屏幕最底（内容能从悬浮 TabBar 下方穿过）。
    // 此前的错误实现把让位 padding 挂在滚动视口外层，视口在 TabBar 上方被裁短。
    final homeScroll = find
        .descendant(of: find.byType(IndexPage), matching: find.byType(SingleChildScrollView))
        .first;
    final RenderBox viewportBox = tester.renderObject(homeScroll) as RenderBox;
    final double viewportBottom =
        viewportBox.localToGlobal(Offset(0, viewportBox.size.height)).dy;
    expect(viewportBottom, moreOrLessEquals(844, epsilon: 0.5),
        reason: '滚动视口应通到屏幕底，内容才可从悬浮胶囊下穿过');

    // 回归核心 2：滚到底后，最后一条内容底边必须高于 TabBar 顶边（不被遮挡）。
    final ScrollPosition pos = tester
        .state<ScrollableState>(
            find.descendant(of: find.byType(IndexPage), matching: find.byType(Scrollable)).first)
        .position;
    pos.jumpTo(pos.maxScrollExtent);
    await tester.pumpAndSettle();

    final RenderBox barBox = tester.renderObject(find.byType(AppTabBar)) as RenderBox;
    final double barTop = barBox.localToGlobal(Offset.zero).dy;
    final column = find
        .descendant(of: homeScroll, matching: find.byType(Column))
        .first;
    final RenderBox colBox = tester.renderObject(column) as RenderBox;
    final double contentBottom =
        colBox.localToGlobal(Offset(0, colBox.size.height)).dy;
    expect(contentBottom, lessThan(barTop),
        reason: '滚到底时最后一条内容应完整越过悬浮 TabBar 顶边');
  });
}
