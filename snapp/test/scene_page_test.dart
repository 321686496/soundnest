// 场景页 scene_page 冒烟 + 播放交互测试。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}