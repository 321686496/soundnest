# 声栖 · Flutter 工程全面优化设计

> 版本 v1.0（2026-09-19） · 对 `snapp/`（Flutter）主工程做一轮系统性加固与打磨
> 前置：T1–T9 全功能已落地，`flutter analyze` 零错误、83 项 `flutter test` 全绿、UI 遵循 Design System MASTER v2
> 依赖 skill：`partial-name` 见各 Phase 标注

---

## 1. 背景与目标

`snapp/` 已是功能完整的主代码工程（iOS / Android / HarmonyOS 三平台），不在救火而是**有基线的代码上做加固**。本优化在五个维度系统性推进，全部以「不破坏现有功能、保持三平台可构建」为前提。

目标产出：
1. 测试覆盖从「services 为主」提升到「关键页面有 widget 测试 + 一条集成测试」
2. 已知布局/调试问题（爆红、溢出、负 margin、设置页空白）逐一定位并固化测试
3. 分层架构边界审计，修正 2-3 处高价值坏味道
4. 核心组件响应式适配 + Widget Preview 化，窄屏无溢出
5. 逐页规范自检 + 主题切换（6配色×3风格×明暗）验收

**铁律**：任何 Phase 完成后必须 `flutter analyze`（零错误零警告）+ `flutter test`（全绿）才视为通过；每阶段停下向用户汇报，确认后再进下一阶段。

---

## 2. 执行顺序与对应 skill

| Phase | 内容 | 对应 skill |
|---|---|---|
| 1 | 测试铺底：关键页面 widget 测试 + 集成测试 | `flutter-add-widget-test` / `flutter-add-integration-test` |
| 2 | 布局/调试问题修复 | `flutter-fix-layout-issues` |
| 3 | 架构与代码质量审计 | `flutter-apply-architecture-best-practices` |
| 4 | 响应式/兼容性 + Widget Preview | `flutter-build-responsive-layout` / `flutter-add-widget-preview` |
| 5 | UI/UX：规范自检 + 主题切换验收 | 规范自检 / 主题验收流程 |

---

## 3. Phase 1 · 测试铺底

**目的**：为后续所有改动铺安全网。

范围（当前缺口：关键页面缺 widget 测试）：
- 为 4 个核心页面补 Widget 测试：首页 `index_page`、场景页 `scene_page`、播放器 `player_page`、播放条 `play_bar`（含混音交互）。
- 补一条集成测试：冷启动 → 首页 → 播放一个场景 → 底部 PlayBar 同步 → 停止，完整链路。

**验收标准**：
- `flutter test` 全绿。
- 新增 widget 测试 ≥ 6–8 项 + 1 条集成测试。
- 每个测试对页面渲染与关键交互（点击播放/切换/返回）均有断言。

---

## 4. Phase 2 · 已知布局/调试问题修复

**目的**：消除历史遗留的红屏与溢出风险。

排查清单：
- 设置页卡片空白 + overflow 报错（上次未复现，需定位触发条件）。
- `theme_page` `_ModeDemo` 内部 Column 高度溢出问题复核。
- 受影响底部 Sheet 顶部圆角/边框冲突是否彻底排除。
- 审查所有 `Transform.translate` 替代负 margin 的落地是否覆盖全部历史点位。

**验收标准**：`flutter analyze` 零错误零警告；`flutter test` 全绿；相关页面在窄/宽屏无 overflow 报错；每个修复对应回归测试。

---

## 5. Phase 3 · 架构与代码质量审计

**目的**：分层已成型，做边界审计而非重构重来。

审计点：
- service 层是否遵循「接口与实现分离」目标形态。
- Store/Service 间是否出现直接引用。
- 是否存在可避免的 `dynamic`。
- 单文件是否过大需拆分（以可独立理解/测试为界）。
- 跨平台条件编译（`Platform.isX`）使用是否规范。

**交付**：架构审计报告（找出问题 → 修正 2-3 处高价值项 → 同步 AGENT.md 如涉及目录/约定变更）。

**验收标准**：`flutter analyze` + `flutter test` 全绿；报告列出已修问题与结论。

---

## 6. Phase 4 · 响应式/兼容性 + Widget Preview

**目的**：保证关键字手机与平板等不同屏幕尺寸下布局正确。

内容：
- 为可复用核心组件（SceneCard / SoundCard / PlayBar / 双列网格）加 Widget Preview（`flutter-add-widget-preview`）。
- 用 `LayoutBuilder` / `MediaQuery` 检视关键页面窄屏（小屏机）与宽屏（平板）适配，修正溢出（`flutter-build-responsive-layout`）。

**验收标准**：核心组件有 preview；窄屏关键页无溢出；`flutter analyze` + `flutter test` 全绿。

---

## 7. Phase 5 · UI/UX：规范自检 + 主题切换验收

**目的**：确保视觉与交互严格对齐 Design System MASTER v2、无硬编码、无混搭。

内容：
- **规范自检**：逐页对照 MASTER v2 token / 触控（≥44pt）/ 间距 / 圆角，修正偏差；确认业务代码无 `Color(0xFF…)` / `Colors.xxx` 硬编码。
- **主题切换验收**：抽查 6配色 × 3风格 × 明暗两模式，在首页/播放器/场景页查看可读性、对比度（4.5:1）、明暗分层一致性；每一 UI 风格浮层取向（flat/glass/neu）正确。

**交付**：主题切换验收清单（逐页逐组合结论 + 修正项）。

**验收标准**：验收清单输出；发现的问题修正；`flutter analyze` + `flutter test` 全绿。

---

## 8. 全局约束

- 主工程唯一改动对象为 `snapp/`；`prototype/`（uni-app）仅作设计基线参考，不改其代码。
- 封面、图标、排版遵循 MASTER v2 与品牌（深森林绿 `#3D6B5E`）。
- 引入任何三方库前必须查 Harmony 适配清单（当前各 Phase 均不引入新三方库，若出现需走 5.2 流程）。
- 三平台构建验证：本阶段以代码层保证为主；真机/OHSDK 构建列为后续待办（同 5.7）。
- 改动完成后同步更新涉及的设计文档与 AGENT.md（文档同步规则）。

---

## 9. 文档同步

- 本设计文档写入 `docs/superpowers/specs/` 并提交 git。
- AGENT.md 第八章「关键文档索引」需补录本设计文档。
- 实施计划文档（writing-plans）引用本设计文档。

---

## 10. Phase 3 审计结论（Task 12）

> 审计对象：`snapp/lib/services/*.dart`（`media_bridge.dart` 为本优化并行、仅只读观察，不在本审计范围）。审计日期 2026-09-19。

### 10.1 Service 面积 / 职责一览

| Service | 文件 | 行数 | 职责 | 接口/实现 | 注入方式 | 结论 |
|---|---|---|---|---|---|---|
| `AudioEngine` | audio_engine.dart | 169 | 抽象引擎接口 + `SimulatedAudioEngine` / `JustAudioEngine` 两实现 | ✅ 明确抽象接口分离 | 构造注入（PlayerService） | 优 |
| `AppStorage` | app_storage.dart | ~90 | 本地存储统一静态入口（`shengqi-*`） | static，无状态 | N/A | 良 |
| `PlayerService` | player_service.dart | ~400 | 播放/混音/定时/最近记录状态机（含 `PlayerTrack`、`RecentItem` 模型） | ChangeNotifier | stats/engine 构造注入 | 良（文件偏大） |
| `StatsService` | stats_service.dart | ~175 | 播放统计 / 排行 / 活跃天数，时钟可注入 | ChangeNotifier | 时钟构造注入 | 良 |
| `FavoritesService` | favorites_service.dart | ~40 | 收藏 ID 集合持久化 | ChangeNotifier | N/A | 良 |
| `CheckinService` | checkin_service.dart | ~75 | 签到集合 / 连续天数，时钟可注入 | ChangeNotifier | 时钟构造注入 | 良 |
| `CustomSceneService` | custom_scene_service.dart | ~70 | 自定义场景 CRUD | ChangeNotifier | N/A | 良 |
| `AchievementService` | achievement_service.dart | ~190 | 8 项成就评估，订阅 5 数据源 | ChangeNotifier | 5 依赖全构造注入 | 优 |
| `SceneService` | scene_service.dart | ~130 | 场景/配方/推荐纯函数 | 顶层函数 + 模型 | N/A | 优 |
| `BannerService` | banner_service.dart | ~100 | 首页 banner 组装（纯函数，注入 stats/recent） | 顶层函数 | 参数注入 | 优 |

### 10.2 审计结论

1. **接口与实现分离**：达标。`AudioEngine` 抽象 + 双实现清晰；`SceneService`/`BannerService` 为纯函数式服务，`StatsService`/`CheckinService` 支持时钟注入，均符合 AGENTS.md `services/` 目标形态。
2. **Service 间直接引用 / Store-to-Store**：无违规。审计确认没有任何 service 直接 `new` 另一 service——全部依赖经构造函数/参数注入装配（`AchievementService` 5 个依赖、`PlayerService` stats/engine、`BannerService` stats/recent 均为注入）。装配点集中在 `main.dart`（该文件属并行改动，未触碰）。
3. **`dynamic` 滥用**：存在一处根因——`AppStorage.readJsonList` 返回 `List<dynamic>?`，迫使 `PlayerService / FavoritesService / CheckinService / CustomSceneService / AchievementService` 5 处 `load()` 各自重复 `.whereType<Map<dynamic,dynamic>>().map(...cast<String,dynamic>...)`；`StatsService.load` 另有两处 `(dynamic k, dynamic v)`。均已修正（见 10.3）。
4. **单文件过大**：`PlayerService`（~400 行）最大，同时承载 `PlayerTrack`/`RecentItem` 模型与播放状态机；当前可独立理解、可读性尚可，**需在后续版本化拆分，本次不强行重构以免破坏 API**。

### 10.3 修正项清单（Task 12）

| # | 文件:行号 | 原因 | 性质 |
|---|---|---|---|
| A | `app_storage.dart`（新增 `readJsonListOfMaps`，lines 56-69） | 在「反序列化边界」层强类型化，消除各 service 重复的 `dynamic` 模式 | 强类型化（根因） |
| A | `player_service.dart` `loadRecent`（120-125） | 消除 `.whereType<Map<dynamic,dynamic>>().map(...cast...)` | 强类型化 |
| A | `favorites_service.dart` `load`（13-21） | 同上 | 强类型化 |
| A | `checkin_service.dart` `load`（36-45） | 同上 | 强类型化 |
| A | `custom_scene_service.dart` `load`（17-26） | 同上 | 强类型化 |
| A | `achievement_service.dart` `load`（111-125） | 同上；迭代体改为强类型 `Map<String,dynamic>` | 强类型化 |
| B | `stats_service.dart` `load`（129-142） | 消除两处 `(dynamic k, dynamic v)`，改 `cast<String,num>()` 强类型迭代 | 强类型化 |

> 全部修正为行为等价的机械重构，未改变任何既有公开 API 签名与调用方；`readJsonList` 保留（仍为 `theme_notifier` 等使用），未破坏调用。

---

## 11. Phase 4 Widget Preview 审计结论（Task 13）

> 审计日期 2026-09-19。对象：`snapp/lib/widgets/{scene_card,sound_card,play_bar}.dart`。
> 本 Phase 因 SDK 硬件约束收口为「审计 + 记录性交付」，不落地任何 `@Preview` 代码。

### 11.1 为何暂缓（SDK 能力复核）

- 当前 PATH 为 Harmony SDK `flutter 3.7.12-ohos-1.1.3`（Dart 2.19.6，`D:\flutter\flutter_harmony\flutter_flutter`）。
- 已核对框架库 `packages/flutter/lib/src/widgets/` **不含 `widget_previews.dart`**（源码 glob 未命中）。
- Widget Previewer（`@Preview` + `package:flutter/widget_previews.dart`）为 Flutter 3.38+ 内置能力；当前 SDK 无法解析该 import，写入即导致 `flutter analyze` error，破坏 Phase 验收。
- 结论：**暂缓落地**，待升级到 Flutter 3.38+ 的 Harmony 适配分支后再启用。此决策不阻塞其余 Phase / Task 14。

### 11.2 三组件 props 可预览性审查（只读）

| 组件 | 构造 props | 原生依赖 | 是否需要 Provider 包裹 | 可预览性结论 |
|---|---|---|---|---|
| `SceneCard` | `name/soundCount/soundIcons/bgColor/cover/isPreset/isGrid/active/soundLabel/bottomMargin` + `onTap/onPlay/onShare` | 无；`Image.asset(sceneImageAsset(cover))` 带 `errorBuilder` 回退渐变 | 否 | ✅ 全字面量可独立构造，升级后可直加 `@Preview` |
| `SoundCard` | `name/type/iconName/color/isActive` + `onTap` | 无（纯 `AppCard` + `AppIcon`/`Text`） | 否 | ✅ 全字面量可独立构造，升级后可直加 `@Preview` |
| `PlayBar` | `onSaveTap`（外层仅透传） | 无 | **是**：`_PlayBarInner`/`_TimerPanel`/`_MainPlayButton`/`_TimerChip` 内部大量用 `context.select/read<PlayerService>` 订阅播放态/定时面板 | ⚠️ 需在 Preview 外层包 `ChangeNotifierProvider<PlayerService>`（预置一个 mock 状态实例），否则渲染期抛 `ProviderNotFoundException` |

### 11.3 升级 Flutter 3.38+ 后落地要点（按 `flutter-add-widget-preview`）

1. **工具入口**：先调用 `flutter-add-widget-preview` skill，按其配置 `previews` 基础设施（`snapp/tool/previews/` 与 `@Preview` 脚手架）。
2. **SceneCard**：在 `scene_card.dart` 文件尾新增 `@Preview("SceneCard · grid")` / `@Preview("SceneCard · row")` 两个示例函数，填入 `name:'雨夜小屋'`、`soundCount:3`、`soundIcons:['rain','thunder']`、`bgColor`（Morandi 渐变字符串）、`isGrid:true/false`、`active:false`、`onTap/onPlay:(){}` 等字面量即可渲染。⚠️ 预览需包裹主题 `MaterialApp`（`ThemeExtension` 读取 `Theme.of(context).appColors`），缺主题装饰器会空渲染。
3. **SoundCard**：文件尾新增一个 `@Preview`,填 `name/type/iconName/color` 字面量、`isActive:false`、`onTap:(){}`；同样需主题包裹。
4. **PlayBar**：文件尾新增 `@Preview`；因内部依赖 Provider，示例函数须先用 `ChangeNotifierProvider<PlayerService>.value(value: PlayerService(...))` 包裹 `PlayBar`，或加隔离的视图模型桩；否则 `context.select<PlayerService,...>` 立即抛 `ProviderNotFoundException`。此为本组件与其他两者的关键差异。
5. **验收**：`flutter analyze` 0 error/0 warning；`flutter test` 全绿；`flutter run` 打开 `previews` 面板目视三组件正常渲染。

> 本阶段**未向 `snapp/lib` 写入任何 `@Preview`/`widget_previews.dart` import**，保证 analyze 保持 0 err / 0 warn（仅追加本设计文档）。