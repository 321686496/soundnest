// 主题页 theme_page 回归测试：默认渲染合法性 + 窄屏 / 大字体下是否真实溢出。
//
// 装配用 test_root.dart 的 appRoot() 走完整 Root；再用 pushReplacement 把
// Shell 替换为主题页，隔离本页，避免无关的底部 TabBar 干扰窄屏/大字体断言。
// 复核 `_ModeDemo`（本无文本节点，不受 textScale 影响）与整页在窄屏 320 +
// textScale 2.0 下是否溢出，据此决定是否需要最小加固。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snapp/app/shell.dart';

import 'helpers/test_root.dart';

void main() {
  /// 用完整 Root 装配并推到主题页：先按默认尺寸渲染 Shell，再用 go_router
  /// 跳转替换为主题页，使断言只覆盖主题页，不受 Shell 布局影响。
  Future<void> pumpTheme(WidgetTester tester) async {
    await tester.pumpWidget(appRoot());
    await tester.pumpAndSettle();
    tester.element(find.byType(ShellWidget)).go('/theme');
    await tester.pumpAndSettle();
  }

  testWidgets('默认渲染：三分区标题 + NavBar 标题存在且无异常', (WidgetTester tester) async {
    await pumpTheme(tester);

    // NavBar 标题
    expect(find.text('主题与风格'), findsOneWidget);
    // 三个分区标题
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('配色方案'), findsOneWidget);
    expect(find.text('UI 风格'), findsOneWidget);

    // 无 overflow / 无渲染异常
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏 320 + textScale 2.0 渲染主题页无溢出', (WidgetTester tester) async {
    await pumpTheme(tester);
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.binding.platformDispatcher.clearAllTestValues);
    await tester.pumpAndSettle();

    // 三个分区标题仍在
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('配色方案'), findsOneWidget);
    expect(find.text('UI 风格'), findsOneWidget);

    // 无 overflow / 无渲染异常
    expect(tester.takeException(), isNull);
  });
}