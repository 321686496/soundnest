import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapp/data/scene_models.dart';
import 'package:snapp/data/seed_data.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/custom_scene_service.dart';
import 'package:snapp/services/media_bridge.dart';
import 'package:snapp/services/player_service.dart';

/// MediaBridge 单元测试。
///
/// 通过 mock `com.snapp.media` MethodChannel 验证双向桥接：
/// - 下行：播放状态快照推送（初始/场景/去重/渐变色解析）；
/// - 上行：通知栏与卡片播控命令路由（play/pause/playPause/
///   playNext/playPrevious），含无音轨时的场景恢复与循环切换。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel mediaChannel = MethodChannel('com.snapp.media');
  final List<Map<Object?, Object?>> updates = <Map<Object?, Object?>>[];

  setUp(() {
    updates.clear();
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(mediaChannel, (MethodCall call) async {
      if (call.method == 'updatePlayback') {
        updates.add(call.arguments as Map<Object?, Object?>);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(mediaChannel, null);
  });

  /// 模拟原生侧（通知栏/桌面卡片按钮）下发播控命令。
  Future<void> sendCommand(String method) async {
    await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .handlePlatformMessage(
      'com.snapp.media',
      const StandardMethodCodec().encodeMethodCall(
          MethodCall('command', <String, Object?>{'method': method})),
      (ByteData? data) {},
    );
    await pumpEventQueue();
  }

  Scene sceneById(String id) =>
      homeScenes.firstWhere((Scene s) => s.id == id);

  RecentItem recentOf(Scene s) => RecentItem(
        sceneId: s.id,
        name: s.name,
        iconName: s.iconName,
        gradient: s.gradient,
        ts: 0,
      );

  group('状态下行（快照推送）', () {
    test('attach 后立即推送空闲快照（品牌回退色）', () async {
      final player = PlayerService(engine: SimulatedAudioEngine());
      MediaBridge().attach(player);
      await pumpEventQueue();
      expect(updates.length, 1);
      final args = updates.single;
      expect(args['title'], '声栖');
      expect(args['artist'], '白噪音 · 混音助眠');
      expect(args['isPlaying'], isFalse);
      expect(args['color1'], '#3D6B5E');
      expect(args['color2'], '#2C4B41');
      expect(args['sceneId'], '');
    });

    test('applyScene 推送场景快照：音轨摘要 + 渐变主色解析', () async {
      final player = PlayerService(engine: SimulatedAudioEngine());
      MediaBridge().attach(player);
      await pumpEventQueue();
      updates.clear();

      player.applyScene(sceneById('deep-sleep'));
      await pumpEventQueue();

      expect(updates.length, 1);
      final args = updates.single;
      expect(args['title'], '深度睡眠');
      expect(args['artist'], '雨声 · 白噪音 · 森林');
      expect(args['isPlaying'], isTrue);
      expect(args['sceneId'], 'deep-sleep');
      // 渐变 linear-gradient(135deg, #7E93A8, #4E7182) → 取前两个 hex。
      expect(args['color1'], '#7E93A8');
      expect(args['color2'], '#4E7182');
    });

    test('快照未变化的通知被去重跳过', () async {
      final player = PlayerService(engine: SimulatedAudioEngine());
      MediaBridge().attach(player);
      player.applyScene(sceneById('deep-sleep'));
      await pumpEventQueue();
      updates.clear();

      // fadeMinutes 不在快照 key 中：仅触发 notifyListeners，不应重复推送。
      player.setFadeMinutes(5);
      await pumpEventQueue();
      expect(updates, isEmpty);

      // 播放态变化 → 推送一次暂停快照。
      player.togglePlay();
      await pumpEventQueue();
      expect(updates.length, 1);
      expect(updates.single['isPlaying'], isFalse);
    });
  });

  group('命令上行（播控路由）', () {
    test('pause/play/playPause 命令切换播放状态', () async {
      final player = PlayerService(engine: SimulatedAudioEngine());
      MediaBridge().attach(player);
      player.applyScene(sceneById('deep-sleep'));
      await pumpEventQueue();
      expect(player.isPlaying, isTrue);

      await sendCommand('pause');
      expect(player.isPlaying, isFalse);

      // 已暂停时 pause 幂等，不反向切换为播放。
      await sendCommand('pause');
      expect(player.isPlaying, isFalse);

      await sendCommand('play');
      expect(player.isPlaying, isTrue);

      await sendCommand('playPause');
      expect(player.isPlaying, isFalse);

      await sendCommand('playPause');
      expect(player.isPlaying, isTrue);
    });

    test('无音轨 playPause：无最近记录回退首个预设场景', () async {
      final player = PlayerService(engine: SimulatedAudioEngine());
      MediaBridge().attach(player);
      await pumpEventQueue();

      await sendCommand('playPause');
      expect(player.currentScene?.id, homeScenes.first.id);
      expect(player.isPlaying, isTrue);
      expect(player.tracks, isNotEmpty);
    });

    test('无音轨 playPause：按最近记录恢复预设场景', () async {
      final player = PlayerService(engine: SimulatedAudioEngine());
      player.recent = <RecentItem>[recentOf(sceneById('ocean-sleep'))];
      MediaBridge().attach(player);
      await pumpEventQueue();

      await sendCommand('playPause');
      expect(player.currentScene?.id, 'ocean-sleep');
      expect(player.isPlaying, isTrue);
    });

    test('无音轨 playPause：恢复自定义场景（CustomSceneService 查找）', () async {
      final customScenes = CustomSceneService();
      const custom = Scene(
        id: 'custom-test',
        name: '测试自定义',
        category: 'sleep',
        desc: '',
        iconName: 'moon',
        gradient: 'linear-gradient(135deg, #123456, #654321)',
        image: '',
        soundIds: <String>['rain'],
        isPreset: false,
      );
      customScenes.scenes.add(custom);

      final player = PlayerService(engine: SimulatedAudioEngine());
      player.recent = <RecentItem>[
        const RecentItem(
            sceneId: 'custom-test',
            name: '测试自定义',
            iconName: 'moon',
            gradient: '',
            ts: 0),
      ];
      MediaBridge(customScenes: customScenes).attach(player);
      await pumpEventQueue();

      await sendCommand('playPause');
      expect(player.currentScene?.id, 'custom-test');
      expect(player.isPlaying, isTrue);
    });

    test('无音轨 playPause：最近记录场景不存在时回退首个预设', () async {
      final player = PlayerService(engine: SimulatedAudioEngine());
      player.recent = <RecentItem>[
        const RecentItem(
            sceneId: 'ghost',
            name: '幽灵场景',
            iconName: 'moon',
            gradient: '',
            ts: 0),
      ];
      MediaBridge().attach(player);
      await pumpEventQueue();

      await sendCommand('playPause');
      expect(player.currentScene?.id, homeScenes.first.id);
    });

    test('playNext 无最近记录时回退首个预设场景', () async {
      final player = PlayerService(engine: SimulatedAudioEngine());
      MediaBridge().attach(player);
      await pumpEventQueue();

      await sendCommand('playNext');
      expect(player.currentScene?.id, homeScenes.first.id);
      expect(player.isPlaying, isTrue);
    });

    test('playNext/playPrevious 在最近列表循环切换（不被重排打断）', () async {
      final player = PlayerService(engine: SimulatedAudioEngine());
      player.recent = <RecentItem>[
        recentOf(sceneById('deep-sleep')),
        recentOf(sceneById('ocean-sleep')),
        recentOf(sceneById('focus-white-noise')),
      ];
      MediaBridge().attach(player);
      await pumpEventQueue();

      // 恢复最近场景：deep-sleep。
      await sendCommand('playPause');
      expect(player.currentScene?.id, 'deep-sleep');

      await sendCommand('playNext');
      expect(player.currentScene?.id, 'ocean-sleep');

      await sendCommand('playNext');
      expect(player.currentScene?.id, 'focus-white-noise');

      // 循环回到首个。
      await sendCommand('playNext');
      expect(player.currentScene?.id, 'deep-sleep');

      // 反向切换。
      await sendCommand('playPrevious');
      expect(player.currentScene?.id, 'focus-white-noise');
    });
  });
}
