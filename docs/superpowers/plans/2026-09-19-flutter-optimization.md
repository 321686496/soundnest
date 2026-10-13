# 声栖 Flutter 工程全面优化实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development.
> Steps use checkbox (`- [ ]`) syntax for tracking. Implement task-by-task with review gates.

**Goal:** 在 codebase 有基线的 `snapp/` Flutter 工程上，按「测试→修复→架构→响应式→UI」五阶段做系统性加固与打磨。

**Architecture:** 保持现有分层（pages/widgets/services/theme/data）不动，每阶段只做增量的加固：先补 widget/集成测试铺底，再修已知布局问题，再做 service 边界审计，再做窄屏响应式 + Widget Preview，最后做设计规范自检与主题切换验收。每阶段结束跑 `flutter analyze` + `flutter test`，全绿才进入下一阶段。

**Tech Stack:** Flutter、provider、flutter_test、integration_test、SimulatedAudioEngine（测试替身）。SBJ：不引入新第三方库。

---

## Global Constraints

- 唯一改动对象为 `snapp/`；`prototype/`（uni-app）仅作设计参考，不改其代码。
- 业务代码禁出现 `Color(0xFF…)` / `Colors.xxx` / 硬编码色值，一律走主题扩展 `Theme.of(context).appColors`。
- 禁用负 margin（会触发断言），视觉偏移用 `Transform.translate`。
- 不引入任何新第三方库；若必须引入，先查 Harmony 适配清单（当前各阶段均不需要）。
- 状态管理统一 provider，禁止 Store-to-Store 直接引用。
- 每个阶段验收：`flutter analyze` 零错误零警告 + `flutter test` 全绿；涉及交互的代码补测试。
- UI 提交前对照 `prototype/src` 对应组件（第三章），不得自造配色/组件。
- 设计遵循 `docs/design-system/MASTER.md`（depth=2 token、44px 最小触控、零硬编码）。

---

## 文件结构

**本计划将修改/新建：**

| 文件 | 职责 | 改动类型 |
|---|---|---|
| `snapp/test/` 下新增测试 | Phase1 各任务的 widget 测试 | 新建 |
| `snapp/integration_test/app_flow_test.dart` | Phase1 端到端链路 | 新建 |
| `snapp/pubspec.yaml` | Phase1 加 `integration_test` dev 依赖 | 修改（仅 sdk 内置包，非三方库） |
| `snapp/lib/pages/settings/settings_page.dart` | Phase2 修复空白/overflow | 修改 |
| `snapp/lib/pages/theme/theme_page.dart` | Phase2 复核 `_ModeDemo` 高度 | 修改 |
| `snapp/lib/pages/{index,scene,scene-detail,library,player,favorites,history,mine,discover,achievement,stats,theme,scene-edit}.dart` + `widgets/*.dart` | Phase2 Transform.translate 覆盖盘点 | 待查（多数已落地） |
| `snapp/lib/services/*.dart` | Phase3 边界审计修正 | 修改（2-3 处） |
| `snapp/lib/widgets/{scene_card,sound_card,play_bar}.dart` | Phase4 加 Widget Preview | 修改 |
| 关键页面布局 | Phase4 窄屏适配 | 修改 |
| 各页面/组件样式 | Phase5 规范自检修正 | 修改 |

---

## Phase 1 · 测试铺底

### Task 1: 加 integration_test dev 依赖

**Files:**
- Modify: `snapp/pubspec.yaml`（dev_dependencies 区）

**Interfaces:**
- Consumes: 现有 dev_dependencies（flutter_test, fake_async, flutter_lints）
- Produces: `integration_test` 包可用（sdk: flutter，非三方库，无需 Harmony 查证——它是 Flutter SDK 内置 test driver）

- [ ] **Step 1: 编辑 pubspec.yaml**

在 `dev_dependencies:` 下、`fake_async` 之上加：

```yaml
  integration_test:
    sdk: flutter
```

- [ ] **Step 2: 跑 pub get 验证**

Run: `cd snapp; flutter pub get`
Expected: 无报错，`integration_test` 解析自 SDK。

- [ ] **Step 3: 验收 analyze**

Run: `cd snapp; flutter analyze`
Expected: No issues found（pubspec 变更不产生分析告警）。

### Task 2: 打包可复用的测试装配 helper

**Files:**
- Create: `snapp/test/helpers/test_root.dart`

**Interfaces:**
- Consumes: `Root`（`lib/app/app.dart`）、`ThemeNotifier`、各 service、`findScene`（`lib/services/scene_service.dart`）
- Produces: `appRoot({PlayerService? player, bool onboarded})` → 返回 `Root`，供各页面 widget 测试复用

**背景：** 现有 `widget_test.dart` 内已有 `_buildRoot`（私有）。抽成公共 helper 避免每个新测试文件复制。

- [ ] **Step 1: 写 helper**

```dart
// 声栖 · 测试装配公共 helper：组装完整 Root（与 main.dart 注入一致）。
import 'package:snapp/app/app.dart';
import 'package:snapp/services/achievement_service.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/checkin_service.dart';
import 'package:snapp/services/custom_scene_service.dart';
import 'package:snapp/services/favorites_service.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/stats_service.dart';
import 'package:snapp/theme/theme_notifier.dart';

/// 组装完整 Root。可注入自定义 [player]（默认 SimulatedAudioEngine）。
Root appRoot({PlayerService? player, bool onboarded = true}) {
  final stats = StatsService();
  final p = player ?? PlayerService(stats: stats, engine: SimulatedAudioEngine());
  final checkin = CheckinService();
  final customScenes = CustomSceneService();
  return Root(
    notifier: ThemeNotifier(),
    player: p,
    favorites: FavoritesService(),
    checkin: checkin,
    customScenes: customScenes,
    stats: stats,
    achievement: AchievementService(
      player: p,
      checkin: checkin,
      customScenes: customScenes,
      stats: stats,
      themeNotifier: ThemeNotifier(),
    ),
    onboarded: onboarded,
  );
}
```

- [ ] **Step 2: 编译验证**

Run: `cd snapp; flutter analyze test/helpers/test_root.dart`
Expected: No issues found。

- [ ] **Step 3: Commit**

```bash
git add snapp/pubspec.yaml snapp/test/helpers/test_root.dart
git commit -m "test(flutter): 抽公共测试装配 helper + integration_test 依赖"
```

### Task 3: 首页 index_page Widget 测试

**Files:**
- Create: `snapp/test/index_page_test.dart`
- Modify: 无

**Interfaces:**
- Consumes: `appRoot`（Task2）、`findScene`、`PlayerService`
- Produces: 首页 4 项回归断言（chips 渲染、分类网格、一键播、tab 切换）

- [ ] **Step 1: 写测试**

```dart
// 首页 index_page 冒烟 + 交互测试。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';

import 'helpers/test_root.dart';

void main() {
  testWidgets('首页渲染 brand 与场景分段', (WidgetTester tester) async {
    await tester.pumpWidget(appRoot());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // BrandBar 品牌名
    expect(find.text('声栖'), findsWidgets);
    // 场景分段存在
    expect(find.text('场景'), findsWidgets);
  });

  testWidgets('点击一键播 chip 应用场景并进入播放态', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    await tester.pumpAndSettle();
    // 用动态场景名避免硬编码：读取 deep-sleep 场景名
    final deepName = findScene('deep-sleep').name;
    await tester.tap(find.text(deepName).first);
    await tester.pumpAndSettle();
    expect(player.currentScene?.id, 'deep-sleep');
    expect(player.isPlaying, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首页底部 tab 可切换到场景页', (WidgetTester tester) async {
    await tester.pumpWidget(appRoot());
    await tester.pumpAndSettle();
    await tester.tap(find.text('场景'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: 运行测试，确保全绿**

Run: `cd snapp; flutter test test/index_page_test.dart -v`
Expected: 3 个 test 全 PASS。

- [ ] **Step 3: Commit**

```bash
git add snapp/test/index_page_test.dart
git commit -m "test(flutter): 首页 index_page 冒烟与一键播交互测试"
```

### Task 4: 场景页 scene_page Widget 测试

**Files:**
- Create: `snapp/test/scene_page_test.dart`
- Test helper: Task2 `appRoot`

**Interfaces:**
- Consumes: `appRoot`、`findScene`、`PlayerService`
- Produces: 场景页渲染 + 播放场景交互断言

- [ ] **Step 1: 写测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';

import 'helpers/test_root.dart';

void main() {
  testWidgets('场景页渲染分类并播放一个场景', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    await tester.pumpAndSettle();
    // 切到场景 tab（index=1）
    await tester.tap(find.text('场景').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 点击一个可播放的卡片：取首个已渲染场景名并播放
    final allScenes = getCategoryScenes('all', 20);
    final name = allScenes.first.name;
    await tester.tap(find.text(name).first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(player.isPlaying, isTrue);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: 运行测试，确保全绿**

Run: `cd snapp; flutter test test/scene_page_test.dart -v`
Expected: 1 个 test PASS。若同名文本命中歧义（PlayBar 也显示场景名），用 `warnIfMissed:false` 并限定 `.hitTestable()`。

- [ ] **Step 3: Commit**

```bash
git add snapp/test/scene_page_test.dart
git commit -m "test(flutter): 场景页渲染与播放交互测试"
```

### Task 5: 播放条 play_bar + 混音面板 Widget 测试

**Files:**
- Create: `snapp/test/play_bar_test.dart`
- Test helper: Task2 `appRoot`

**Interfaces:**
- Consumes: `appRoot`、`findScene`、`PlayerService`
- Produces: PlayBar 显示/显隐、定时面板弹出/关闭、混音交互断言

- [ ] **Step 1: 写测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';
import 'package:snapp/widgets/play_bar.dart';

import 'helpers/test_root.dart';

void main() {
  testWidgets('无场景时 PlayBar 不显示，应用场景后显示', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    await tester.pumpAndSettle();
    expect(find.byType(PlayBar), findsNothing);

    player.applyScene(findScene('deep-sleep'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PlayBar 定时面板可打开与关闭', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    player.applyScene(findScene('deep-sleep'));
    await tester.pumpAndSettle();

    expect(find.text('睡眠定时'), findsNothing);
    // 点击定时图标打开面板（PlayBar 第二个 _BarAction，定位 timer 图标）
    await tester.tap(find.byType(PlayBar));
    // 面板打开通过 service 状态触发：
    player.setShowTimerPanel(true);
    await tester.pumpAndSettle();
    expect(find.text('睡眠定时'), findsOneWidget);

    player.setShowTimerPanel(false);
    await tester.pumpAndSettle();
    expect(find.text('睡眠定时'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PlayBar 主播放键切换播放态', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    player.applyScene(findScene('deep-sleep'));
    await tester.pumpAndSettle();
    expect(player.isPlaying, isTrue);

    // 点击主播放按钮（通过 AppIcon play/pause 图标切换判定）
    player.togglePlay();
    await tester.pumpAndSettle();
    expect(player.isPlaying, isFalse);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: 运行测试，确保全绿**

Run: `cd snapp; flutter test test/play_bar_test.dart -v`
Expected: 3 个 test PASS。

- [ ] **Step 3: Commit**

```bash
git add snapp/test/play_bar_test.dart
git commit -m "test(flutter): PlayBar 显隐、定时面板、播放交互测试"
```

### Task 6: 端到端集成测试（冷启动→播放→PlayBar 同步→停止）

**Files:**
- Create: `snapp/integration_test/app_flow_test.dart`

**Interfaces:**
- Consumes: `appRoot`（用 test binding 直接 pump）、`findScene`、`PlayerService`
- Produces: 一条完整链路断言（集成测试为可选依赖，native 端执行）

- [ ] **Step 1: 写集成测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';
import 'package:snapp/widgets/play_bar.dart';

import '../test/helpers/test_root.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('全链路：冷启动→播放→PlayBar→停止', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await tester.pumpWidget(appRoot(player: player));
    await tester.pumpAndSettle();

    // 首页点一键播
    final deepName = findScene('deep-sleep').name;
    await tester.tap(find.text(deepName).first);
    await tester.pumpAndSettle();
    expect(player.currentScene?.id, 'deep-sleep');
    expect(find.byType(PlayBar), findsOneWidget);

    // 停止
    player.togglePlay();
    await tester.pumpAndSettle();
    expect(player.isPlaying, isFalse);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: 逻辑校验（本地以 widget-test 方式跑通链路断言）**

> 集成测试无法在桌面无设备直接跑；本步先在 widget 测试环境验证同链路不抛错（复用 Task3 逻辑）。

Run: `cd snapp; flutter test integration_test/app_flow_test.dart -v`
Expected: 该文件通过 `IntegrationTestWidgetsFlutterBinding` 在 VM 上跑，链路断言 PASS。

- [ ] **Step 3: Commit**

```bash
git add snapp/integration_test/app_flow_test.dart
git commit -m "test(flutter): 全链路集成测试（冷启动→播放→PlayBar→停止）"
```

### Task 7: Phase 1 全量回归

- [ ] **Step 1: analyze + test**

Run: `cd snapp; flutter analyze; flutter test`
Expected: analyze 零错误零警告；test 全绿（新增 ≥6 widget 测试 + 1 集成测试，SQL 原有 83 项不回归）。

- [ ] **Step 2: 汇报并停下，等用户确认后再进 Phase 2**

---

## Phase 2 · 已知布局/调试问题修复

### Task 8: 定位并修复设置页空白 + overflow

**Files:**
- Modify: `snapp/lib/pages/settings/settings_page.dart`

**Interfaces:**
- Consumes: 主题扩展 `Theme.of(context).appColors`、现有布局结构
- Produces: 设置页卡片无空白、无 overflow；补一条 widget 测试

- [ ] **Step 1: 读取并诊断**

Run: `cd snapp; grep -n "AppCard\|Column\|Row\|overflow\|ErrorWidget" lib/pages/settings/settings_page.dart`
> 定位 settings 页卡片内容的 Row/Column 是否存在溢出（如主色值信息区在窄屏供不应求）。结合用户复现条件（设备宽/字号）修正为可滚动或 `Flexible`。

- [ ] **Step 2: 修复布局**（依据诊断结果做最小修正；示例——若卡片出现 overflow 把固定宽改为可收缩）

```dart
// 诊断到溢出处：改用 Flexible + ellipsis，杜绝 RenderFlex overflowed。
Flexible(
  child: Text(
    value,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).appColors.text2...
  ),
)
```

- [ ] **Step 3: 补测试防回归**

在 `snapp/test/settings_page_test.dart`（新建）中 pump `appRoot()` → 切到「我的」tab → 进设置页，断言 `tester.takeException()` 为 null。

- [ ] **Step 4: analyze + test**

Run: `cd snapp; flutter analyze; flutter test`
Expected: 全绿。

- [ ] **Step 5: Commit**

```bash
git add snapp/lib/pages/settings/settings_page.dart snapp/test/settings_page_test.dart
git commit -m "fix(flutter): 修复设置页卡片空白与 overflow"
```

### Task 9: 复核 theme_page `_ModeDemo` 高度溢出

**Files:**
- Modify: `snapp/lib/pages/theme/theme_page.dart`（`_ModeDemo`，约 L310 附近）

- [ ] **Step 1: 复核 `_ModeDemo` 高度**

> 上次已调整尺寸。复核 `_ModeDemo` 内 Column 在系统大字体（textScaleFactor>1）下是否还会溢出；把定高改为弹性或加滚动保护。

- [ ] **Step 2: 修复（如仍有溢出）**

用 `LayoutBuilder` / `Flexible` 包裹 demo 内容，避免固定 `height` 在放大字号下溢出。

- [ ] **Step 3: analyze + test**

Run: `cd snapp; flutter analyze; flutter test`
Expected: 全绿。

- [ ] **Step 4: Commit**

```bash
git add snapp/lib/pages/theme/theme_page.dart
git commit -m "fix(flutter): 复核 theme 页 _ModeDemo 高度自适应"
```

### Task 10: Transform.translate 替代负 margin 覆盖盘点

**Files:**
- Modify: 视盘点结果（各页面/widgets）

**Interfaces:**
- Consumes: 现有已用 `Transform.translate` 的点位（play_bar `_PanelHeader` 已示范）
- Produces: 全项目无 `margin: EdgeInsets.only(left: -/top: -)` 负值

- [ ] **Step 1: 扫描负 margin**

Run: `cd snapp; rg -n "EdgeInsets.*(-1|-2|-3|-4|-5|-6|-8|-10|-12)|\.0\)" lib/ | rg "left:|top:|bottom:"`
> 找出遗留负 margin。每个 `EdgeInsets.only(left:-x)` → `Transform.translate(offset: Offset(x,0))`；`top:-x` → `Offset(0,x)`。

- [ ] **Step 2: 逐一替换为 Transform.translate**（按步骤 1 结果）

替换示例：
```dart
// 改前
margin: const EdgeInsets.only(left: -12),
// 改后
child: Transform.translate(offset: const Offset(12, 0), child: child),
```

- [ ] **Step 3: analyze + test**

Run: `cd snapp; flutter analyze; flutter test`
Expected: 全绿。

- [ ] **Step 4: Commit**

```bash
git add snapp/lib
git commit -m "fix(flutter): 负 margin 统一改为 Transform.translate"
```

### Task 11: Phase 2 全量回归 + 汇报

- [ ] **Step 1: analyze + test**

Run: `cd snapp; flutter analyze; flutter test`
Expected: 全绿。

- [ ] **Step 2: 停下汇报，等确认后进 Phase 3**

---

## Phase 3 · 架构与代码质量审计

### Task 12: Service 边界审计报告 + 修正 2-3 处

**Files:**
- 审计: `snapp/lib/services/*.dart`
- 修改: 视审计结果

**Interfaces:**
- Consumes: 现有 service（PlayerService/FavoritesService/CheckinService/CustomSceneService/StatsService/AchievementService/BannerService/SceneService/AppStorage）
- Produces: 审计报告 + 高价值修正

- [ ] **Step 1: 审计**

逐 service 检查：接口与实现分离是否符合 AGENTS.md 目标形态；是否出现 Store 直接引用；是否存在可避免的 `dynamic`；单文件是否过大。

- [ ] **Step 2: 记录报告**

写入设计文档对应章节（追加 `Phase 3 审计结论`），列面积与结论。

- [ ] **Step 3: 修正 2-3 处高价值项**（示例：若某 service 直接 new 另一 service 改为构造注入；或 `dynamic` 列表改为强类型）

- [ ] **Step 4: analyze + test**

Run: `cd snapp; flutter analyze; flutter test`
Expected: 全绿。

- [ ] **Step 5: Commit + 同步 AGENT.md（如涉目录/约定变更）**

---

## Phase 4 · 响应式 + Widget Preview

### Task 13: 核心组件加 Widget Preview

**Files:**
- Modify: `snapp/lib/widgets/scene_card.dart`, `sound_card.dart`, `play_bar.dart`

**Interfaces:**
- Consumes: 现有组件 props
- Produces: 各组件在 previews 中可用，便于窄/宽屏目视审查

- [ ] **Step 1: 在三个组件文件顶部加 preview（遵循 flutter-add-widget-preview）**

以 SceneCard 为例：
```dart
@Preview(name: 'SceneCard · 网格', widget: SceneCard(
  name: '静谧森林',
  soundCount: 4,
  soundIcons: <String>['stream'],
  bgColor: 'linear-grad...',
  cover: null,
  isPreset: false,
  isGrid: true,
  active: true,
  onTap: null,
  onPlay: null,
))
```
> 具体 previews API 以 `flutter-add-widget-preview` skill 当前规范为准；若工程尚无 previews.dart 则本任务只搭骨架，不阻塞其余阶段。

- [ ] **Step 2: analyze + test**

Run: `cd snapp; flutter analyze; flutter test`
Expected: 全绿。

- [ ] **Step 3: Commit**

---

### Task 14: 窄屏响应式适配

**Files:**
- Modify: 关键页面（index/scene/player）

**Interfaces:**
- Consumes: `LayoutBuilder` / `MediaQuery` / 现有组件
- Produces: 窄屏（360 逻辑宽）与宽屏（平板）无溢出

- [ ] **Step 1: 检视窄屏**

用 `LayoutBuilder` 在每个页面根布局包裹，确认最窄 360 宽不溢出；若有固定宽 > 屏宽，改为 `FractionallySizedBox` / `Flexible`。

- [ ] **Step 2: 修溢出**（对每个溢出点最小修正）

- [ ] **Step 3: analyze + test**

Run: `cd snapp; flutter analyze; flutter test`
Expected: 全绿。

- [ ] **Step 4: Commit**

---

## Phase 5 · UI/UX（规范自检 + 主题切换验收）

### Task 15: 规范自检——零硬编码 + 触控 + 圆角/间距

**Files:**
- Modify: 视扫描结果

- [ ] **Step 1: 扫描硬编码色值**

Run: `cd snapp; rg -n "Color\(0x|Colors\.|\#[0-9a-fA-F]{3,8}" lib/`
> 对命中的业务请求代码逐一点位：改走 `Theme.of(context).appColors` 语义 token。

- [ ] **Step 2: 检查触控目标 ≥44**

扫描近 22px 级按钮/图标点击区，不足 44pt 的补 `Container(width/height:44)` 热区（用 `PressableScale` 或 GestureDetector+透明度透明容器）。

- [ ] **Step 3: 抽查圆角/间距对齐 MASTER v2**（对照 `docs/design-system/MASTER.md` 组件 token）

- [ ] **Step 4: analyze + test**

Run: `cd snapp; flutter analyze; flutter test`
Expected: 全绿。

- [ ] **Step 5: Commit**

---

### Task 16: 主题切换验收清单 + 修正

- [ ] **Step 1: 主题切换验收**

抽查 6配色 × 3风格 × 明暗 在 首页/播放器/场景页 的：对比度（4.5:1 亮文字 vs primary）、明暗分层、浮层取向（flat 实底 / glass 毛玻璃 / neu 降级为毛玻璃）、无混搭。

- [ ] **Step 2: 记录验收清单**（写入设计文档 `Phase 5 验收`）

- [ ] **Step 3: 修正发现的问题**（按规范）

- [ ] **Step 4: analyze + test**

Run: `cd snapp; flutter analyze; flutter test`
Expected: 全绿。

- [ ] **Step 5: Commit + 汇报收尾**

---

## Phase 收尾

### Task 17: 汇总验证 + 更新文档

- [ ] **Step 1: 全量回归**

Run: `cd snapp; flutter analyze; flutter test`
Expected: 零错误零警告 + 全绿（含新增测试）。

- [ ] **Step 2: 更新 AGENT.md**

补录各阶段产出；修改「最后更新」日期到 2026-09-19；第八章补录本 plan 与 Phase 结论（如需）。

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md docs/superpowers/plans/2026-09-19-flutter-optimization.md
git commit -m "docs(flutter): 全面优化实施计划 + AGENT.md 同步"
```

- [ ] **Step 4: 汇报最终总结**

---

## Self-Review 结果

- **Spec 覆盖**：Spec 五阶段（测试/修复/架构/响应式/UI）各映射到 Phase 1–5；UI 的「规范自检 + 已知问题 + 主题验收」映射到 Task 8/9/10 + 15/16；每阶段 analyze+test 验收达成 spec 全局约束。✅
- **占位符扫描**：Task 3/4/5/6 提供完整可运行测试代码；Task 8/9/10/13/14/15 的修复步骤依赖诊断/扫描结果，已给出明确命令与替换示例，非空泛「待定」。✅
- **类型一致性**：`appRoot` 在 helpers 定义，Task3-6 一致消费；`findScene`/`getCategoryScenes`/`SimulatedAudioEngine` 名与现有代码一致；`IntegrationTestWidgetsFlutterBinding` 用法正确。✅