# 场景详情页 UI 优化 + 声音详情页 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 场景详情页 Hero 改为浮动圆角卡并精修配方条/故事卡 + 新增独立声音详情页（`/sound/:soundId`，试听/加入混音真实生效）并替换音疗库底部弹层。

**Architecture:** 视觉层改造集中在 `scene_detail_page.dart`；声音详情页复用既有 `AppPage/NavBar/AppCard/AppIcon/PressableScale` 组件语言；`PlayerService` 新增 `playSound`/`addTrack`/`displayScene`，并把 PlayBar 可见性从「有场景」改为「有音轨」，使单曲试听不丢播放条、不误亮场景高亮。

**Tech Stack:** Flutter (Dart 2.19.6) + go_router 6.5.2 + provider + flutter_test。

**Spec:** `docs/superpowers/specs/2026-10-13-scene-detail-ui-and-sound-detail-page-design.md`

## Global Constraints

- Dart 2.19.6 兼容：禁止 record / switch 表达式等 3.0 语法；`super.key` 可用。
- go_router 6.5.2：取参用 `GoRouterState.of(context).params['xxx']`（不是 `pathParameters`）。
- **禁止硬编码颜色/圆角/阴影**：颜色一律 `Theme.of(context).appColors`（AppColors token）；圆角沿用 22/28/999；阴影用 `c.shadow1..4`。例外：Hero 渐变底上的白色半透明蒙层（on-cover 语境，沿用现状写法 `Colors.white.withOpacity(...)`）。
- 图标只用 `AppIcon` 已定义名（play/pause/timer/shuffle/mixer/check/heart/share/edit/close/wave 等，**不新增图标引用**）。
- 所有工作在 `snapp/` 目录下执行；验证命令：`flutter analyze`（零错误）、`flutter test`（全绿）。
- PowerShell 不支持 `&&`，链式命令用 `;`。
- 音频引擎测试统一用 `SimulatedAudioEngine()`（无插件依赖）。

---

### Task 1: PlayerService 增强（playSound / addTrack / displayScene / maxMixTracks）

**Files:**
- Modify: `snapp/lib/services/player_service.dart`
- Test: `snapp/test/player_service_test.dart`

**Interfaces:**
- Consumes: 既有 `PlayerService(engine:)` 构造、`findSound(String id)`、`PlayerTrack(id/name/iconName/color)`、`audioAssetFor(id)`、`BackgroundTask.start()`、`_engine.disposeAll/loadTrack/play`。
- Produces（后续任务依赖）：
  - `static const int maxMixTracks = 6`
  - `void playSound(Sound s)` — 单轨重建、`currentScene = null`、开始播放、不写 recent/统计
  - `bool addTrack(Sound s)` — 追加一轨；重复/超限返回 false
  - `Scene? get displayScene` — `currentScene ?? 首轨声音合成展示 Scene`

- [ ] **Step 1: 写失败测试**（追加到 `snapp/test/player_service_test.dart`，在文件顶部 import 区加入：）

```dart
import 'package:snapp/data/sound_models.dart';
import 'package:snapp/data/seed_data.dart';
```

在 `main()` 内追加：

```dart
  test('playSound rebuilds single track and clears currentScene', () {
    final player = buildPlayer();
    player.applyScene(findScene('deep-sleep'));
    expect(player.currentScene, isNotNull);
    player.playSound(player.findSound('rain')!);
    expect(player.currentScene, isNull);
    expect(player.tracks.length, 1);
    expect(player.tracks.first.id, 'rain');
    expect(player.isPlaying, isTrue);
  });

  test('playSound does not write recent', () {
    final player = buildPlayer();
    player.applyScene(findScene('deep-sleep'));
    final recentBefore = player.recent.length;
    player.playSound(player.findSound('rain')!);
    expect(player.recent.length, recentBefore);
  });

  test('displayScene falls back to synthesized scene from first track', () {
    final player = buildPlayer();
    expect(player.displayScene, isNull);
    player.playSound(player.findSound('rain')!);
    final display = player.displayScene;
    expect(display, isNotNull);
    expect(display!.id, 'sound-rain');
    expect(display.name, '雨声');
    expect(player.currentScene, isNull);
  });

  test('addTrack appends distinct track and dedups', () {
    final player = buildPlayer();
    player.applyScene(findScene('deep-sleep'));
    final extra = sounds.firstWhere(
        (Sound s) => !player.tracks.any((PlayerTrack t) => t.id == s.id));
    final countBefore = player.tracks.length;
    expect(player.addTrack(extra), isTrue);
    expect(player.tracks.length, countBefore + 1);
    expect(player.tracks.last.id, extra.id);
    expect(player.addTrack(extra), isFalse);
  });

  test('addTrack enforces maxMixTracks limit of 6', () {
    final player = buildPlayer();
    player.playSound(sounds.first);
    for (final Sound s in sounds.skip(1)) {
      if (player.tracks.length >= 6) break;
      player.addTrack(s);
    }
    expect(player.tracks.length, 6);
    final seventh = sounds.firstWhere(
        (Sound s) => !player.tracks.any((PlayerTrack t) => t.id == s.id));
    expect(player.addTrack(seventh), isFalse);
    expect(player.tracks.length, 6);
  });

  test('addTrack bumps maxTrackCount (achievement dependency)', () {
    final player = buildPlayer();
    player.playSound(sounds.first);
    expect(player.maxTrackCount, 1);
    final extra = sounds.firstWhere(
        (Sound s) => !player.tracks.any((PlayerTrack t) => t.id == s.id));
    player.addTrack(extra);
    expect(player.maxTrackCount, 2);
  });
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/player_service_test.dart`（cwd: `d:\app\projects\whitenoise\snapp`）
Expected: 编译失败 / FAIL，报 `playSound`、`addTrack`、`displayScene`、`maxMixTracks` 未定义。

- [ ] **Step 3: 实现**（`snapp/lib/services/player_service.dart`）

在 `int maxTrackCount = 0;`（约 L105）之后加：

```dart
  /// 混音上限（MixSheet「/6 路」徽标与 6 路成就同源）。
  static const int maxMixTracks = 6;
```

在 `applyScene` 方法（L135-161）之后加：

```dart
  /// 单曲试听：重建为单轨播放；不写最近记录 / 统计（试听不算场景播放），
  /// currentScene 置 null 退出场景语境（展示层回退见 displayScene）。
  void playSound(Sound s) {
    currentScene = null;
    tracks = <PlayerTrack>[
      PlayerTrack(id: s.id, name: s.name, iconName: s.iconName, color: s.color),
    ];
    if (tracks.length > maxTrackCount) maxTrackCount = tracks.length;
    isPlaying = true;
    unawaited(_engine.disposeAll());
    unawaited(_engine.loadTrack(s.id, audioAssetFor(s.id)));
    unawaited(_engine.play());
    unawaited(BackgroundTask.start());
    notifyListeners();
  }
```

在 `removeTrack` 方法（L207-216）之后加：

```dart
  /// 追加一轨；已在混音或达 [maxMixTracks] 上限时返回 false，由调用方 toast 提示。
  bool addTrack(Sound s) {
    for (final PlayerTrack t in tracks) {
      if (t.id == s.id) return false;
    }
    if (tracks.length >= maxMixTracks) return false;
    tracks = List<PlayerTrack>.of(tracks)
      ..add(PlayerTrack(id: s.id, name: s.name, iconName: s.iconName, color: s.color));
    if (tracks.length > maxTrackCount) maxTrackCount = tracks.length;
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

在 `currentScene` 字段声明（L82）之后加 getter：

```dart
  /// 展示用场景：无当前场景但有音轨（如单曲试听）时，由首轨声音合成一个
  /// 仅用于展示的 Scene（不入库、不写最近/统计，id 前缀 sound- 不会命中 findScene）。
  Scene? get displayScene {
    final Scene? current = currentScene;
    if (current != null) return current;
    if (tracks.isEmpty) return null;
    final String id = tracks.first.id;
    final Sound? s = findSound(id);
    return Scene(
      id: 'sound-$id',
      name: s?.name ?? tracks.first.name,
      category: '',
      desc: s?.desc ?? '',
      iconName: tracks.first.iconName,
      gradient: s?.gradient ?? '',
      image: '',
      soundIds: <String>[id],
      isPreset: false,
    );
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/player_service_test.dart`
Expected: 全部 PASS（含既有用例）。

- [ ] **Step 5: Commit**

```bash
git add snapp/lib/services/player_service.dart snapp/test/player_service_test.dart
git commit -m "feat: PlayerService 新增单曲试听 playSound 与追加混音 addTrack"
```

---

### Task 2: currentScene==null 影响面（PlayBar 可见性 / 标题回退 / 播放页 / 媒体桥接）

**Files:**
- Modify: `snapp/lib/widgets/app_page.dart:33-40`（reservedBottomInset）
- Modify: `snapp/lib/app/shell.dart:41-42`（showPlayBar）
- Modify: `snapp/lib/widgets/play_bar.dart:47-48`（sceneName）
- Modify: `snapp/lib/pages/player/player_page.dart:47-48`（currentScene select）
- Modify: `snapp/lib/services/media_bridge.dart:94-107`（_snapshotOf）
- Test: `snapp/test/media_bridge_test.dart`（新增试听快照用例）

**Interfaces:**
- Consumes: Task 1 的 `displayScene` getter。
- Produces: PlayBar 可见性 = `tracks.isNotEmpty`；播放页/PlayBar/通知栏元数据经 `displayScene` 回退到声音名。

- [ ] **Step 1: 写失败测试**（`snapp/test/media_bridge_test.dart`，在 `group('状态下行（快照推送）')` 内追加；rain 渐变为 `linear-gradient(135deg, #9AABC0, #667C91)`）

```dart
    test('playSound 后快照标题回退声音名（displayScene）', () async {
      final player = PlayerService(engine: SimulatedAudioEngine());
      MediaBridge().attach(player);
      await pumpEventQueue();
      updates.clear();

      player.playSound(player.findSound('rain')!);
      await pumpEventQueue();

      expect(updates.length, 1);
      final args = updates.single;
      expect(args['title'], '雨声');
      expect(args['artist'], '雨声');
      expect(args['isPlaying'], isTrue);
      // 试听无真实场景：场景恢复 id 保持空串（不指向合成场景）。
      expect(args['sceneId'], '');
      expect(args['color1'], '#9AABC0');
      expect(args['color2'], '#667C91');
    });
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/media_bridge_test.dart`
Expected: 新用例 FAIL（title 为 '声栖' 而非 '雨声'，color 为回退品牌色）。

- [ ] **Step 3: 实现**

`snapp/lib/widgets/app_page.dart` L34-35 改为（注释同步改）：

```dart
    final bool showPlayBar = context.select<PlayerService, bool>(
        (PlayerService p) => p.tracks.isNotEmpty);
```

`snapp/lib/app/shell.dart` L41-42 改为：

```dart
    final showPlayBar = context.select<PlayerService, bool>(
        (PlayerService p) => p.tracks.isNotEmpty);
```

`snapp/lib/widgets/play_bar.dart` L47-48 改为：

```dart
    final sceneName = context.select<PlayerService, String?>(
        (PlayerService p) => p.displayScene?.name);
```

`snapp/lib/pages/player/player_page.dart` L47-48 改为：

```dart
    final currentScene = context.select<PlayerService, Scene?>(
        (PlayerService p) => p.displayScene);
```

`snapp/lib/services/media_bridge.dart` `_snapshotOf`（L94-107）改为：

```dart
  _MediaSnapshot _snapshotOf(PlayerService player) {
    // 展示元数据走 displayScene（试听回退声音名/声音渐变）；
    // sceneId 仍取真实 currentScene：试听无场景，供卡片恢复时回退。
    final scene = player.displayScene;
    final hasTracks = player.tracks.isNotEmpty;
    return _MediaSnapshot(
      title: scene?.name ?? '声栖',
      artist: hasTracks
          ? player.tracks.map((PlayerTrack t) => t.name).join(' · ')
          : '白噪音 · 混音助眠',
      isPlaying: hasTracks && player.isPlaying,
      color1: _gradientColor(scene?.gradient, 0, _fallbackColor1),
      color2: _gradientColor(scene?.gradient, 1, _fallbackColor2),
      sceneId: player.currentScene?.id ?? '',
    );
  }
```

- [ ] **Step 4: 运行相关测试确认通过**

Run: `flutter test test/media_bridge_test.dart test/play_bar_test.dart test/player_service_test.dart`
Expected: 全部 PASS（既有「空闲快照 title=声栖」「无场景 PlayBar 不显示」不受影响——无音轨时 displayScene 为 null）。

- [ ] **Step 5: Commit**

```bash
git add snapp/lib/widgets/app_page.dart snapp/lib/app/shell.dart snapp/lib/widgets/play_bar.dart snapp/lib/pages/player/player_page.dart snapp/lib/services/media_bridge.dart snapp/test/media_bridge_test.dart
git commit -m "feat: PlayBar 可见性改按音轨判定，试听态标题/通知栏回退声音名"
```

---

### Task 3: 声音详情页 + 路由 + 音疗库入口改造

**Files:**
- Create: `snapp/lib/pages/sound-detail/sound_detail_page.dart`
- Modify: `snapp/lib/app/router.dart`（import + 路由表，插在 `/scene-edit/:sceneId` 之后）
- Modify: `snapp/lib/pages/library/library_page.dart`（_openDetail 改跳页；删除 `_SoundDetailSheet` 与 `_MetaRow` 两个类）
- Test (Create): `snapp/test/sound_detail_page_test.dart`

**Interfaces:**
- Consumes: Task 1 `playSound/addTrack/maxMixTracks`；既有组件 `AppPage(bottomBarSpace, padding)`、`NavBar(title:)`、`AppCard(padding, child)`、`AppSectionTitle(title)`、`AppIcon(name, size, color)`、`PressableScale(onTap: VoidCallback?, scale)`、`showAppToast(context, msg)`、`parseCssGradient(String)/hexToColor(String)`（style_utils）、`PlayerService.findSound(id)`、`sounds`（seed_data）。
- Produces: 路由 `/sound/:soundId`（Task 4 配方联动跳转目标）。

- [ ] **Step 1: 写失败测试**（新建 `snapp/test/sound_detail_page_test.dart`）

```dart
// 声栖 · 声音详情页测试：渲染 / 试听 / 加入混音与已加入态。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:snapp/pages/sound-detail/sound_detail_page.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/theme/app_theme.dart';
import 'package:snapp/theme/theme_extension.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, PlayerService player) async {
    final router = GoRouter(
      initialLocation: '/sound/rain',
      routes: <RouteBase>[
        GoRoute(
          path: '/sound/:soundId',
          builder: (_, __) => const SoundDetailPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<PlayerService>.value(
        value: player,
        child: MaterialApp.router(
          theme: buildAppTheme(appColorsFor('morandi', 'flat', Brightness.light)),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders hero, spec rows and scene tags', (WidgetTester tester) async {
    await pumpPage(tester, PlayerService(engine: SimulatedAudioEngine()));

    expect(find.text('声音详情'), findsOneWidget);
    expect(find.text('雨声'), findsOneWidget);
    expect(find.text('自然音'), findsOneWidget);
    expect(find.text('规格参数'), findsOneWidget);
    expect(find.text('时长'), findsOneWidget);
    expect(find.text('60:00'), findsOneWidget);
    expect(find.text('48kHz'), findsOneWidget);
    expect(find.text('无损'), findsOneWidget);
    expect(find.text('实地录音 · 江南雨巷屋檐'), findsOneWidget);
    expect(find.text('适用场景'), findsOneWidget);
    expect(find.text('助眠'), findsOneWidget);
    expect(find.text('试听'), findsOneWidget);
    expect(find.text('加入混音'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap 试听 rebuilds single track via playSound', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await pumpPage(tester, player);

    await tester.tap(find.text('试听'));
    await tester.pump();
    expect(player.tracks.length, 1);
    expect(player.tracks.first.id, 'rain');
    expect(player.currentScene, isNull);
    expect(player.isPlaying, isTrue);
  });

  testWidgets('加入混音 succeeds then shows joined state', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    await pumpPage(tester, player);

    await tester.tap(find.text('加入混音'));
    await tester.pumpAndSettle();
    expect(player.tracks.map((t) => t.id), contains('rain'));
    expect(find.text('已在混音中'), findsOneWidget);
    expect(find.text('加入混音'), findsNothing);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/sound_detail_page_test.dart`
Expected: 编译失败（`sound_detail_page.dart` 不存在）。

- [ ] **Step 3: 创建页面**（`snapp/lib/pages/sound-detail/sound_detail_page.dart`）

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/sound_models.dart';
import '../../data/seed_data.dart';
import '../../services/player_service.dart';
import '../../theme/theme_extension.dart';
import '../../utils/style_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_section.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/nav_bar.dart';
import '../../widgets/pressable.dart';

/// 声音详情页（Flutter 侧新增，无原型对应页）：
/// 浮动渐变 Hero（与场景详情 Hero 同视觉语言）+ 规格参数 + 适用场景 +
/// 试听 / 加入混音（真实生效）。路由 /sound/:soundId。
class SoundDetailPage extends StatefulWidget {
  const SoundDetailPage({super.key});

  @override
  State<SoundDetailPage> createState() => _SoundDetailPageState();
}

class _SoundDetailPageState extends State<SoundDetailPage> {
  String _soundId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 路径参数：/sound/:soundId。
    if (_soundId.isEmpty) {
      _soundId = GoRouterState.of(context).params['soundId'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    // 只订阅「该声音是否已在混音」；其余播放器通知不重建整页。
    final player = context.read<PlayerService>();
    final sound = player.findSound(_soundId) ?? sounds.first;
    final inMix = context.select<PlayerService, bool>(
        (PlayerService p) => p.tracks.any((PlayerTrack t) => t.id == sound.id));

    return AppPage(
      bottomBarSpace: true,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NavBar(title: '声音详情'),
            ),
            _SoundHero(sound: sound),
            _buildSection(c, '规格参数', _SpecCard(sound: sound)),
            _buildSection(c, '适用场景', _TagsCard(sound: sound)),
            _buildSection(c, '', _ActionRow(sound: sound, inMix: inMix)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(AppColors c, String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: AppSectionTitle(title),
            ),
          child,
        ],
      ),
    );
  }
}

/// 浮动渐变 Hero：声音 gradient 底 + 图标圆底光晕 + 名称/类型/描述。
class _SoundHero extends StatelessWidget {
  const _SoundHero({required this.sound});
  final Sound sound;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final g = parseCssGradient(sound.gradient);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        gradient: g == null
            ? null
            : LinearGradient(begin: g.begin, end: g.end, colors: g.colors),
        color: g == null ? c.primary : null,
        borderRadius: BorderRadius.circular(28),
        boxShadow: c.shadow3,
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: Colors.white.withOpacity(0.22),
                    blurRadius: 24,
                    spreadRadius: 8),
                BoxShadow(
                    color: Colors.white.withOpacity(0.10),
                    blurRadius: 52,
                    spreadRadius: 20),
              ],
            ),
            alignment: Alignment.center,
            child: AppIcon(name: sound.iconName, size: 96, color: c.onCover),
          ),
          const SizedBox(height: 14),
          Text(sound.name,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: c.onCover)),
          const SizedBox(height: 4),
          Text(sound.type,
              style: TextStyle(fontSize: 11.5, color: c.onCoverSoft)),
          const SizedBox(height: 10),
          Text(sound.desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, height: 1.6, color: c.onCoverSoft)),
        ],
      ),
    );
  }
}

/// 规格参数五行表（迁自音疗库底部弹层 _MetaRow）。
class _SpecCard extends StatelessWidget {
  const _SpecCard({required this.sound});
  final Sound sound;

  static const List<String> _labels = <String>[
    '时长', '采样率', '音质', '循环片段', '来源',
  ];

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final values = <String>[
      sound.duration, sound.sampleRate, sound.quality, sound.loopLength, sound.source,
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == _labels.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: c.line, width: 0.5)),
              ),
              child: Row(
                children: [
                  Text(_labels[i],
                      style: TextStyle(fontSize: 12, color: c.text2)),
                  const Spacer(),
                  Flexible(
                    child: Text(values[i],
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: c.text)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 适用场景标签（primarySoft 胶囊）。
class _TagsCard extends StatelessWidget {
  const _TagsCard({required this.sound});
  final Sound sound;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: sound.scenes
            .map((String tag) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(tag,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: c.primary)),
                ))
            .toList(),
      ),
    );
  }
}

/// 操作行：试听（主钮）+ 加入混音（次钮，已在混音中呈禁用态）。
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.sound, required this.inMix});
  final Sound sound;
  final bool inMix;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Row(
      children: [
        Expanded(
          child: PressableScale(
            onTap: () {
              context.read<PlayerService>().playSound(sound);
              showAppToast(context, '正在试听 ${sound.name}');
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(999),
                boxShadow: c.shadow1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(name: 'play', size: 20, color: c.onPrimary),
                  const SizedBox(width: 5),
                  Text('试听',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: c.onPrimary)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PressableScale(
            onTap: inMix
                ? null
                : () {
                    final ok = context.read<PlayerService>().addTrack(sound);
                    showAppToast(context, ok ? '已加入混音' : '最多支持 6 路混音');
                  },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: inMix ? c.sunken : null,
                borderRadius: BorderRadius.circular(999),
                border: inMix
                    ? null
                    : Border.all(color: c.primary.withOpacity(0.55)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                      name: inMix ? 'check' : 'mixer',
                      size: 20,
                      color: inMix ? c.text3 : c.primary),
                  const SizedBox(width: 5),
                  Text(inMix ? '已在混音中' : '加入混音',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: inMix ? c.text3 : c.primary)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 注册路由**（`snapp/lib/app/router.dart`）

顶部 import 区加：

```dart
import '../pages/sound-detail/sound_detail_page.dart';
```

`/scene-edit/:sceneId` 路由（L84-87）之后插入：

```dart
        GoRoute(
          path: '/sound/:soundId',
          builder: (_, __) => const SoundDetailPage(),
        ),
```

- [ ] **Step 5: 音疗库入口改造**（`snapp/lib/pages/library/library_page.dart`）

1. 顶部加 import：`import 'package:go_router/go_router.dart';`
2. `_openDetail`（约 L50-56）整段替换为：

```dart
  void _openDetail(Sound sound) {
    context.push('/sound/${sound.id}');
  }
```

3. 删除 `_SoundDetailSheet` 整个类与 `_MetaRow` 整个类（含 sheet 内全部代码）。
4. 删除后运行 `flutter analyze`，按其报告移除 library_page.dart 中不再使用的 import（如 `parseCssGradient`/`showAppToast`/`AppCard` 等仅在弹层使用时才删；其他区域仍在用则保留）。

- [ ] **Step 6: 运行测试确认通过**

Run: `flutter test test/sound_detail_page_test.dart test/scene_edit_page_test.dart`
Expected: 全部 PASS（音疗库搜索用例不受弹层删除影响）。

- [ ] **Step 7: Commit**

```bash
git add snapp/lib/pages/sound-detail/sound_detail_page.dart snapp/lib/app/router.dart snapp/lib/pages/library/library_page.dart snapp/test/sound_detail_page_test.dart
git commit -m "feat: 新增声音详情页（试听/加入混音真实生效），音疗库弹层改为跳页"
```

---

### Task 4: 场景详情页 UI 优化 + 配方条目跳转联动

**Files:**
- Modify: `snapp/lib/pages/scene-detail/scene_detail_page.dart`
- Test (Create): `snapp/test/scene_detail_page_test.dart`

**Interfaces:**
- Consumes: Task 3 的 `/sound/:soundId` 路由；`parseCssGradient`、`PlayerService.findSound`（取声音 gradient 渲染配方条）。
- Produces: 无（纯视觉 + 联动入口）。

**关键事实：** `buildRecipe(scene)` 按 `scene.soundIds` 顺序 1:1 构造（`scene_service.dart:73-85`），故 `recipe[i] ↔ scene.soundIds[i]`，联动直接按下标取 id。

- [ ] **Step 1: 写失败测试**（新建 `snapp/test/scene_detail_page_test.dart`）

```dart
// 声栖 · 场景详情页测试：配方条目点击跳转声音详情（场景↔声音闭环）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:snapp/pages/scene-detail/scene_detail_page.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/favorites_service.dart';
import 'package:snapp/services/player_service.dart';
import 'package:snapp/services/scene_service.dart';
import 'package:snapp/theme/app_theme.dart';
import 'package:snapp/theme/theme_extension.dart';

void main() {
  testWidgets('配方条目点击跳转 /sound/:id', (WidgetTester tester) async {
    final player = PlayerService(engine: SimulatedAudioEngine());
    final router = GoRouter(
      initialLocation: '/scene-detail/deep-sleep',
      routes: <RouteBase>[
        GoRoute(
          path: '/scene-detail/:sceneId',
          builder: (_, __) => const SceneDetailPage(),
        ),
        GoRoute(
          path: '/sound/:soundId',
          builder: (_, __) => const SoundDetailPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<PlayerService>.value(value: player),
          ChangeNotifierProvider<FavoritesService>.value(value: FavoritesService()),
        ],
        child: MaterialApp.router(
          theme: buildAppTheme(appColorsFor('morandi', 'flat', Brightness.light)),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // buildRecipe 首项 = soundIds[0]，配方行文本为声音名。
    final scene = findScene('deep-sleep');
    final firstName = player.findSound(scene.soundIds.first)!.name;
    await tester.tap(find.text(firstName));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.location,
      startsWith('/sound/'),
    );
  });
}
```

（若 `SingleChildWidget` 类型不可用，`providers` 列表直接写 `<ChangeNotifierProvider<PlayerService>>[...]` 换成 `Provider` 的动态列表即可：用 `providers: [ChangeNotifierProvider..., ChangeNotifierProvider...]` 去掉显式泛型。）

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/scene_detail_page_test.dart`
Expected: FAIL——配方行当前不可点，路由 location 仍是 `/scene-detail/deep-sleep`。

- [ ] **Step 3: 实现视觉与联动**（`snapp/lib/pages/scene-detail/scene_detail_page.dart`）

**3.1 Hero 浮动卡**——`_buildHero` 中 Container（约 L143-151）替换为：

```dart
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        gradient: g == null
            ? null
            : LinearGradient(begin: g.begin, end: g.end, colors: g.colors),
        color: g == null ? c.primary : null,
        borderRadius: BorderRadius.circular(28),
        boxShadow: c.shadow3,
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
```

**3.2 图标光晕**——图标 Container（约 L154-163）decoration 替换为：

```dart
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: Colors.white.withOpacity(0.20),
                    blurRadius: 26,
                    spreadRadius: 10),
                BoxShadow(
                    color: Colors.white.withOpacity(0.10),
                    blurRadius: 56,
                    spreadRadius: 22),
              ],
            ),
```

**3.3 播放钮光晕**——播放钮 Container（约 L186-193）的 `boxShadow: c.shadow3` 替换为：

```dart
                    boxShadow: <BoxShadow>[
                      ...c.shadow3,
                      BoxShadow(
                          color: c.primarySoft,
                          blurRadius: 28,
                          spreadRadius: 8),
                    ],
```

**3.4 配方卡改造**——调用处（L74）替换为：

```dart
            _buildSection(
              c,
              '声音配方',
              _RecipeCard(
                recipe: recipe,
                soundIds: scene.soundIds,
                c: c,
                onOpenSound: (String id) => context.push('/sound/$id'),
              ),
            ),
```

`_RecipeCard` 整类替换为：

```dart
class _RecipeCard extends StatelessWidget {
  final List<RecipeItem> recipe;
  final List<String> soundIds;
  final AppColors c;
  final void Function(String soundId) onOpenSound;

  const _RecipeCard({
    required this.recipe,
    required this.soundIds,
    required this.c,
    required this.onOpenSound,
  });

  @override
  Widget build(BuildContext context) {
    // buildRecipe 按 scene.soundIds 顺序 1:1 构造（scene_service.dart），
    // recipe[i] ↔ soundIds[i]，联动按下标取 id。
    final player = context.read<PlayerService>();
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          for (var i = 0; i < recipe.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            PressableScale(
              onTap: () => onOpenSound(soundIds[i]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: AppIcon(
                            name: recipe[i].icon, size: 18, color: c.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(recipe[i].name,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: c.text)),
                      ),
                      Text('${recipe[i].percent}%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.text2)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 8,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Container(color: c.sunken),
                          Builder(builder: (BuildContext context) {
                            final snd = player.findSound(soundIds[i]);
                            final g =
                                snd == null ? null : parseCssGradient(snd.gradient);
                            return FractionallySizedBox(
                              widthFactor: recipe[i].percent / 100,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: g == null
                                      ? null
                                      : LinearGradient(
                                          begin: g.begin,
                                          end: g.end,
                                          colors: g.colors),
                                  color: g == null
                                      ? hexToColor(recipe[i].color) ?? c.primary
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

**3.5 故事卡**——`_StoryCard` 的 `build` 整体替换为：

```dart
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('"${scene.desc}"',
                  style: TextStyle(
                    fontSize: 14,
                    color: c.text,
                    fontStyle: FontStyle.italic,
                    height: 1.7,
                    letterSpacing: 0.25,
                  )),
            ),
          ],
        ),
      ),
    );
  }
```

**3.6 分区节奏**——`_buildSection` 的 padding 保持 `fromLTRB(20, 18, 20, 0)`（即为统一值），确认无其他分区各自为政的 margin（预设卡间距 `bottom: 8` 保留）。改动完成后视觉核对：Hero 与 NavBar 间距 = margin top 12。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/scene_detail_page_test.dart`
Expected: PASS（点击配方行后 location 以 `/sound/` 开头）。

- [ ] **Step 5: Commit**

```bash
git add snapp/lib/pages/scene-detail/scene_detail_page.dart snapp/test/scene_detail_page_test.dart
git commit -m "feat: 场景详情浮动 Hero 卡与配方条精修，配方条目联动声音详情页"
```

---

### Task 5: 全量回归 + AGENTS.md 文档同步

**Files:**
- Modify: `d:\app\projects\whitenoise\AGENTS.md`（头部日期 + 5.7 已知待办）

- [ ] **Step 1: 静态检查**

Run: `flutter analyze`（cwd: `snapp`）
Expected: `No issues found!`（零错误、零警告）。

- [ ] **Step 2: 全量测试**

Run: `flutter test`
Expected: 全部 PASS（原 99 项 + 新增约 11 项）。

- [ ] **Step 3: AGENTS.md 同步**

1. 头部 `> 最后更新：2026-10-12` 改为 `> 最后更新：2026-10-13`。
2. 「5.7 已知待办」列表末尾追加：

```markdown
- **声音详情页（2026-10-13 新增）**：Flutter 侧新增页面（无原型对应页），路由 `/sound/:soundId`；入口为音疗库声音卡片与场景详情页声音配方条目。`PlayerService` 新增 `playSound`（单曲试听）/ `addTrack`（追加混音）/ `displayScene`（试听态展示回退），混音上限常量 `maxMixTracks = 6`；PlayBar 可见性改为按「有音轨」判定。
```

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md
git commit -m "docs: 同步声音详情页与场景详情页改版的 AGENTS.md 记录"
```

---

## Self-Review 记录

- **Spec coverage**：规格第三章（Hero 浮动卡/图标光晕/播放钮光晕/配方条/故事卡/分区节奏）→ Task 4；第四章（路由/页面结构/交互）→ Task 3；第五章（playSound/addTrack/displayScene + 5.1 影响面 6 处）→ Task 1/2；第六章（音疗库入口）→ Task 3；第七章（测试）→ 各任务 TDD 步骤 + Task 5 回归；第八章（文档同步）→ Task 5。规格 5.1 表中 media_bridge 一行经核实原实现已空值安全，仍按 displayScene 升级元数据（标题/渐变色）并保持 sceneId 取真实场景。
- **Placeholder scan**：无 TBD/TODO；所有代码步骤含完整代码。
- **Type consistency**：`playSound(Sound)`/`addTrack(Sound)→bool`/`displayScene→Scene?`/`maxMixTracks` 在 Task 1/2/3/4 引用一致；`onOpenSound(String)` 与路由 push 参数一致；`_RecipeCard` 新构造签名与调用处一致。
