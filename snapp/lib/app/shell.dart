import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/discover/discover_page.dart';
import '../pages/index/index_page.dart';
import '../pages/mine/mine_page.dart';
import '../pages/scene/scene_page.dart';
import '../services/player_service.dart';
import '../theme/theme_tokens.dart';
import '../widgets/app_toast.dart';
import '../widgets/play_bar.dart';
import '../widgets/tab_bar.dart';
import 'shell_tabs.dart';

/// 应用主壳：底部 4 tab 内容（对照原型 tabBar：首页 / 场景 / 发现 / 我的）。
///
/// 4 个 tab 经 [ShellTabNotifier]（IndexedStack 保活）切换，对应原型
/// `uni.switchTab` 语义、不走路由。有播放内容时四个 tab 全局悬浮 PlayBar
/// （覆盖在页面之上，不压缩页面高度）；点击 PlayBar 经 `/player` 路由
/// 从底部滑入完整播放页。保存行为：toast 提示。
class ShellWidget extends StatefulWidget {
  const ShellWidget({super.key});

  @override
  State<ShellWidget> createState() => _ShellWidgetState();
}

class _ShellWidgetState extends State<ShellWidget> {
  static const List<Widget> _pages = <Widget>[
    IndexPage(),
    ScenePage(),
    DiscoverPage(),
    MinePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final tabIndex = context.watch<ShellTabNotifier>().index;
    // 只订阅是否需要展示 PlayBar：避免音量拖拽 / 静音 / 睡眠定时逐秒等
    // PlayerService 的高频变更导致整棵 Shell（Stack + TabBar + PlayBar）重建。
    final showPlayBar = context.select<PlayerService, bool>(
        (PlayerService p) => p.tracks.isNotEmpty);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: tabIndex, children: _pages),
          if (showPlayBar)
            Positioned(
              left: 13,
              right: 13,
              bottom: safeBottom + kTabHeight + 8,
              child: PlayBar(
                onSaveTap: () => showAppToast(context, '可在首页保存为场景'),
              ),
            ),
          // 紧约束包裹：避免松约束下 Expanded 自适应导致 TabBar 溢出。
          // 无外部盒子的悬浮 tab：4 项图标浮于底部，内容可滚到最底不被截断。
          Positioned(
            left: 12,
            right: 12,
            bottom: safeBottom * 0.4 + 6,
            child: AppTabBar(
              currentIndex: tabIndex,
              onTap: (int i) => context.read<ShellTabNotifier>().go(i),
            ),
          ),
        ],
      ),
    );
  }
}
