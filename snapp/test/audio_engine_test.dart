// 声栖 · 音频引擎测试。
//
// 覆盖：SimulatedAudioEngine 状态记录、PlayerService 与引擎的接线
// （有资产音轨被加载（含真实录音）、播放/音量/静音/移除同步、
// 无资产场景静默播放）、JustAudioEngine 在测试环境（无平台插件）的降级路径。

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:snapp/data/scene_models.dart';
import 'package:snapp/data/seed_data.dart';
import 'package:snapp/services/audio_engine.dart';
import 'package:snapp/services/player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SimulatedAudioEngine', () {
    test('records loaded tracks, skipping null assets', () async {
      final engine = SimulatedAudioEngine();
      await engine.loadTrack('white-noise', 'assets/audio/white-noise.wav');
      await engine.loadTrack('rain', 'assets/audio/rain.wav');
      await engine.loadTrack('drizzle', null);

      expect(engine.loaded, containsAll(<String>['white-noise', 'rain']));
      expect(engine.loaded, isNot(contains('drizzle')));
      expect(engine.volumes['white-noise'], 1.0);
      expect(engine.mutes['white-noise'], isFalse);
    });

    test('play/pause flips playing state', () async {
      final engine = SimulatedAudioEngine();
      expect(engine.playing, isFalse);
      await engine.play();
      expect(engine.playing, isTrue);
      await engine.pause();
      expect(engine.playing, isFalse);
    });

    test('volume/mute/dispose sync state', () async {
      final engine = SimulatedAudioEngine();
      await engine.loadTrack('rain', 'assets/audio/rain.wav');

      await engine.setVolume('rain', 0.3);
      await engine.setMute('rain', true);
      expect(engine.volumes['rain'], 0.3);
      expect(engine.mutes['rain'], isTrue);

      await engine.disposeTrack('rain');
      expect(engine.loaded, isNot(contains('rain')));
      expect(engine.volumes.containsKey('rain'), isFalse);
      expect(engine.mutes.containsKey('rain'), isFalse);
    });

    test('disposeAll clears everything', () async {
      final engine = SimulatedAudioEngine();
      await engine.loadTrack('rain', 'assets/audio/rain.wav');
      await engine.loadTrack('wind', 'assets/audio/wind.wav');

      await engine.disposeAll();
      expect(engine.loaded, isEmpty);
      expect(engine.volumes, isEmpty);
      expect(engine.mutes, isEmpty);
    });
  });

  group('PlayerService + SimulatedAudioEngine 接线', () {
    test('applyScene loads only generated-asset tracks and starts playing',
        () {
      final engine = SimulatedAudioEngine();
      final player = PlayerService(engine: engine);

      player.applyScene(_sceneById('rainy-night'));
      // rainy-night = [drizzle, thunder, campfire]，三者均有资产（真实录音）
      expect(engine.loaded, <String>{'drizzle', 'thunder', 'campfire'});
      expect(engine.playing, isTrue);
      expect(player.isPlaying, isTrue);
      expect(player.tracks, hasLength(3));
    });

    test('togglePlay pauses and resumes engine', () {
      final engine = SimulatedAudioEngine();
      final player = PlayerService(engine: engine);
      player.applyScene(_sceneById('deep-sleep'));
      expect(engine.playing, isTrue);

      expect(player.togglePlay(), isTrue);
      expect(engine.playing, isFalse);

      expect(player.togglePlay(), isTrue);
      expect(engine.playing, isTrue);
    });

    test('setTrackVolume syncs normalized volume', () {
      final engine = SimulatedAudioEngine();
      final player = PlayerService(engine: engine);
      player.applyScene(_sceneById('deep-sleep'));

      player.setTrackVolume('rain', 30);
      expect(engine.volumes['rain'], 0.3);
    });

    test('toggleTrackMute syncs mute state', () {
      final engine = SimulatedAudioEngine();
      final player = PlayerService(engine: engine);
      player.applyScene(_sceneById('deep-sleep'));

      player.toggleTrackMute('rain');
      expect(engine.mutes['rain'], isTrue);

      player.toggleTrackMute('rain');
      expect(engine.mutes['rain'], isFalse);
    });

    test('removeTrack disposes engine track', () {
      final engine = SimulatedAudioEngine();
      final player = PlayerService(engine: engine);
      player.applyScene(_sceneById('deep-sleep'));

      player.removeTrack('rain');
      expect(engine.loaded, isNot(contains('rain')));
      expect(player.tracks, hasLength(2));
    });

    test('scene with no audio assets still plays silently', () {
      final engine = SimulatedAudioEngine();
      final player = PlayerService(engine: engine);

      // 自造场景只含仍无资产的音（夜莺/蓝噪音）→ 全部走模拟引擎静音播放
      const Scene silentScene = Scene(
        id: 'test-silent',
        name: '静默场景',
        category: 'sleep',
        desc: '仅含无资产声音的测试场景',
        iconName: 'bird',
        gradient: '',
        image: '',
        soundIds: <String>['nightingale', 'blue-noise'],
        isPreset: true,
      );
      player.applyScene(silentScene);
      expect(engine.loaded, isEmpty);
      expect(engine.playing, isTrue);
      expect(player.isPlaying, isTrue);
    });
  });

  group('JustAudioEngine 降级', () {
    test('degrades gracefully when platform plugin missing', () async {
      final engine = JustAudioEngine();

      // 测试环境无 just_audio 原生实现：setAsset 内部的平台调用失败会让引擎
      // 整体降级。loadTrack 可能因内部 durationCompleter 永不完成而挂起，
      // 故不 await，改为冲刷事件队列后断言降级标记。
      unawaited(engine.loadTrack('rain', 'assets/audio/rain.wav'));
      await pumpEventQueue();
      expect(engine.degraded, isTrue);

      // 降级后继续调用不抛异常、保持静默
      unawaited(engine.play());
      unawaited(engine.pause());
      unawaited(engine.disposeAll());
      await pumpEventQueue();
      expect(engine.degraded, isTrue);
    });
  });
}

Scene _sceneById(String id) => homeScenes.firstWhere((Scene s) => s.id == id);
