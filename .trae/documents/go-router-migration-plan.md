# 路由迁移计划：命名路由 → go_router 6.5.2

## Context

用户要求改用「性能最高的路由库」。当前 `snapp/lib/app/router.dart` 为手写命名路由 map（19 条）+ `onGenerateRoute`，页面间用 `Navigator.pushNamed` + `ModalRoute.arguments` 传参。

**选型结论：go_router 6.5.2**（Flutter 官方出品，flutter.dev 发布者）。理由（已查证）：

- **Harmony 适配校验（AGENTS.md 5.2 已履行）**：go_router 为纯 Dart 包（依赖仅 collection/logging/meta，无平台通道、无原生代码），OpenHarmony 适配清单只收录含原生实现的插件，纯 Dart 包直接跑在 OHOS Flutter 引擎上，无 MissingPluginException / 构建失败风险。
- **版本兼容（硬约束）**：工程 SDK `>=2.19.6 <3.0.0`（Flutter 3.7.12-ohos 分支）。go_router 7.x+ 要求 Dart 3 不可用；6.5.2 约束 `sdk >=2.18.0 <4.0.0 / flutter >=3.3.0`，完全兼容，为 Dart 2.19 下可用的最新版。
- **性能**：底层仍是 Navigator（零额外转场开销）；顶层路由匹配 O(1)；4 个 tab 继续用 IndexedStack 保活（切 tab 零重建）。实际收益：声明式路由表、路径参数类型安全、天然深链能力、redirect 守卫。

**6.5.2 API 注意点（与新版不同，勿凭新版记忆写）**：
- 路径参数：`state.params['sceneId']`（不是 `pathParameters`，那是 7.x+ 改名）
- 查询参数：`state.queryParams['category']`
- redirect 签名：`String? Function(GoRouterState state)`（单参数，6.0+ 设计）
- `GoRouterState.of(context)` 可用；`context.push/go/pop` 扩展可用

## 设计决策

1. **4 个 tab 页不走路由**：保留 `_Shell`（IndexedStack + 悬浮 AppTabBar）+ `ShellTabNotifier`，对应原型 `uni.switchTab` 语义且是最高性能的 tab 保活方案（go_router 6.x 无 StatefulShellRoute，7.x+ 才有且我们用不了）。`/index` `/scene` `/discover` `/mine` 4 个命名路由从表中移除；原「清栈回首页」语义改为 `context.go('/')` + `ShellTabNotifier.go(0)`。
2. **参数改路径/查询参数**（可深链、类型安全）：
   - `/scene-detail/:sceneId`
   - `/scene-edit/:sceneId`（`new` = 新建模式）
   - `/scene-all`（查询参数 `?category=sleep`）
   - 其余 12 条无参路由保持纯路径。
3. **转场保真**：
   - 普通页面：`MaterialPage`（go_router 默认，等同现 MaterialPageRoute 转场，无需自定义）。
   - `/player`：用 `CustomTransitionPage` 复刻现 `play_bar.dart` 中 `_playerRoute()` 的 320ms 底部滑入 + 淡入转场，转场定义迁入 router.dart，PlayBar 改为 `context.push('/player')`。
4. **Onboarding 守卫**：`redirect` + `refreshListenable`。新建轻量 `OnboardNotifier extends ChangeNotifier`（router.dart 内），`redirect: !_onboarded && location != '/onboarding' → '/onboarding'`。完成后写 `shengqi-onboarded` 标记 + notify。`OnboardingPage.onDone` 改必传（Root 构建路由时注入）。
5. **返回/兜底**：go_router push 的页面就在根 Navigator 栈上，`Navigator.of(context).canPop()/pop()` 原样保留；仅把兜底 `pushNamedAndRemoveUntil('/index', ...)` 改为 `context.go('/')`。

## 改动文件清单

### 1. `snapp/pubspec.yaml`
`dependencies` 新增（含 Harmony 校验注释）：
```yaml
  # 声明式路由（Flutter 官方）。纯 Dart 包无平台通道，OHOS 直接可用
  # （适配清单仅收录原生插件）。锁 6.5.2：7.x+ 要求 Dart 3，工程 SDK 2.19。
  go_router: 6.5.2
```

### 2. `snapp/lib/app/router.dart`（重写）
- `GoRouter buildRouter({required ValueNotifier<bool> onboarded, required VoidCallback onOnboardDone})`：
  - `redirect`：未引导 → `/onboarding`；`/onboarding` 路由 builder 调 `onOnboardDone` 后写存储。
  - 路由表：
    - `/` → `_Shell`（从 app.dart 私有类改为 router.dart 可见，或路由 builder 引 app.dart 导出的 Shell；取「_Shell 改为公开 ShellWidget 导出」方案）
    - `/onboarding`、`/library`、`/theme`、`/achievement`、`/invite`、`/settings`、`/checkin`、`/stats`、`/favorites`、`/history`
    - `/scene-all`（读 `state.queryParams['category']`）
    - `/scene-detail/:sceneId`、`/scene-edit/:sceneId`
    - `/player` → `CustomTransitionPage`（迁入 _playerRoute 的转场参数）
- 移除 `buildRoutes()` / `onGenerateRoute`。

### 3. `snapp/lib/app/app.dart`
- `Root`：`MaterialApp` → `MaterialApp.router(routerConfig: _router, theme: ...)`；删除 `home` 切换与 `_onboarded` setState 逻辑（改为持有 `ValueNotifier<bool> _onboarded` 传给 router；`_finishOnboarding` 只写存储 + notifier 更新）。
- `_Shell` 保留原样（IndexedStack + PlayBar + AppTabBar）。

### 4. 调用点迁移（模式统一：`Navigator.pushNamed(context, '/x', arguments: {...})` → `context.push('/x/...')`；需在文件头引入 `package:go_router/go_router.dart`）

| 文件 | 改动 |
|---|---|
| `pages/index/index_page.dart` | `_openDetail` → `push('/scene-detail/${scene.id}')`；Banner 分支 `/scene-detail`+sceneId → 拼 path，其余 `b.route!` → `push(b.route!)` |
| `pages/discover/discover_page.dart` | `_goDetail` 同上；`/scene-all`（L146）；`/theme`(L255)、`/library`(L260) |
| `pages/scene/scene_page.dart` | `_openDetail`(L71)；`/scene-all`(L220)；`/theme`(L385)；`/scene-edit` L420(`new`)/L428(编辑) → `push('/scene-edit/${id}')` |
| `pages/scene-all/scene_all_page.dart` | `_openDetail`(L51) |
| `pages/scene-detail/scene_detail_page.dart` | `_editScene`(L239) → `push('/scene-edit/$_sceneId')` |
| `pages/mine/mine_page.dart` | `_go`(L26) → `context.push(route)`（13 处 route 值不变） |
| `pages/player/player_page.dart` | L37 兜底 → `context.go('/')`；L109 → `context.push('/library')` |
| `pages/onboarding/onboarding_page.dart` | `onDone` 改必传参数；删除 `_goHome` 的 pushNamedAndRemoveUntil 分支 |
| `pages/settings/settings_page.dart` | L299 `/theme` |
| `widgets/brand_bar.dart` | L61 `/theme`、L66 `/achievement` |
| `widgets/play_bar.dart` | 删 `_playerRoute()`；L83 → `context.push('/player')` |
| `widgets/nav_bar.dart` | L21 兜底 → `context.go('/')`（canPop/pop 保留 Navigator） |

### 5. 读参数页改造（`ModalRoute.arguments` → `GoRouterState`）
- `scene_detail_page.dart`（L36）：builder 内 `GoRouterState.of(context).params['sceneId']`，回退逻辑不变。
- `scene_all_page.dart`（L31）：`GoRouterState.of(context).queryParams['category']`，仅 `_activeTag == 'all'` 时应用，逻辑不变。
- `scene_edit_page.dart`（L48）：`params['sceneId']`，`new`/空 → 新建模式，逻辑不变。

### 6. 测试适配
- `test/widget_test.dart`：`_buildRoot()` pump `Root` 不变（内部已换 router）；L78 测试单独 pump `OnboardingPage()` 需补 `onDone: () {}`（参数改必传）。
- 其余 13 个测试文件不涉及路由，无需改动。

### 7. 文档同步（AGENTS.md 第九章要求）
- `.trae/rules/` 无需动；更新 `AGENTS.md`：5.2 节补 go_router 校验记录、5.3 节「路由：使用命名路由」→「go_router 声明式路由（6.5.2），4 tab 走 IndexedStack 壳」、头部「最后更新」日期。
- `docs/code-wiki/whitenoise-code-wiki.md` 若含路由章节则同步一句（实施时确认）。

## 验证

1. `cd snapp && flutter pub get` — 依赖解析成功（确认 go_router 6.5.2 无传递依赖冲突）。
2. `flutter analyze` — 零错误零警告（项目验收标准）。
3. `flutter test` — 全绿（当前基线 73 项）。
4. 关键路径人工核对（代码走查）：scene-detail 深链 path 参数、scene-all category 回填、scene-edit new/edit 双模式、PlayBar → /player 转场、onboarding redirect 守卫、NavBar 兜底返回。
5. 三平台构建验证属既有待办（需本地 OH SDK），本次不新增范围。
