// 首页 index_page 冒烟 + 交互测试。
import 'package:flutter_test/flutter_test.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';

import 'helpers/test_root.dart';

void main() {
  testWidgets('首页渲染品牌与场景分段', (WidgetTester tester) async {
    await tester.pumpWidget(appRoot());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // BrandBar 品牌名
    expect(find.text('声栖'), findsWidgets);
    // 场景分段存在
    expect(find.text('场景'), findsWidgets);
  });

  testWidgets('点击一键播 chip 应用场景并进入播放态', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    await tester.pumpAndSettle();
    // 用动态场景名避免硬编码：读取 deep-sleep 场景名
    final deepName = findScene('deep-sleep').name;
    await tester.tap(find.text(deepName).first);
    // 播放态下 PlayBar 有持续动画，不能用 pumpAndSettle（永不静止），用有界 pump。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(player.currentScene?.id, 'deep-sleep');
    expect(player.isPlaying, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首页底部 tab 可切换到我的页', (WidgetTester tester) async {
    await tester.pumpWidget(appRoot());
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}