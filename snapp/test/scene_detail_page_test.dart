// 声栖 · 场景详情页测试：配方条目点击跳转声音详情（场景↔声音闭环）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:snapp/pages/scene-detail/scene_detail_page.dart';
import 'package:snapp/pages/sound-detail/sound_detail_page.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/favorites_service.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';
import 'package:snapp/theme/app_theme.dart';
import 'package:snapp/theme/theme_extension.dart';

void main() {
  testWidgets('配方条目点击跳转 /sound/:id', (WidgetTester tester) async {
    // 配方行在默认 800×600 视口外（y≈634）：按仓库惯例放大到 iPhone 尺寸
    // 再 pump（scene_page_test.dart / sound_detail_page_test.dart 同款），
    // 否则 tester.tap 点不中配方行。
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final player = PlayerService(engine: SimulatedAudioEngine());
    final router = GoRouter(
      initialLocation: '/scene-detail/deep-sleep',
      routes: <RouteBase>[
        GoRoute(
          path: '/scene-detail/:sceneId',
          builder: (_, __) => const SceneDetailPage(),
        ),
        GoRoute(
          path: '/sound/:soundId',
          builder: (_, __) => const SoundDetailPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlayerService>.value(value: player),
          ChangeNotifierProvider<FavoritesService>.value(value: FavoritesService()),
        ],
        child: MaterialApp.router(
          theme: buildAppTheme(appColorsFor('morandi', 'flat', Brightness.light)),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // buildRecipe 首项 = soundIds[0]，配方行文本为声音名。
    final scene = findScene('deep-sleep');
    final firstName = player.findSound(scene.soundIds.first)!.name;
    await tester.tap(find.text(firstName));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.location,
      startsWith('/sound/'),
    );
  });
}
