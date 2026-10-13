import 'dart:async';

import 'package:flutter/services.dart';

/// 声栖 · OHOS 媒体控制通道。
///
/// 一端连接原生 [MediaControllerHandler]：
/// - `updatePlayback`：把当前场景（标题/音轨/播放态/渐变色）推送到原生，
///   原生侧据此更新 AVSession（通知栏播放条）与桌面音乐卡片；
/// - [commands]：接收原生命令（通知栏播控按钮 / 桌面卡片按钮），
///   method 取值：`play` / `pause` / `playPause` / `playNext` / `playPrevious`。
///
/// 非 OHOS 平台插件未注册时所有调用静默降级（吞掉 MissingPluginException）。
class MediaController {
  MediaController._();

  static const MethodChannel _channel = MethodChannel('com.snapp.media');

  static final StreamController<String> _commands =
      StreamController<String>.broadcast();

  /// 原生播控命令流（通知栏 + 桌面卡片共用）。
  static Stream<String> get commands => _commands.stream;

  static bool _initialized = false;

  /// 挂载命令监听并通知原生「Dart 侧已就绪」。
  ///
  /// 原生侧冷启动（如桌面卡片拉起应用）期间收到的命令会被排队，
  /// attach 后统一补发到 [commands] 流。
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'command') {
        final Map<Object?, Object?>? args =
            call.arguments as Map<Object?, Object?>?;
        final String? method = args?['method'] as String?;
        if (method != null) _commands.add(method);
      }
    });
    try {
      await _channel.invokeMethod<void>('attach');
    } catch (_) {
      // 非 OHOS 平台插件未注册，忽略。
    }
  }

  /// 推送播放状态到原生（AVSession 元数据 + 播放态 + 卡片数据）。
  ///
  /// [title] 场景名；[artist] 音轨名摘要；[isPlaying] 播放中标记；
  /// [color1]/[color2] 场景渐变主色（卡片沉浸背景）；[sceneId] 当前场景 id。
  static Future<void> updatePlayback({
    required String title,
    required String artist,
    required bool isPlaying,
    String color1 = '#3D6B5E',
    String color2 = '#2C4B41',
    String sceneId = '',
  }) async {
    try {
      await _channel.invokeMethod<void>('updatePlayback', <String, Object?>{
        'title': title,
        'artist': artist,
        'isPlaying': isPlaying,
        'color1': color1,
        'color2': color2,
        'sceneId': sceneId,
      });
    } catch (_) {
      // 非 OHOS 平台忽略。
    }
  }
}
