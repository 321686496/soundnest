import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/player_service.dart';
import '../theme/theme_extension.dart';
import 'app_toast.dart';
import 'app_card.dart';
import 'app_icon.dart';
import 'pressable.dart';

/// 底部悬浮主控条（对应原型 `components/PlayBar.vue`）。
///
/// 由外层 Shell 定位在 TabBar 之上；含睡眠定时面板与混音面板（互斥弹出）。
class PlayBar extends StatelessWidget {
  final VoidCallback? onSaveTap;

  const PlayBar({this.onSaveTap, super.key});

  @override
  Widget build(BuildContext context) {
    // 顶层只订阅定时面板显隐；播放器其余通知（每秒倒计时等）不连坐重建
    // 下方 PlayBar 主体。
    final showTimerPanel = context.select<PlayerService, bool>(
        (PlayerService p) => p.showTimerPanel);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTimerPanel) const _TimerPanel(),
        const SizedBox(height: 8),
        _PlayBarInner(onSaveTap: onSaveTap),
      ],
    );
  }
}

class _PlayBarInner extends StatelessWidget {
  final VoidCallback? onSaveTap;
  const _PlayBarInner({this.onSaveTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    // 各自只订阅本块真正展示的字段；音量/静音/每秒倒计时不重建 PlayBar 主体。
    final isPlaying = context.select<PlayerService, bool>(
        (PlayerService p) => p.isPlaying);
    final sceneName = context.select<PlayerService, String?>(
        (PlayerService p) => p.currentScene?.name);
    final isLocked = context.select<PlayerService, bool>(
        (PlayerService p) => p.isLocked);
    final hasTimer = context.select<PlayerService, bool>(
        (PlayerService p) => p.timerMinutes > 0);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // 点击封面/标题区 → 从底部滑入打开完整播放页（转场见路由表 /player）。
                onTap: () => context.push('/player'),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.sunken,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset('assets/brand/logo.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Center(child: AppIcon(name: 'wave', size: 18, color: c.text3))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PlayBars(playing: isPlaying),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  sceneName ?? '未选择场景',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.15,
                                    color: c.text,
                                  ),
                                ),
                              ),
                              // 剩余秒标签独立成 widget，每秒倒计时只重建它。
                              const _TimerChip(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BarAction(
              active: isLocked,
              icon: AppIcon(
                  name: 'lock',
                  size: 20,
                  color: isLocked ? c.primary : c.text3),
              onTap: () {
                final player = context.read<PlayerService>();
                player.toggleLock();
                showAppToast(context, player.isLocked ? '已锁定播放' : '已解锁');
              },
            ),
            _BarAction(
              active: hasTimer,
              icon: AppIcon(
                  name: 'timer',
                  size: 20,
                  color: hasTimer ? c.primary : c.text3),
              onTap: () {
                final player = context.read<PlayerService>();
                player.setShowTimerPanel(!player.showTimerPanel);
              },
            ),
            const _MainPlayButton(),
            _BarAction(
              icon: AppIcon(name: 'save', size: 20, color: c.text3),
              onTap: onSaveTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final bool active;
  const _BarAction({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? c.primarySoft : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}

class _MainPlayButton extends StatelessWidget {
  const _MainPlayButton();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    // 仅订阅播放态；其余播放器通知不重建此按钮。
    final isPlaying = context.select<PlayerService, bool>(
        (PlayerService p) => p.isPlaying);
    return PressableScale(
      onTap: () {
        if (!context.read<PlayerService>().togglePlay()) {
          showAppToast(context, '请先选择场景');
        }
      },
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[c.primary, c.primaryStrong],
          ),
          boxShadow: c.shadow2,
        ),
        alignment: Alignment.center,
        child: AppIcon(
            name: isPlaying ? 'pause' : 'play',
            size: 30,
            color: c.onPrimary),
      ),
    );
  }
}

/// 剩余秒 / 定时标签 chip：独立订阅 `timerLabel`，睡眠定时每秒倒计时时
/// 仅此 chip 重建，避免连坐整条 PlayBar 主体。标签为空（未启用定时）时隐藏。
class _TimerChip extends StatelessWidget {
  const _TimerChip();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final label = context.select<PlayerService, String>(
        (PlayerService p) => p.timerLabel);
    final fading = context.select<PlayerService, bool>(
        (PlayerService p) => p.fading);
    if (label.isEmpty) return const SizedBox.shrink();
    return AnimatedContainer(
      margin: const EdgeInsets.only(left: 5),
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: fading ? c.surface2 : c.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 400),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fading ? c.text2 : c.primary),
        child: Text(fading ? '$label · 入眠中' : label),
      ),
    );
  }
}

/// 播放中的 4 根跳动摇杆（原型 `.play-bars`）。
class _PlayBars extends StatefulWidget {
  final bool playing;
  const _PlayBars({required this.playing});

  @override
  State<_PlayBars> createState() => _PlayBarsState();
}

class _PlayBarsState extends State<_PlayBars> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  // 原型静态高度：10 / 20 / 14 / 17（rpx→px 减半后 5 / 10 / 7 / 8.5）
  static const List<double> _heights = <double>[5, 10, 7, 8.5];

  @override
  void initState() {
    super.initState();
    _update(widget.playing);
  }

  @override
  void didUpdateWidget(_PlayBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) _update(widget.playing);
  }

  void _update(bool playing) {
    if (playing) {
      _ctrl.repeat();
    } else {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return RepaintBoundary(
      child: SizedBox(
        height: 12,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List<Widget>.generate(_heights.length, (int i) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (BuildContext context, _) {
                final t = widget.playing
                    ? 0.5 + 0.5 * _wave(_ctrl.value * 2 + i * 0.2)
                    : 1.0;
                return Container(
                  width: 2.5,
                  height: (_heights[i] * (widget.playing ? t : 1)).clamp(2.0, 12.0),
                  margin: const EdgeInsets.only(right: 2.5),
                  decoration: BoxDecoration(
                    color: widget.playing ? c.primary : c.text3,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  double _wave(double x) {
    final v = (x % 1.0) * 2;
    return v <= 1 ? v : 2 - v;
  }
}

/// 睡眠定时面板（对应原型 `.timer-panel`）。
class _TimerPanel extends StatelessWidget {
  const _TimerPanel();

  static const List<int> _options = <int>[15, 30, 45, 60, 90];
  static const List<int> _fades = <int>[1, 2, 3, 5];

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    // 只订阅定时分钟 / 渐弱分钟；其余通知不重建面板。
    final timerMinutes = context.select<PlayerService, int>(
        (PlayerService p) => p.timerMinutes);
    final fadeMinutes = context.select<PlayerService, int>(
        (PlayerService p) => p.fadeMinutes);
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: '睡眠定时'),
          const SizedBox(height: 10),
          Row(
            children: _options.map((int m) {
              final on = timerMinutes == m;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.read<PlayerService>().setTimer(m),
                  child: Container(
                    height: 44,
                    margin: EdgeInsets.only(
                        right: m == _options.last ? 0 : 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? c.primary : c.surface2,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: on ? c.shadow1 : null,
                    ),
                    child: Text('$m分钟',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: on ? c.onPrimary : c.text)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('渐弱时长', style: TextStyle(fontSize: 12, color: c.text2)),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: _fades.map((int f) {
                    final on = fadeMinutes == f;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            context.read<PlayerService>().setFadeMinutes(f),
                        child: Container(
                          height: 32,
                          margin: EdgeInsets.only(
                              right: f == _fades.last ? 0 : 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: on ? c.primarySoft : c.surface2,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('$f分钟',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      on ? FontWeight.w600 : FontWeight.w500,
                                  color: on ? c.primary : c.text2)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

///
/// 定时面板头（标题 + 关闭）。
class _PanelHeader extends StatelessWidget {
  final String title;
  const _PanelHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
        ),
        GestureDetector(
          onTap: () {
            final player = context.read<PlayerService>();
            player.setShowTimerPanel(false);
            player.setShowMixPanel(false);
          },
          child: Transform.translate(
            // 原负 margin 会被 Container 断言拒绝，改用平移复刻「贴右缘」观感
            offset: const Offset(14, 0),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: AppIcon(name: 'close', size: 16, color: c.text3),
            ),
          ),
        ),
      ],
    );
  }
}

/// 面板统一容器：浮层卡片 + panelIn 进入动效。
class _PanelCard extends StatelessWidget {
  final Widget child;
  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (BuildContext context, double v, Widget? w) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 6 * (1 - v)), child: w),
      ),
      child: AppCard(padding: const EdgeInsets.all(12), child: child),
    );
  }
}
