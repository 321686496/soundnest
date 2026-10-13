// PlayBar 显隐、定时面板、播放交互测试。
import 'package:flutter_test/flutter_test.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';
import 'package:snapp/widgets/play_bar.dart';

import 'helpers/test_root.dart';

void main() {
  testWidgets('无场景时 PlayBar 不显示，应用场景后显示', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    await tester.pumpAndSettle();
    expect(find.byType(PlayBar), findsNothing);

    player.applyScene(findScene('deep-sleep'));
    await tester.pump();
    expect(find.byType(PlayBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PlayBar 定时面板可打开与关闭', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    player.applyScene(findScene('deep-sleep'));
    await tester.pump();

    expect(find.text('睡眠定时'), findsNothing);
    player.setShowTimerPanel(true);
    await tester.pump();
    expect(find.text('睡眠定时'), findsWidgets);

    player.setShowTimerPanel(false);
    await tester.pump();
    expect(find.text('睡眠定时'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PlayBar 主播放键切换播放态', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    player.applyScene(findScene('deep-sleep'));
    await tester.pump();
    expect(player.isPlaying, isTrue);

    player.togglePlay();
    await tester.pump();
    expect(player.isPlaying, isFalse);
    expect(tester.takeException(), isNull);
    // 冲掉可能残留的定时器
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}