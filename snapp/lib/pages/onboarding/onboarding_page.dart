import 'package:flutter/material.dart';

import '../../theme/theme_extension.dart';
import '../../utils/style_utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/pressable.dart';

/// 引导页轮播项。
class _Slide {
  final String icon;
  final String title;
  final String subtitle;
  final String iconBg;
  const _Slide(this.icon, this.title, this.subtitle, this.iconBg);
}

/// 新人引导（对照原型 `pages/onboarding/onboarding.vue`）：
/// 三页轮播（欢迎 / 混音 / 入眠）+ 指示点 + 跳过 / 下一步 / 开始体验。
///
/// [onDone]：完成回调（由路由表注入 Root 的 `_finishOnboarding`，
/// 负责写入 `shengqi-onboarded` 并放行主壳）。
class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingPage({required this.onDone, super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  static const List<_Slide> _slides = <_Slide>[
    _Slide('wave', '欢迎来到声栖', '用声音构建你的专属宁静空间',
        'linear-gradient(135deg, #8296A8, #5F7A92)'),
    _Slide('mixer', '自由混音', '混合多种声音，创造属于你的白噪音配方',
        'linear-gradient(135deg, #7E9A74, #5F7A52)'),
    _Slide('moon', '安心入眠', '定时播放，伴你温柔入梦',
        'linear-gradient(135deg, #8E82A6, #6E6290)'),
  ];

  void _goHome() {
    // 交还调用方（Root）写标记并放行主壳；redirect 守卫自动切换界面。
    widget.onDone();
  }

  void _goNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          // 顶部柔和渐变（对应 .onboarding-bg，520rpx 高）
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: 260,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.8, 1],
                    colors: [c.bgGrad, c.bg, c.bg.withOpacity(0)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (int i) =>
                        setState(() => _currentPage = i),
                    itemBuilder: (BuildContext context, int index) {
                      final slide = _slides[index];
                      final g = parseCssGradient(slide.iconBg);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: g == null
                                    ? null
                                    : LinearGradient(
                                        begin: g.begin,
                                        end: g.end,
                                        colors: g.colors),
                                color: g == null ? c.primary : null,
                                boxShadow: c.shadow3,
                              ),
                              child: Center(
                                child: AppIcon(
                                    name: slide.icon,
                                    size: 80,
                                    color: c.onCover),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(slide.title,
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: c.text)),
                            const SizedBox(height: 10),
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: c.text2),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // 指示点
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(_slides.length, (int i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: active ? 18 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: active ? c.primary : c.text3.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                // 按钮
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: _currentPage < _slides.length - 1
                      ? Row(
                          children: [
                            PressableScale(
                              onTap: _goHome,
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                alignment: Alignment.center,
                                child: Text('跳过',
                                    style: TextStyle(
                                        fontSize: 14, color: c.text2)),
                              ),
                            ),
                            const Spacer(),
                            PressableScale(
                              onTap: _goNext,
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: c.primary,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: c.shadow2,
                                ),
                                child: Text('下一步',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: c.onPrimary)),
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: PressableScale(
                            onTap: _goHome,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.primary,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: c.shadow2,
                              ),
                              child: Text('开始体验',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: c.onPrimary)),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
