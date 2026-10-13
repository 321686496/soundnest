import { FormExtensionAbility, formBindingData, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { MediaControllerHandler } from 'media_controller';

/**
 * 声栖音乐播放卡片（Form Kit 动态卡片）。
 *
 * - onAddForm：登记 formId 到跨进程 RDB（主进程据此推送更新），
 *   并用持久化播放状态异步回填卡片（兜底返回默认数据）。
 * - onRemoveForm：移除 formId 登记。
 * - 播控按钮走 call 事件（EntryAbility callee），不走 message 事件。
 */
export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = want.parameters![formInfo.FormParam.IDENTITY_KEY] as string;
    const handler = MediaControllerHandler.getInstance();
    handler.setFormContext(this.context);
    handler.persistForm(formId, true);
    handler.refreshCardFromStore(formId);
    return formBindingData.createFormBindingData({
      'formId': formId,
      'title': '声栖',
      'artist': '白噪音 · 混音助眠',
      'isPlaying': false,
      'color1': '#3D6B5E',
      'color2': '#2C4B41',
    });
  }

  onRemoveForm(formId: string): void {
    MediaControllerHandler.getInstance().persistForm(formId, false);
  }

  onUpdateForm(formId: string): void {
    // updateEnabled=false 一般不触发；保留按共享状态回填，覆盖系统主动刷新场景。
    MediaControllerHandler.getInstance().setFormContext(this.context);
    MediaControllerHandler.getInstance().refreshCardFromStore(formId);
  }

  onFormEvent(_formId: string, _message: string): void {
    // 播控走 call 事件（UIAbility callee），无 message 事件。
  }
}
