import { common, Want, AbilityConstant } from '@kit.AbilityKit';
import { rpc } from '@kit.IPCKit';
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { MediaControllerHandler } from 'media_controller';

/** call 事件回调的空返回值（callee 约定要求 Parcelable）。 */
class CardCallVoid implements rpc.Parcelable {
  marshalling(_data: rpc.MessageSequence): boolean {
    return true;
  }

  unmarshalling(_data: rpc.MessageSequence): boolean {
    return true;
  }
}

export default class EntryAbility extends FlutterAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    await super.onCreate(want, launchParam);
    // 显式注入 UIAbilityContext（AVSession/RDB 用），不依赖 AppStorage 时序。
    MediaControllerHandler.getInstance().setAppContext(this.context);
    this.registerCardCall();
  }

  /** 桌面卡片播控（call 事件）→ media_controller 插件 → Dart。 */
  private registerCardCall(): void {
    const handler = MediaControllerHandler.getInstance();
    const wrap = (method: string): ((data: rpc.MessageSequence) => rpc.Parcelable) => {
      return (_data: rpc.MessageSequence): rpc.Parcelable => {
        handler.onCardCommand(method);
        return new CardCallVoid();
      };
    };
    this.callee.on('playPause', wrap('playPause'));
    this.callee.on('playNext', wrap('playNext'));
    this.callee.on('playPrevious', wrap('playPrevious'));
  }

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    // 供 background_task / media_controller 插件取用：长时任务与 AVSession
    // 均需 UIAbilityContext，传应用级 context 会触发 401 参数校验失败。
    AppStorage.setOrCreate<common.UIAbilityContext>('entryContext', this.context);
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    // 说明：不覆盖 'context' 键（保持 just_audio_ohos 写入的 applicationContext）。
    // 该插件会为每个音轨各建一个 AVSession（元数据取自音频文件标签，恒为
    //「未知」且随音轨重建泄漏），通知栏播控改由 media_controller 的应用级
    // 唯一 AVSession 统一接管（场景名元数据 + 整组混音播控 + 桌面卡片）。
  }
}
