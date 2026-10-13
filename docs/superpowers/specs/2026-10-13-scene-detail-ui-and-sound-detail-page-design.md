# 场景详情页 UI 优化 + 声音详情页 设计

> 日期：2026-10-13
> 状态：已与用户对齐（布局照参考图、颜色走主题 token；声音详情页「页面化 + 真实播放」）
> 关联参考：用户提供的「场景详情页」设计稿（蓝灰底 + 明黄下划线参考图，仅取布局结构，不取配色）

---

## 一、背景与目标

1. **场景详情页**（`snapp/lib/pages/scene-detail/scene_detail_page.dart`）当前为通栏渐变 Hero，与参考设计的「浮动圆角大卡 + 光晕」气质有差距；声音配方条、故事卡等视觉细节偏朴素。
2. **声音详情**当前是音疗库（`library_page.dart`）内的底部弹层 `_SoundDetailSheet`，且「播放 / 加入混音」两个按钮均为 toast 假动作，违反项目规则「未完成功能要么实现要么移除」。

目标：

- A. 场景详情页 Hero 改为浮动圆角卡，配方条 / 故事卡 / 间距精修（仅视觉层，逻辑不动）。
- B. 新增独立声音详情页 `/sound/:soundId`，替换音疗库弹层；`PlayerService` 补 `playSound` / `addTrack` 使按钮真实生效。
- C. 场景详情页声音配方条目可点击，跳转对应声音详情页（场景↔声音闭环）。

## 二、范围

**In：**
- `scene_detail_page.dart` 视觉改造 + 配方条目点击联动
- 新增 `snapp/lib/pages/sound-detail/sound_detail_page.dart`
- `snapp/lib/app/router.dart` 新增 `/sound/:soundId`
- `snapp/lib/services/player_service.dart` 新增 `playSound` / `addTrack` / `displayScene`
- `snapp/lib/widgets/app_page.dart`、`snapp/lib/app/shell.dart` PlayBar 可见性条件调整
- `snapp/lib/widgets/play_bar.dart` 标题回退
- `snapp/lib/pages/library/library_page.dart` 入口改跳页、删除 `_SoundDetailSheet` 与 `_MetaRow`
- 单元测试 / Widget 测试补充

**Out（本次不做）：**
- 声音收藏（FavoritesService 仅场景维度，弹层亦无此功能）
- 声音详情页「相关场景」推荐区
- 试听按钮的播放/暂停态切换（固定为「重新开始试听」）
- 参考图配色（明黄下划线、蓝灰底）——一律走 `AppColors` token

## 三、A：场景详情页 UI 优化

改动仅限 `scene_detail_page.dart` 的视觉层；`_onHeroPlay` / 定时 / 混音 Sheet 逻辑不动。

| 区块 | 现状 | 改为 |
|---|---|---|
| Hero 容器 | 通栏贴边，仅底部 24 圆角 | 水平 margin 20、**四角 28 圆角浮动大卡**，保留 `scene.gradient` 渐变底，`c.shadow3` 投影 |
| 图标 | 120 圆形白色 18% 底 | 保留圆底，**外圈加光晕**（on-cover 半透明白双层 BoxShadow，对照参考图月晕） |
| 播放钮 | 88 圆钮渐变 + shadow3 | 光晕增强：外圈 `c.primarySoft` glow + 保留渐变钮与 shadow3 |
| 声音配方条 | 高 6 纯色填充 | 高 8、`BorderRadius.circular(999)`，填充用该声音 `gradient`（`parseCssGradient`）渐变；图标包小圆底（`c.primarySoft`） |
| 配方条目交互 | 不可点 | **整行 `PressableScale` 点击 → `context.push('/sound/<soundId>')`**（配方项含 soundId 字段则直接用；若 `RecipeItem` 无 id，从 `scene.soundIds[i]` 对应取） |
| 场景故事卡 | 纯引号文本卡 | 左侧 `c.primarySoft` 竖条 + 引号装饰（对照参考图引用卡），文本样式不变 |
| 分区节奏 | 各区 margin 不一 | 分区纵向间距收敛为一套固定值（分区顶部 / 卡片间距各取一个定值，按参考图比例实施），不再各区各异 |

约束：
- Hero 内白色半透明蒙层为 on-cover 语境（现有做法，原型有 `--app-on-cover`），保留但优先用 `c.onCover` / `c.onCoverSoft` 表达。
- 禁止新增任何硬编码色值 / 圆角 / 阴影；圆角、间距数值与既有卡片语言一致（22/28/999）。

## 四、B：声音详情页

### 4.1 路由

`router.dart` 增加（对照 `/scene-detail/:sceneId` 模式）：

```dart
GoRoute(path: '/sound/:soundId', builder: (_, __) => const SoundDetailPage()),
```

页面经 `GoRouterState.of(context).params['soundId']` 取参，`player.findSound(id)` 查数据；查不到回退 `sounds.first`（对照 `findScene` 回退惯例）。

### 4.2 页面结构（`snapp/lib/pages/sound-detail/sound_detail_page.dart`）

```
AppPage(bottomBarSpace: true, padding: LTRB(0, 12, 0, 28))
└─ SingleChildScrollView
   ├─ NavBar('声音详情')
   ├─ _SoundHero    // 浮动圆角卡（与场景详情 Hero 同视觉语言）：
   │                //   sound.gradient 渐变底 + 图标圆底光晕 + name + type + desc
   ├─ 分区「规格参数」 _SpecCard   // 时长/采样率/音质/循环片段/来源 五行表（迁自弹层 _MetaRow）
   ├─ 分区「适用场景」 _TagsCard   // primarySoft 胶囊 Wrap（迁自弹层）
   └─ 分区「」       _ActionRow   // 试听（主钮）+ 加入混音（次钮）
```

- Hero 视觉规格与 A 部分场景详情 Hero 一致（浮动圆角 28、图标光晕），仅尺寸按声音维度收敛（图标圆底 96、无播放钮）。
- 订阅策略：仅 `context.select` 取 `isPlaying`、`tracks`（判断「已在混音中」），避免整页随播放器通知重建。

### 4.3 交互

| 按钮 | 行为 |
|---|---|
| 试听（主钮，`c.primary` 实底） | `player.playSound(sound)` + toast「正在试听 <名称>」 |
| 加入混音（次钮，描边） | `player.addTrack(sound)`：成功 → toast「已加入混音」；已在混音中 → 按钮呈**已加入态**（置灰 +「已在混音中」，不可点）；超上限 → toast「最多支持 6 路混音」 |

「已在混音中」判定：`tracks.any((t) => t.id == sound.id)`（select 订阅 tracks）。

## 五、PlayerService 增强

```dart
static const int maxMixTracks = 6;

/// 单曲试听：重建为单轨播放；不写最近记录 / 统计（试听不算场景播放）。
void playSound(Sound s) {
  currentScene = null;                 // 关键：退出场景语境
  tracks = [PlayerTrack(id: s.id, name: s.name, iconName: s.iconName, color: s.color)];
  if (tracks.length > maxTrackCount) maxTrackCount = tracks.length;
  isPlaying = true;
  unawaited(_engine.disposeAll());
  unawaited(_engine.loadTrack(s.id, audioAssetFor(s.id)));
  unawaited(_engine.play());
  unawaited(BackgroundTask.start());
  notifyListeners();
}

/// 追加一轨；已在混音 / 达上限返回 false，由调用方 toast。
bool addTrack(Sound s) {
  if (tracks.any((t) => t.id == s.id)) return false;
  if (tracks.length >= maxMixTracks) return false;
  tracks = List<PlayerTrack>.of(tracks)..add(PlayerTrack(id: s.id, name: s.name,
      iconName: s.iconName, color: s.color));
  if (tracks.length > maxTrackCount) maxTrackCount = tracks.length;   // 6 路成就依赖
  unawaited(_engine.loadTrack(s.id, audioAssetFor(s.id)));
  if (!isPlaying) {
    isPlaying = true;
    unawaited(_engine.play());
    unawaited(BackgroundTask.start());
  }
  notifyListeners();
  return true;
}
```

### 5.1 `currentScene == null` 影响面（必须逐一处理）

| 位置 | 现状 | 处理 |
|---|---|---|
| `player_service.dart` | — | 新增计算 getter `Scene? get displayScene`：`currentScene ?? (tracks 非空时由首轨声音合成展示用 Scene)`（仅展示，不入库、不写 recent） |
| `app_page.dart:35` / `shell.dart:42` | PlayBar 可见性 = `currentScene != null` | 改为 `tracks.isNotEmpty`（有音轨即显示，试听不丢播放条） |
| `play_bar.dart:48` | 标题 = `currentScene?.name` | 改用 `displayScene?.name`（试听时显示声音名），无音轨回退空串 |
| `player_page.dart:47-97` | `currentScene == null` → 空态「去音疗库」 | select 改用 `displayScene`；`displayScene == null` 才显示空态 |
| `media_bridge.dart:95` | AVSession 元数据读 `currentScene` | 改用 `displayScene`（试听时通知栏显示声音名；实施时核对该文件空值分支） |
| 场景高亮判断（index/scene/discover/scene-all/scene-detail 的 `currentSceneId`） | `currentScene?.id` | **不改**：试听后所有场景不再误亮「播放中」，语义正确 |

## 六、音疗库入口改造（`library_page.dart`）

- `_openDetail(sound)` 改为 `context.push('/sound/${sound.id}')`。
- 删除 `_SoundDetailSheet`、`_MetaRow`（约 240 行死代码）。
- `SoundCard` 组件不动。

## 七、测试与验收

**新增单测**（`test/` 下对应文件）：
1. `playSound`：tracks 重建为单轨、`currentScene` 置 null、`isPlaying` 为 true、不写 `recent`。
2. `addTrack`：成功追加 / 重复返回 false / 第 7 轨返回 false / `maxTrackCount` 随之累加（成就依赖）。
3. `displayScene`：currentScene 为 null 且有音轨时返回合成场景。

**Widget 测试**：
4. `SoundDetailPage` 渲染：名称 / 规格五行 / 场景标签可见；已加入混音态呈禁用文案；点试听后 PlayerService.tracks 长度为 1。
5. 路由：`/sound/rain` 正常解析（若既有路由测试存在则跟随其模式）。

**回归**：
- `flutter analyze` 零错误；`flutter test` 全绿（现 99 项 + 新增）。
- 目视验证：场景详情 Hero 浮动卡在 6 配色 × 3 UI 风格下无硬编码残留、无混搭。

## 八、文档同步

- AGENTS.md：头部「最后更新」日期；5.7 已知待办追加一条「声音详情页为 Flutter 侧新增页面（无原型对应页），路由 `/sound/:soundId`」。
- 本 spec 提交 git。
