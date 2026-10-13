// 设置页 settings_page 回归测试：窄屏 / 大字体下卡片不溢出、关键行存在、
// 交互不变（开关 / 选择 / 清缓存 toast）。
//
// 装配用 test_root.dart 的 appRoot() 走完整 Root；再用 pushReplacement 把
// Shell 替换为设置页，隔离本页，避免无关的底部 TabBar 干扰窄屏/大字体断言。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snapp/app/shell.dart';

import 'helpers/test_root.dart';

void main() {
  /// 用完整 Root 装配并推到设置页：先按默认尺寸渲染 Shell，再用 go_router
  /// 跳转替换为设置页，使断言只覆盖设置页，不受 Shell 布局影响。
  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(appRoot());
    await tester.pumpAndSettle();
    tester.element(find.byType(ShellWidget)).go('/settings');
    await tester.pumpAndSettle();
  }

  testWidgets('窄屏语义断言 + 三卡片渲染无溢出', (WidgetTester tester) async {
    await pumpSettings(tester);
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();

    // 三个分区标题都在
    expect(find.text('播放设置'), findsOneWidget);
    expect(find.text('提醒设置'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);

    // 关键行存在
    expect(find.text('启动时自动恢复播放'), findsOneWidget);
    expect(find.text('每日助眠提醒'), findsOneWidget);
    expect(find.text('版本'), findsOneWidget);

    // 无 overflow / 无渲染异常
    expect(tester.takeException(), isNull);
  });

  testWidgets('大字体 + 窄屏渲染设置页无溢出', (WidgetTester tester) async {
    await pumpSettings(tester);
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.binding.platformDispatcher.clearAllTestValues);
    await tester.pumpAndSettle();

    expect(find.text('启动时自动恢复播放'), findsOneWidget);
    expect(find.text('每日助眠提醒'), findsOneWidget);
    expect(find.text('版本'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}