// 我的页 mine_page 回归测试：确认头像 / 周边关键元素渲染，并在默认 + 窄屏两种
// Surface 下锁定「页内负偏移（_buildProfileHero 的 Positioned 装饰出血）不触发
// EdgeInsets 断言、无 paint/render 异常」。它是全 lib 唯一含负偏移的页面。
//
// 装配用 test_root.dart 的 appRoot() 走完整 Root；再用 pushReplacement 把 Shell
// 替换为「我的」页，隔离本页，避免无关的底部 TabBar 干扰窄屏断言。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snapp/pages/mine/mine_page.dart';
import 'package:snapp/widgets/app_icon.dart';

import 'helpers/test_root.dart';

void main() {
  /// 用完整 Root 装配并推到「我的」页：先按默认尺寸渲染 Shell，再向根
  /// Navigator 推入普通页面路由（/mine 是 Shell 内 tab，不在路由表中），
  /// 使断言只覆盖本页，不受 Shell 布局影响。
  Future<void> pumpMine(WidgetTester tester) async {
    await tester.pumpWidget(appRoot());
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(navigator.push(MaterialPageRoute<void>(
        builder: (_) => const MinePage())));
    await tester.pumpAndSettle();
  }

  testWidgets('默认渲染：头像/周边关键元素齐全且无断言', (WidgetTester tester) async {
    await pumpMine(tester);

    // 头部品牌
    expect(find.text('声栖'), findsOneWidget);
    expect(find.text('我的私享声音空间'), findsOneWidget);

    // 头像 Hero 及其周边元素
    expect(find.byType(AppIcon), findsWidgets); // 头像（bird 图标）等图标已渲染
    expect(find.text('声栖用户'), findsOneWidget);
    expect(find.text('睡眠陪伴中'), findsOneWidget);
    expect(find.textContaining('已陪伴你'), findsWidgets); // 陪伴天数文字

    // 核心数据区
    expect(find.text('累计播放(分)'), findsOneWidget);
    expect(find.text('连续天数'), findsOneWidget);

    // 页内负偏移为 Positioned 装饰出血（禁断言路径）：
    // 无 EdgeInsets 断言 / 无 paint / render 异常
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏 320 渲染我的页无溢出', (WidgetTester tester) async {
    await pumpMine(tester);
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();

    // 头像 / 周边关键元素在窄屏下仍在
    expect(find.text('声栖用户'), findsOneWidget);
    expect(find.text('睡眠陪伴中'), findsOneWidget);
    expect(find.textContaining('已陪伴你'), findsWidgets);
    expect(find.byType(AppIcon), findsWidgets);

    // 无 overflow / 无渲染异常
    expect(tester.takeException(), isNull);
  });
}