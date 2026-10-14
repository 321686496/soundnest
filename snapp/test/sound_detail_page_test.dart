// 声栖 · 声音详情页测试：渲染 / 试听 / 加入混音与已加入态。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:snapp/pages/sound-detail/sound_detail_page.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/theme/app_theme.dart';
import 'package:snapp/theme/theme_extension.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, PlayerService player) async {
    // 页面内容（Hero + 规格 + 标签）高于默认 600 逻辑高测试面，操作行落在
    // 视口外（y≈650+）：按仓库惯例放大到 iPhone 尺寸再 pump
    // （scene_page_test.dart 同款），否则 tester.tap 点不中按钮。
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: '/sound/rain',
      routes: <RouteBase>[
        GoRoute(
          path: '/sound/:soundId',
          builder: (_, __) => const SoundDetailPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<PlayerService>.value(
        value: player,
        child: MaterialApp.router(
          theme: buildAppTheme(appColorsFor('morandi', 'flat', Brightness.light)),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders hero, spec rows and scene tags', (WidgetTester tester) async {
    await pumpPage(tester, PlayerService(engine: SimulatedAudioEngine()));

    expect(find.text('声音详情'), findsOneWidget);
    expect(find.text('雨声'), findsOneWidget);
    expect(find.text('自然音'), findsOneWidget);
    expect(find.text('规格参数'), findsOneWidget);
    expect(find.text('时长'), findsOneWidget);
    expect(find.text('60:00'), findsOneWidget);
    expect(find.text('48kHz'), findsOneWidget);
    expect(find.text('无损'), findsOneWidget);
    expect(find.text('实地录音 · 江南雨巷屋檐'), findsOneWidget);
    expect(find.text('适用场景'), findsOneWidget);
    expect(find.text('助眠'), findsOneWidget);
    expect(find.text('试听'), findsOneWidget);
    expect(find.text('加入混音'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap 试听 rebuilds single track via playSound', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await pumpPage(tester, player);

    await tester.tap(find.text('试听'));
    await tester.pump();
    expect(player.tracks.length, 1);
    expect(player.tracks.first.id, 'rain');
    expect(player.currentScene, isNull);
    expect(player.isPlaying, isTrue);
    // 冲掉试听 toast 的定时器链（1800ms 自消失 + 220ms 移除回调），
    // 避免测试结束残留 Timer（scene_page_test.dart 同款处理）。
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('加入混音 succeeds then shows joined state', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await pumpPage(tester, player);

    await tester.tap(find.text('加入混音'));
    await tester.pumpAndSettle();
    expect(player.tracks.map((t) => t.id), contains('rain'));
    expect(find.text('已在混音中'), findsOneWidget);
    expect(find.text('加入混音'), findsNothing);
    // 冲掉「已加入混音」toast 的 1800ms 自消失定时器（同上）。
    await tester.pump(const Duration(seconds: 2));
  });
}
