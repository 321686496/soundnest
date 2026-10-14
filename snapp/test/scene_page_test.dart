// 场景页 scene_page 冒烟 + 播放交互测试。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapp/pages/scene/scene_page.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';
import 'package:snapp/widgets/app_icon.dart';
import 'package:snapp/widgets/scene_card.dart';
import 'package:snapp/widgets/tab_bar.dart';

import 'helpers/test_root.dart';

void main() {
  testWidgets('窄屏 360 逻辑宽下场景页头部无溢出', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(appRoot());
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(AppTabBar), matching: find.text('场景')));
    await tester.pumpAndSettle();
    // 头部（品牌 + 偏好 chip）在 360 宽下不得超过右边界（RenderFlex overflow）。
    expect(tester.takeException(), isNull);
  });

  testWidgets('场景页渲染分类并播放一个场景', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    await tester.pumpAndSettle();
    // 切到场景 tab
    await tester.tap(find.descendant(
        of: find.byType(AppTabBar), matching: find.text('场景')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 取全部场景首个并播放（点精选网格内该卡片的播放钮触发 onPlay，
    // 而非点卡片名——点名字走 onTap 跳到详情页，不会播放）。
    final allScenes = getCategoryScenes('all', 20);
    final name = allScenes.first.name;
    final card = find
        .ancestor(of: find.text(name), matching: find.byType(SceneCard))
        .first;
    final playBtn = find
        .descendant(
            of: card,
            matching:
                find.byWidgetPredicate((w) => w is AppIcon && w.name == 'play'))
        .first;
    // 播放钮位于视野内（y≈378，高于底部栏），直接点按触发 onPlay。
    // （命中警告可忽略：命中点落在播放钮手势区，_playScene 已被调用。）
    await tester.tap(playBtn, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(player.isPlaying, isTrue);
    expect(tester.takeException(), isNull);
    // 播放后 _playScene 触发 800ms 跳回首页定时器 + toast 1800ms 自消失定时器，
    // 前进时间触发它们，避免测试结束残留 Timer。
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('精选网格：奇数类目尾卡横排铺满，全部类目 4 张齐整', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(appRoot());
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(AppTabBar), matching: find.text('场景')));
    await tester.pumpAndSettle();

    // 「放松」类目仅 3 条：2 张网格卡 + 第 3 张横排尾卡（修复右列留白）。
    // Shell 四 tab 保活在树中，'放松' 在多个页面出现 → 只点可见可命中的 chip。
    await tester.tap(find.text('放松').hitTestable(), warnIfMissed: false);
    await tester.pumpAndSettle();
    // 精选网格限定 _FeaturedGrid（私有类）子树：全树 byType(SceneCard)
    // 会命中首页推荐/我的场景/库页等 21 张保活卡片。
    // 注意发现页也有同名私有类 _FeaturedGrid（IndexedStack 保活），
    // 必须再限定 ScenePage 子树排除它。
    final featuredGrid = find.descendant(
        of: find.byType(ScenePage),
        matching: find.byWidgetPredicate(
            (Widget w) => w.runtimeType.toString() == '_FeaturedGrid'));
    expect(featuredGrid, findsOneWidget);
    final relaxCards = tester
        .widgetList<SceneCard>(
            find.descendant(of: featuredGrid, matching: find.byType(SceneCard)))
        .toList();
    expect(relaxCards.length, 3);
    expect(relaxCards[0].isGrid, isTrue);
    expect(relaxCards[1].isGrid, isTrue);
    expect(relaxCards[2].isGrid, isFalse, reason: '奇数尾卡应为横排形态铺满整行');

    // 「全部」类目取 4 条：2×2 全网格，无孤行。
    await tester.tap(find.text('全部').hitTestable(), warnIfMissed: false);
    await tester.pumpAndSettle();
    final allCards = tester
        .widgetList<SceneCard>(
            find.descendant(of: featuredGrid, matching: find.byType(SceneCard)))
        .toList();
    expect(allCards.length, 4);
    for (final card in allCards) {
      expect(card.isGrid, isTrue);
    }
    expect(tester.takeException(), isNull);
  });
}