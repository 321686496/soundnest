# AGENT.md — 声栖（白噪音混音助眠应用）

> 项目根目录智能体指令文件
> 最后更新：2026-10-12

---

## 一、项目概览

声栖是一款白噪音混音助眠 App，采用 iPhone / Apple HIG 设计美学。仓库包含 **两个工程**：

> **铁律（重要）**：**`snapp/`（Flutter）是主代码工程**，日常改动、功能迭代、Bug 修复一律默认在 Flutter 工程中进行；`prototype/`（uni-app）是**设计原型 / 参考基线**，仅作为视觉、配色、交互的权威参照，非特殊情况不改其代码（改了也需先获许可）。

| 维度 | uni-app 工程（原型/参考） | Flutter 工程（主开发） |
|---|---|---|
| 目录 | `prototype/` | `snapp/` |
| 技术栈 | uni-app（Vue 3 + TS）+ Vite | Flutter（Dart） |
| 定位 | **设计原型 / 参考基线**：定义「最终长什么样」的权威事实来源（v2 已全量落地：明暗双模式 + 6 配色 × 3 UI 风格） | **主代码工程**（T1–T9 全功能已实现：`flutter analyze` 零错误、`flutter test` 全绿） |
| 状态 | 完整视觉体系 + 主题引擎 + 全组件/页面（作为对照基准） | 全功能已落地，为主开发对象 |
| 目标平台 | H5 / 多端小程序 | iOS / Android / **HarmonyOS**（含 `ohos/`） |

> **关键约束**：
> 1. **默认改动落在 `snapp/`（Flutter）**；`prototype/`（uni-app）是**设计基线**，实现 UI 时须与其保持一致，以 uni-app 源码为权威视觉参考，但**不作为主代码改动对象**。
> 2. Flutter 工程为三平台主工程，需兼容 iOS / Android / HarmonyOS，涉及三方库必须先经 Harmony 适配校验。

### 1.1 两个工程的关系

- `prototype/` 定义「最终长什么样」：主题 token、组件样式、交互流程全部在其源码中落地，是设计基线。
- `snapp/`（Flutter）是**主代码工程**，负责以真原生的方式承载与演进产品实现；样式与交互须与原型一致，**不得自行发明配色或组件**。
- 诉求到代码的落地顺序：**先对齐 `prototype/` 的设计基线 → 默认在 `snapp/`（Flutter）实现**。

---

## 二、核心工程约定（uni-app `prototype/`）

原型代码全部位于 `prototype/src/`。改动代码前必读以下约定，避免破坏既有设计与数据一致性。

### 2.1 技术栈与命令

- **框架**：uni-app + Vue3 `<script setup lang="ts">` + Vite 5
- **语言**：TypeScript（`vue-tsc --noEmit` 类型检查）
- **样式**：SCSS（`uni.scss` 提供全局变量）
- **包管理**：pnpm@11

在 `prototype/` 目录下执行：
- `pnpm dev:h5`：H5 开发
- `pnpm build:h5`：H5 构建
- `pnpm type-check`：类型检查（**改动后务必通过**）

### 2.2 目录结构

```
prototype/src/
├── App.vue               # 全局样式 / 设计语言 / 启动日志（initTheme 调用）
├── main.ts               # 应用入口
├── pages.json            # 页面与 tabBar 注册
├── manifest.json         # 应用配置（名称应为「声栖」）
├── uni.scss              # SCSS 全局变量（品牌主色等）
├── pages/                # 页面（index / scene / scene-detail / scene-all / scene-edit / library / discover / mine / settings / theme / achievement / invite / checkin / stats / favorites / history / onboarding）
├── components/           # 组件（Icon / TabBar / PlayBar / SceneCard / SoundCard / MixTrack）
├── composables/          # usePlayer.ts（共享播放状态单例）
├── data/                 # scenes.ts（场景数据层）/ sounds.ts（音频库）
├── theme/                # index.ts（主题引擎：配色 × UI 风格）
└── static/               # 静态资源（logo、场景封面、tab 图标等）
```

### 2.3 硬性约束（改动必须遵守）

- 应用名必须为「声栖」，品牌主色为深森林绿 `#3D6B5E`，与 logo 的莫兰迪绿一致。
- 首页头部须展示 logo 图片 + 「声栖」品牌名。
- 图标：**禁止 emoji**，一律使用 `components/Icon.vue` 定义的定制 SVG 图标。
- iconName 必须与 `Icon.vue` 已定义图标名一致，新增前先确认图标存在。
- 所有页面/卡片/按钮颜色必须走主题变量 `var(--app-*)` 与 `.app-card` 容器，**不新增自定义颜色**。
- 不混用不同 UI 风格或主题色；UI 样式必须随主题引擎切换而变化。
- 修改前先获用户许可，不得在未授权下改动代码。

### 2.4 主题引擎（theme/index.ts）

- 配色 6 套：`morandi / ocean / forest / sunset / lavender / mono`。
- UI 风格 3 套：`flat 扁平化 / glass 玻璃拟态 / neu 新拟态`。
- 以「配色 × UI 风格」二维组合生成运行时 CSS 变量，注入 `html` 根节点，即时切换、本地持久化（storage key `shengqi-theme`）。
- `.page-bg` 必须使用 `z-index: -1`（为 0 会导致文字渲染异常）。

### 2.5 共享播放状态（usePlayer.ts）

- `player` 为模块级 `reactive` 单例，首页大播放卡 / 场景网格 / 底部 PlayBar 读写同一状态。
- 应用/播放场景走 `applyScene(scene)`（重建音轨并写入最近记录）；无音轨时 `togglePlay()` 返回 false，由调用方 toast 提示。
- 场景页推荐区需用 `ref` 承载结果并在 `onShow` 刷新，否则播放后不更新。
- 最近记录本地存储 key `shengqi-recent`，上限 10 条。

### 2.6 数据层（data/scenes.ts）

- 统一由 `homeScenes` 提供场景数据；`findScene(id)` 查找，找不到回退 `homeScenes[0]`。
- 保持数据层函数：`getRecommended / getCategoryScenes / buildRecipe / buildPresets`。
- 模拟偏好标签写死 `['sleep','nature']`；推荐逻辑优先「偏好分类且未听过」，不足按序补齐。

---

## 三、uni-app 源码作为设计参考（强制）

> 当任务需要参考**设计稿、配色、组件样式、交互流程**时，直接阅读 `prototype/src` 源码作为**权威参考**，不要凭记忆臆造。

- **配色 / Token**：以 `src/theme/index.ts` 的 token 定义与 `src/uni.scss` 变量为准，禁止自造色值。
- **组件样式 / 布局**：以 `src/App.vue` 的公共样式（`.app-card`、`.btn-primary`、`.section-title` 等）与 `src/components/*.vue` 的实际实现为准。
- **交互流程**：以 `src/composables/usePlayer.ts`（播放/混音状态机）与各 `pages/*/*.vue` 的页面流程为准。
- **迁移到 Flutter 时**：以 `prototype/src` 为对照基准，逐组件、逐页面 1:1 复刻（见第四章）。

---

## 四、Flutter UI 设计规范（强制）

> `snapp/`（Flutter）在实现任何 UI 前必须阅读本规范。

### 4.1 样式跟随主题（铁律）

- **样式永远跟随「设置里的 UI 风格 + 主题」**，通过统一的主题对象读取，**禁止硬编码颜色 / 圆角 / 阴影 / 间距**。
- 主题切换（6 配色 × 3 UI 风格）须 1:1 迁移原型：用 `ThemeData` + 自定义 `InheritedWidget`（或等价方案）承载，切换时全局即时生效并持久化。
- 所有颜色一律通过 `Theme.of(context)` / 主题扩展读取；业务代码中**不得出现** `Color(0xFF...)`、`Colors.xxx`、硬编码边框/阴影数值。
- **禁止不同 UI 风格 / 不同主题色混搭**：一个界面只能呈现一种 UI 风格 + 一套配色，不得出现「玻璃态卡片叠在扁平化页面、新拟态按钮与扁平按钮共存」等情况。

### 4.2 新拟态（neumorphic）的浮雕取向铁律

新拟态靠「组件表面色与画布背景色一致 + 外阴影明暗」营造浮雕感，不得加描边。方向铁律：

- **光源固定**：光线从左上前方来（top-left 亮）。
- **凸起（浮出）**＝左上浅色高光阴影 + 右下深色阴影。
- **凹陷（按下 / 选中）**＝左上深色阴影 + 右下浅色阴影（方向反转）。
- 按钮按下态＝**内凹下沉**；选中态＝**同样的凹陷按压样式**。
- 组件表面色必须与所在画布背景一致；禁止为浮雕加描边或色块边缘。

### 4.3 各风格「叠在照片上」的浮层取向（速查）

当浮层 / 卡片要叠在照片、封面等复杂图片之上时，按 UI 风格采取对应取向：

| UI 风格 | 浮层取向（叠在照片/图片上） | 说明 |
|---|---|---|
| `flat` 扁平化 | **不透明实底** | 白 / 主题底色盖在图上，加发丝描边与柔和投影，不使用毛玻璃 |
| `glass` 玻璃拟态 | **半透明 + 毛玻璃模糊** | `backdrop-filter` 磨砂透出照片，半透明底 + 白色高光边框 |
| `neu` 新拟态 | **禁止浮雕双阴影** | 图片背景无法呈现浮雕明暗，必须降级为「半透明/实底 + 毛玻璃」浮层，避免落影错乱 |

> 即：新拟态本身不能在「照片上」做浮雕，遇到图上浮层一律退回玻璃/实底取向；如何判断要落到哪款则以当前 UI 风格为准。

### 4.4 Flutter 工程目录约定（目标形态）

```
snapp/lib/
├── main.dart                    # 应用入口
├── app/                         # 应用根组件、路由配置（app.dart / router.dart / shell.dart / shell_tabs.dart / theme_prefs.dart）
├── pages/                       # 页面（与 uni-app pages/ 对齐）
├── widgets/                     # 公共组件（对应 uni-app components/）
├── composables/                 # 业务逻辑 Hooks（对应 useXxx.ts）
├── services/                    # 服务层（接口与实现分离）
├── models/                      # 数据模型（对应 data/scenes.ts / sounds.ts）
├── theme/                       # 设计 Token 与主题切换
├── utils/                       # 工具函数
└── data/                        # 静态数据
```

## 五、Flutter 工程开发规范（Harmony 适配强制阅读）

> **核心原则**：`snapp/`（Flutter）为后续主开发技术栈，所有 Flutter 代码必须同时兼容 **iOS / Android / HarmonyOS** 三大平台（含 `ohos/` 目录）。
>
> **强制规则**：每次开发 Flutter 工程，若涉及使用或引入三方库，**必须先阅读**下方 Harmony 版 Flutter 引擎与三方库适配清单，以适配清单作为引入决策依据，确保所用 API、三方库均在 Harmony 适配范围内，保证工程能正确适配 HarmonyOS 端。

### 5.1 强制参考资源（开发前必读）

| 资源 | 地址 | 用途 |
|---|---|---|
| Harmony 版 Flutter 引擎（主仓） | https://gitcode.com/CPF-Flutter/flutter_flutter | 华为 HarmonyOS 适配的 Flutter SDK 主仓，引入三方库前须了解 Harmony 版 Flutter 的 API 支持范围 |
| Harmony 版 Flutter 引擎（分支） | https://gitcode.com/CPF-Flutter/flutter_flutter/tree/br_3.7.12-ohos-1.1.3 | 当前采用的 Harmony 适配分支（3.7.12-ohos-1.1.3） |
| 三方库适配清单 | https://gitcode.com/OpenHarmony-Flutter/docs/blob/main/ThirdpartyLibrarites.md | 已适配 Harmony 的三方库查询清单，**引入任何三方库前必须在此查证** |
| OpenHarmony-Flutter 文档总仓 | https://gitcode.com/OpenHarmony-Flutter/docs | Harmony 版 Flutter 适配文档总入口 |

### 5.2 三方库引入强制流程（MUST FOLLOW）

在 `snapp/`（或任何 Flutter 工程）引入任何新的三方库之前，**必须**按以下流程执行：

1. **查询适配清单**：访问 [三方库适配清单](https://gitcode.com/OpenHarmony-Flutter/docs/blob/main/ThirdpartyLibrarites.md)，搜索目标库是否已适配 Harmony。
2. **版本匹配**：确认适配清单标注的库版本与 `pubspec.yaml` 中要引入的版本兼容（当前 SDK `<3.0.0`）。
3. **降级 / 替代方案**：若目标库未适配 Harmony，必须寻找替代库（同样需通过清单校验）或自行实现等价功能，**禁止**强行引入未适配库导致 Harmony 平台构建失败。
4. **平台测试**：库引入后，必须在 iOS / Android / HarmonyOS 三平台分别构建一次，确认无平台报错。

### 5.3 Flutter 开发准则

- **语言**：Dart 强类型，禁用 `dynamic`（与原生交互必要的边界除外）。
- **状态管理**：统一方案（如 Riverpod / Provider），禁止 Store-to-Store 直接引用。
- **路由**：使用 **go_router 6.5.2** 声明式路由（`lib/app/router.dart` 统一 `GoRouter` 配置），页面跳转一律 `context.push/go/pop`，读参数用 `GoRouterState.of(context)` 的 `params` / `queryParams`，**禁止新增 `Navigator.pushNamed` / `ModalRoute` 取参**。路由路径与 uni-app `pages.json` 页面表一一对应；4 个 tab 页不走路由，由 `ShellWidget`（IndexedStack）保活切换（对应 `uni.switchTab` 语义）；首启引导由 `OnboardState` + `redirect` 守卫实现。Dialog / BottomSheet 仍可直接用 `Navigator.pop`（非页面路由）。
- **主题切换**：6 配色 × 3 UI 风格须 1:1 迁移，通过 `ThemeData` + 自定义 `InheritedWidget` 实现，并遵循第四章规范（跟随主题、禁硬编码、禁混搭）。
- **资源引用**：所有静态图片、字体通过 `assets/` 引用并在 `pubspec.yaml` 中声明。
- **平台条件编译**：使用 `Platform.isIOS` / `Platform.isAndroid` / Harmony 等价常量做平台分支，禁止使用未适配 API。
- **测试**：每个核心 Service / Composable 必须有单元测试，关键页面有 Widget Test。

### 5.4 设计参考（uni-app 源码）

所有页面、组件样式、配色、交互流程在实现前，阅读 `prototype/src` 对应源码作为权威参考（第三章），不得自行发明配色或组件。

### 5.5 Harmony 平台特别注意事项

1. **`ohos/` 目录维护**：`ohos/entry/src/main/ets/plugins/GeneratedPluginRegistrant.ets` 由构建工具自动生成，**禁止手动编辑**。
2. **EntryAbility**：`ohos/entry/src/main/ets/entryability/EntryAbility.ets`（若存在）须继承 `FlutterAbility`，并在 `configureFlutterEngine` 中调用 `GeneratedPluginRegistrant.registerWith`。
3. **权限声明**：相机、相册等权限需在 `ohos/entry/src/main/module.json5` 中声明，与 `android/app/src/main/AndroidManifest.xml`、`ios/Runner/Info.plist` 保持一致。
4. **构建命令**：Harmony 平台构建使用 `flutter build hap`（HAP 包）或 `flutter build app`（APP 包），开发调试使用 `flutter run -d <harmony-device>`。
5. **ArkTS/ArkUI**：涉及 `ohos/` 内 `.ets`（ArkTS / ArkUI）代码时，以华为官方开发文档（https://developer.huawei.com/consumer/cn/doc/ ）为准，**禁止凭记忆臆造 API**。
6. **媒体播控（media_controller 插件）**：OHOS 通知栏播放条（AVSession）与桌面音乐卡片（Form Kit 卡片，`EntryFormAbility` + `widget/pages/MusicWidget2x2/2x4`）由本地插件 `plugins/media_controller` 承载：应用级唯一 AVSession + RDB（`shengqi_media.db`）跨进程共享状态，channel `com.snapp.media`；Flutter 侧经 `lib/services/media_bridge.dart` 桥接 `PlayerService`。**EntryAbility 禁止向 AppStorage 覆盖 `'context'` 键**：just_audio_ohos 会据该键为每条音轨各建一个 AVSession（元数据恒「未知」且 dispose 不销毁），与应用级 session 冲突。

### 5.6 AI Agent Flutter 任务自检

每次 Flutter 工程任务完成后，**必须**自问并确认：

- [ ] 是否已先读取 [Harmony 版 Flutter 引擎](https://gitcode.com/CPF-Flutter/flutter_flutter) 与 [三方库适配清单](https://gitcode.com/OpenHarmony-Flutter/docs/blob/main/ThirdpartyLibrarites.md) 作为参考？
- [ ] 新引入的三方库是否已通过 5.2 的适配清单校验？
- [ ] 代码是否在 iOS / Android / HarmonyOS 三平台都能构建通过？
- [ ] 是否使用了未适配 Harmony 的私有 API 或三方库？
- [ ] 主题/样式是否遵循「设置里的 UI 风格 + 主题」，无硬编码、无混搭？
- [ ] 路由表是否与 uni-app `pages.json` 保持一致（迁移阶段）？
- [ ] 是否同步更新了相关设计文档与 AGENT.md？

### 5.7 已知待办

- **Harmony 三平台构建验证**：Flutter 全功能实现（T1-T9）已完成，路由已迁移至 go_router 6.5.2，`flutter analyze` 零错误；OHOS 端 `flutter build hap` 构建验证（见下），iOS / Android 构建验证列为后续待办。just_audio 0.9.37 已通过三方库适配清单校验（OpenHarmony `fluttertpc_just_audio`），音频在 Harmony 端走原生适配；go_router 为纯 Dart 包（无平台通道），不依赖 OHOS 原生适配，其 SDK 约束兼容工程 Dart 2.19.6。
- **go_router 版本锁定**：固定 **6.5.2**（7.x 起要求 Dart 3），API 与新版差异较大（`initialLocation` 而非 `initialRoute`、`state.params` / `state.queryParams` 而非 `pathParameters`），改动前须查阅本地 pub 缓存源码而非在线文档。
- **音频素材（2026-10-12 更新）**：已落地 20 条 Mixkit 真实采录音（补齐 13 条缺失音 + 升级 7 条伪自然音，Mixkit License 可商用免署名），逐条登记见 `docs/audio-assets-license.md`；`seed_data.dart` 资产集合拆分为 `generatedAudioIds`（纯合成）+ `recordedAudioIds`（真实录音）。缺口：`nightingale`（夜莺）与蓝/紫/灰噪音（按调研保留算法合成路线）仍走静音模拟。
- **OHOS 媒体播控（2026-09-19 已实现，待真机验证）**：通知栏播放条（AVSession 应用级唯一会话）与桌面音乐卡片（Form Kit：`EntryFormAbility` + 2x2/2x4 卡片，播控走 `postCardAction call` → `EntryAbility.callee`）已随 HAP 构建落地；需真机验证通知栏元数据/播控按钮、卡片添加与状态刷新、冷启动卡片播控恢复。
- **integration_test 跨盘约束**：SDK 在 D 盘而项目在 E 盘时，`flutter build hap` 会把 SDK 内 `integration_test/ohos`（D 盘）注入 `ohos/oh-package.json5` overrides，触发 ohpm `00618008 Cross Driver Error`。已 vendor 到仓库根 `vendor/integration_test` 并在 `snapp/pubspec.yaml` `dependency_overrides` 指向同盘 path 解决；**Harmony SDK 升级后须同步更新 vendor 拷贝**。

---

## 六、UI / 页面设计约定（uni-app 与 Flutter 通用）

- 遵循 iOS 语言（Apple HIG）：浅色背景 + 深色文字（类似 Stripe / Apple 官网高级感），**不用高饱和蓝紫渐变大字横幅（「营业厅促销风」）**。
- 分区表头用 iOS 式小号灰色次级标签（12px 灰），非大号加粗标题。
- 页面容器需含顶部安全区 padding（适配刘海设备），进入动效轻微上浮 + 淡入并兼容 `prefers-reduced-motion`。
- 网格/卡片布局项必须 `box-sizing: border-box`，避免 H5 双列变单列。
- 卡片组件偏好双列布局、紧凑边距；不同海报类型可用不同布局。
- 避免「AI 感」元素（过度光环、圆环、磨砂胶囊、轨道卫星、抢眼徽章）；避免空/杂乱/低质界面，未完成功能要么实现要么移除。

---

## 七、开发工作流

### 7.1 AI Agent 操作准则

- **默认改 Flutter（铁律）**：功能 / 样式 / Bug 修复一律默认在 `snapp/`（Flutter）实现；`prototype/`（uni-app）只是设计基线，仅在涉及“视觉应该长什么样”的对照、或用户明确要求时才修改。
- **参考优先**：实现 / 修改 UI 前先阅读 `prototype/src` 对应源码作为设计基准（第三章）。
- **验证**：Flutter 改动后必须通过 `flutter analyze`（零错误）与 `flutter test`；必要时 `flutter run` 目视确认。uni-app 改动（如真的需要）须通过 `pnpm type-check`。

### 7.2 多任务拆分

独立任务可用子智能体并行（各任务自包含、写明文件路径与验收命令）；共享状态的改动按顺序串行，避免覆盖。

---

## 八、关键文档索引

| 文档 | 路径 | 用途 |
|---|---|---|
| PRD | `docs/superpowers/specs/2026-08-17-whitenoise-app-prd.md` | 产品需求规格 |
| 设计基线 | `docs/superpowers/specs/2026-08-17-whitenoise-app-design.md` | 品牌 / 视觉设计体系 |
| iOS 重设计 | `docs/superpowers/specs/2026-09-07-whitenoise-ios-redesign.md` | iOS 设计语言规范 |
| 首页重设计 | `docs/superpowers/specs/2026-09-07-homepage-redesign-design.md` | 首页布局 / 内容 / 交互 |
| 音频组件 | `docs/superpowers/specs/2026-09-07-html-audio-components-design.md` | 播放器 / 混音组件规格 |
| 场景页个性化 | `docs/superpowers/specs/2026-09-08-scene-page-personalization-design.md` | 场景页个性化设计 |
| 场景页 iOS 改版 | `docs/superpowers/specs/2026-09-08-scene-page-ios-redesign-design.md` | 场景页 iOS 化改版 |
| 设计系统 v2 | `docs/design-system/MASTER.md` | 全界面 redesign 单一事实来源（v2 token / 组件 / IA） |
| 原型 v2 落地 | `docs/superpowers/specs/2026-09-16-prototype-v2-implementation-design.md` | 原型 v2 全量落地实施设计 |
| Flutter 全功能实现（spec） | `docs/superpowers/specs/2026-09-17-flutter-app-features-design.md` | Flutter 工程全功能实现设计 |
| Flutter 全功能实现（plan） | `docs/superpowers/plans/2026-09-17-flutter-app-features.md` | T1-T9 逐任务实施计划 |
| Flutter 全面优化（spec） | `docs/superpowers/specs/2026-09-19-flutter-optimization-design.md` | 五阶段加固（测试/修复/架构/响应式/UI）设计 |
| 代码维基 | `docs/code-wiki/whitenoise-code-wiki.md` | 代码结构 / 约定速查 |
| 白噪音素材调研 | `docs/audio-resources-research.md` | 公开可商用音频来源 / 授权 / 落地建议 |
| 项目规则 | `.trae/rules/project_rules.md` | TRAE IDE 行为规则 |

> **维护要求**：新增 / 重命名 / 删除文档时，同步更新本表（本文件）。

---

## 九、文档同步规则

> 文档是单一事实来源。**工程或文档变更后，须同步回 AGENT.md 及相关文档**，保证地图与实际状态一致。

- 新增 / 删除 / 重命名文档 → 更新第八章「关键文档索引」。
- 新增 / 修改页面路由、组件树、Service / Store / 数据层函数 → 更新对应设计文档与 AGENT.md 相应章节。
- 修改设计 Token / 品牌视觉 / UI 风格 → 更新设计基线文档 + 第三章 / 第四章。
- 修改目录结构、编码约定、工作流 → 更新本文件第二 / 三 / 四 / 七章。
- 任何对 AGENT.md 的修改，同步更新文件头部「最后更新」日期。

---

> **本文件是项目的开发宪法，AI/开发者在每次会话中须优先加载并遵循。**