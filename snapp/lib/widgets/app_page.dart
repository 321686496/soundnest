import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/player_service.dart';
import '../theme/theme_extension.dart';
import '../theme/theme_tokens.dart';
import '../utils/style_utils.dart';

/// 页面容器：顶部安全区 + 顶部柔和渐变（`.page-bg`，高度 440rpx）+
/// 轻微上浮/淡入进入动效（尊重系统「减弱动态效果」）。
///
/// [bottomBarSpace]：true（4 个 tab 页，悬浮 TabBar / PlayBar 叠在其上）时，
/// **外层底部内边距为 0**——滚动视口通到屏幕最底，内容全程从悬浮组件下方
/// 滑过，保持「悬浮叠层」效果；「最后一条内容不被遮挡」由滚动内容**尾部内衬**
/// 实现：页面根级滚动组件用 [AppPage.reservedBottomInset] 作内部 padding
/// （对应原型 `.page-container` 把 padding-bottom 挂在滚动内容上的做法）。
/// false（路由推入页，上方无悬浮组件）时保留固定 28 底部内边距。
class AppPage extends StatefulWidget {
  final Widget child;
  final bool bottomBarSpace;

  /// 覆盖默认内边距（默认 LTRB(20,12,20,bottom)）。
  /// 需要内容通栏（如场景详情 Hero）时传 EdgeInsets.zero 自行控制。
  final EdgeInsetsGeometry? padding;

  /// 滚动内容尾部应预留的让位高度：悬浮 TabBar（未播放）或
  /// TabBar + PlayBar（播放中）。锚点几何见 shell.dart：
  /// TabBar bottom = safeBottom*0.4 + 6，PlayBar bottom = safeBottom + kTabHeight + 8。
  ///
  /// 铁律：只能加在**滚动内容内部**（根级 SingleChildScrollView 的 `padding`），
  /// 不得加在本容器外层——外层 padding 会裁短滚动视口，内容在悬浮组件上方
  /// 被硬裁掉，永远进不了悬浮组件下方，悬浮叠层效果即失效。
  static double reservedBottomInset(BuildContext context) {
    final bool showPlayBar = context.select<PlayerService, bool>(
        (PlayerService p) => p.currentScene != null);
    final double safeBottom = MediaQuery.of(context).padding.bottom;
    return showPlayBar
        ? safeBottom + kTabHeight + kPlayBarHeight + 20.0
        : safeBottom * 0.4 + kTabHeight + 16.0;
  }

  const AppPage({
    required this.child,
    this.bottomBarSpace = false,
    this.padding,
    super.key,
  });

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: 0,
  );

  bool _reducedMotion() {
    try {
      return WidgetsBinding
          .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    } catch (_) {
      return MediaQuery.of(context).disableAnimations;
    }
  }

  @override
  void initState() {
    super.initState();
    // 延后到首帧后再启动动画：initState 阶段外层路由的 TickerMode 可能尚未激活，
    // 若在此处 forward() 且 ticker 被静音后未能恢复（部分嵌入式/OHOS 引擎），
    // 控制器会停在 0。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_reducedMotion()) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 220,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.7, 1],
                  colors: [c.bgGrad, c.bg, c.bg.withOpacity(0)],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: FadeTransition(
            // 底值 0.3：即使 ticker 卡住导致控制器停在 0，页面也已可见。
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
            child: SlideTransition(
              position: slide,
              child: Padding(
                // bottomBarSpace 页外层 bottom 归零：滚动视口通到屏幕最底，
                // 内容得以从悬浮 TabBar / PlayBar 下方滑过（悬浮叠层）。
                padding: widget.padding ??
                    EdgeInsets.fromLTRB(rx(40), rx(24), rx(40),
                        widget.bottomBarSpace ? 0.0 : 28.0),
                child: widget.child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
