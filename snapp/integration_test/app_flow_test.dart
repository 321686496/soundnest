// 全链路集成测试：冷启动→首页播放→PlayBar 同步→停止。
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';
import 'package:snapp/widgets/play_bar.dart';

import '../test/helpers/test_root.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('全链路：冷启动→播放→PlayBar→停止', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    await tester.pumpAndSettle();

    // 首页一键播
    final deepName = findScene('deep-sleep').name;
    await tester.tap(find.text(deepName).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(player.currentScene?.id, 'deep-sleep');
    expect(find.byType(PlayBar), findsOneWidget);

    // 停止
    player.togglePlay();
    await tester.pump();
    expect(player.isPlaying, isFalse);
    expect(tester.takeException(), isNull);
    // 冲掉残留定时器
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}