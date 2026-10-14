// 播放页 player_page 回归测试：均衡器/呼吸封面引入后锁定
// 「播放态渲染无异常 + 播控切换（播放↔暂停）过渡无异常」。
//
// 装配用 test_root.dart 的 appRoot() 走完整 Root（提供 PlayerService/
// FavoritesService），applyScene 预置播放场景后经根 Navigator 推入
// PlayerPage 隔离本页。
//
// 注意：播放态下均衡器与封面呼吸均为无限动画，全程用 pump(固定时长)
// 而非 pumpAndSettle，否则 settle 永不结束导致超时。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:snapp/pages/player/player_page.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/favorites_service.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';
import 'package:snapp/widgets/app_icon.dart';

import 'helpers/test_root.dart';

void main() {
  /// 预置播放态并经 `/player` 路由直接落到播放页。
  ///
  /// [audition] 为 true 时走 `playSound` 单曲试听预置（currentScene 置 null，
  /// 页面展示合成 `sound-*` 场景）；默认 `applyScene(ocean-sleep)`，
  /// applyScene 即开始播放。
  ///
  /// 用 initialLocation 走 go_router 正规路由（手动 push 会被初始路由
  /// restore 冲掉）；pump 固定时长越过路由过渡——播放态下均衡器/封面
  /// 呼吸为无限动画，全程不可 pumpAndSettle。
  ///
  /// Shell 四个 tab 保活在树中，find 必须限定 PlayerPage 子树，
  /// 否则会命中 PlayBar/首页卡上的同名图标与文本。
  Future<void> pumpPlayer(WidgetTester tester, PlayerService player,
      {bool audition = false}) async {
    if (audition) {
      player.playSound(player.findSound('rain')!);
    } else {
      player.applyScene(findScene('ocean-sleep')); // applyScene 即开始播放
    }
    await tester.pumpWidget(appRoot(player: player, initialLocation: '/player'));
    await tester.pump();
    // 900ms 越过 300ms 路由转场 + AppPage 入场动效（约 450ms 上浮淡入，
    // 期间 hit test 被 AbsorbPointer 吸收，tap 会打空）。
    await tester.pump(const Duration(milliseconds: 900));
  }

  Finder inPlayer(Finder child) =>
      find.descendant(of: find.byType(PlayerPage), matching: child);

  testWidgets('播放态渲染：均衡器/标题/混音区齐全且无渲染异常',
      (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await pumpPlayer(tester, player);

    expect(inPlayer(find.text('正在播放')), findsOneWidget);
    expect(inPlayer(find.text('海浪催眠')), findsOneWidget);
    expect(inPlayer(find.text('当前混音')), findsOneWidget);
    expect(inPlayer(find.text('添加声音')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('播放↔暂停切换：图标切换与均衡器/呼吸回落无异常',
      (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await pumpPlayer(tester, player);

    // 播放态显示暂停图标；经服务层切到暂停后断言图标/回落渲染。
    // （tap 主控钮在 600 高默认 surface 上被滚动视口裁剪，手势命中脆弱；
    // 手势本身由 PressableScale 通用组件承载，此处锁定切换后的渲染无异常。）
    final pauseIcon = inPlayer(
        find.byWidgetPredicate((w) => w is AppIcon && w.name == 'pause'));
    expect(pauseIcon, findsOneWidget);
    player.togglePlay();
    // 越过图标切换 240ms + 均衡器/封面回落 600ms。
    await tester.pump(const Duration(milliseconds: 800));
    expect(player.isPlaying, isFalse);
    expect(
        inPlayer(find.byWidgetPredicate((w) => w is AppIcon && w.name == 'play')),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    // 收尾卸载：取消 _ProgressSection 的 100ms 周期 Timer，避免 pending timer。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('试听态收藏：不写合成 sound-* 脏 id，提示「试听暂不支持收藏」',
      (WidgetTester tester) async {
    // 内容高于 600 默认测试面：按仓库惯例放大到 iPhone 尺寸再 pump
    // （sound_detail_page_test.dart 同款），否则收藏按钮落在视口外点不中。
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final player = PlayerService(engine: SimulatedAudioEngine());
    await pumpPlayer(tester, player, audition: true);

    // 试听态：currentScene 为 null，页面展示的是合成展示场景（id 前缀 sound-）。
    expect(player.currentScene, isNull);
    expect(player.displayScene!.id, 'sound-rain');

    // 收藏服务实例取自 appRoot 注入的 provider。
    final fav =
        tester.element(find.byType(PlayerPage)).read<FavoritesService>();
    expect(fav.ids, isEmpty);

    final heart = inPlayer(
        find.byWidgetPredicate((w) => w is AppIcon && w.name == 'heart'));
    expect(heart, findsOneWidget);
    await tester.ensureVisible(heart);
    await tester.tap(heart);
    await tester.pump(); // overlay 下一帧构建 toast

    // 核心断言：合成展示 id 未被写入收藏（修复前会持久化 'sound-rain'）。
    expect(fav.ids, isEmpty);
    expect(fav.isFav('sound-rain'), isFalse);
    expect(find.text('试听暂不支持收藏'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 冲掉 toast 定时器链（1800ms 自消失 + 220ms 移除回调），避免残留 Timer
    // （sound_detail_page_test.dart 同款处理）。
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('试听暂不支持收藏'), findsNothing);

    // 收尾卸载：取消 _ProgressSection 的 100ms 周期 Timer，避免 pending timer。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
