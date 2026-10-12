import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme_extension.dart';
import 'app_icon.dart';
import 'pressable.dart';

/// 页头导航（对应原型 `components/NavBar.vue`）：
/// 返回圆钮 + 居中标题 + 右侧动作插槽。
class NavBar extends StatelessWidget {
  final String title;
  final bool back;
  final Widget? action;

  const NavBar({required this.title, this.back = true, this.action, super.key});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // 无可回退栈（深链直达等）→ 回到主壳首页。
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: back
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: PressableScale(
                      onTap: () => _goBack(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: AppIcon(name: 'chevron-left', size: 22, color: c.text),
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: c.text,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Align(alignment: Alignment.centerRight, child: action),
          ),
        ],
      ),
    );
  }
}
