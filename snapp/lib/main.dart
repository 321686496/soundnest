import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/theme_prefs.dart';
import 'services/achievement_service.dart';
import 'services/app_storage.dart';
import 'services/checkin_service.dart';
import 'services/custom_scene_service.dart';
import 'services/favorites_service.dart';
import 'services/media_bridge.dart';
import 'services/player_service.dart';
import 'services/stats_service.dart';
import 'theme/theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifier = ThemeNotifier(persist: ThemePrefs.write);
  await notifier.loadFrom(ThemePrefs.read);
  // 首启引导标记：未完成时由路由 redirect 守卫强制停留在 /onboarding，完成后写回。
  final onboarded =
      await AppStorage.getString(AppStorage.keyOnboarded) == 'true';
  // 播放服务单例：main 创建一次并恢复最近播放，Provider 以 .value 注入同一实例，
  // 避免冷启动时 Provider 另建实例导致最近播放为空（存储不可用时静默降级）。
  final stats = StatsService();
  await stats.load();
  final player = PlayerService(stats: stats);
  await player.loadRecent();
  final favorites = FavoritesService();
  await favorites.load();
  final checkin = CheckinService();
  await checkin.load();
  final customScenes = CustomSceneService();
  await customScenes.load();
  // OHOS 媒体桥：播放状态 → 通知栏播放条（AVSession）+ 桌面音乐卡片；
  // 反向接收播控命令（play/pause/next/prev）。attach 须在 loadRecent
  // 完成后（无音轨播控按最近记录恢复场景）；非 OHOS 平台桥为空转。
  MediaBridge(customScenes: customScenes).attach(player);
  final achievement = AchievementService(
    player: player,
    checkin: checkin,
    customScenes: customScenes,
    stats: stats,
    themeNotifier: notifier,
  );
  await achievement.load();
  achievement.evaluate();
  runApp(Root(
      notifier: notifier,
      player: player,
      favorites: favorites,
      checkin: checkin,
      customScenes: customScenes,
      stats: stats,
      achievement: achievement,
      onboarded: onboarded));
}
