import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme_extension.dart';
import 'app_icon.dart';
import 'pressable.dart';

/// 首页品牌头（对应原型 `components/BrandBar.vue`）：
/// logo 图 +「声栖」+ 按时段问候 + 主题 / 成就入口。
class BrandBar extends StatelessWidget {
  const BrandBar({super.key});

  static String greetingOf(DateTime now) {
    final h = now.hour;
    if (h < 5) return '夜深了，愿你好眠';
    if (h < 11) return '早上好';
    if (h < 13) return '中午好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            'assets/brand/logo.jpg',
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('声栖',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: c.text)),
              const SizedBox(height: 2),
              Text(greetingOf(DateTime.now()),
                  style: TextStyle(fontSize: 12, color: c.text2)),
            ],
          ),
        ),
        _BrandBtn(
          onTap: () => context.push('/theme'),
          child: AppIcon(name: 'palette', size: 20, color: c.text2),
        ),
        const SizedBox(width: 4),
        _BrandBtn(
          onTap: () => context.push('/achievement'),
          child: AppIcon(name: 'award', size: 20, color: c.text2),
        ),
      ],
    );
  }
}

class _BrandBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _BrandBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.surface,
          shape: BoxShape.circle,
          border: c.line.opacity > 0.01
              ? Border.all(color: c.line, width: 0.5)
              : null,
          boxShadow: Theme.of(context).appColors.shadow1,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
