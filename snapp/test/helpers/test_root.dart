// 声栖 · 测试装配公共 helper：组装完整 Root（与 main.dart 注入一致）。
import 'package:snapp/app/app.dart';
import 'package:snapp/services/achievement_service.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/checkin_service.dart';
import 'package:snapp/services/custom_scene_service.dart';
import 'package:snapp/services/favorites_service.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/stats_service.dart';
import 'package:snapp/theme/theme_notifier.dart';

/// 组装完整 Root。可注入自定义 [player]（默认 SimulatedAudioEngine）。
Root appRoot({PlayerService? player, bool onboarded = true}) {
  final stats = StatsService();
  final p = player ?? PlayerService(stats: stats, engine: SimulatedAudioEngine());
  final checkin = CheckinService();
  final customScenes = CustomSceneService();
  return Root(
    notifier: ThemeNotifier(),
    player: p,
    favorites: FavoritesService(),
    checkin: checkin,
    customScenes: customScenes,
    stats: stats,
    achievement: AchievementService(
      player: p,
      checkin: checkin,
      customScenes: customScenes,
      stats: stats,
      themeNotifier: ThemeNotifier(),
    ),
    onboarded: onboarded,
  );
}