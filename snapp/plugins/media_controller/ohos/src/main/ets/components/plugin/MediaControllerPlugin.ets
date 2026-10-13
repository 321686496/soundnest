import { FlutterPlugin, FlutterPluginBinding, MethodChannel } from '@ohos/flutter_ohos';
import { MediaControllerHandler } from './MediaControllerHandler';

/** 声栖媒体控制插件（channel: com.snapp.media）。 */
export default class MediaControllerPlugin implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private handler: MediaControllerHandler | null = null;

  getUniqueClassName(): string {
    return 'MediaControllerPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    // 单例注入通道：EntryAbility callee 收到卡片 call 命令后经同一实例转发 Dart。
    this.handler = MediaControllerHandler.getInstance();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'com.snapp.media');
    this.channel.setMethodCallHandler(this.handler);
    this.handler.setChannel(this.channel);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.handler = null;
  }
}
