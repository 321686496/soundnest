import { MethodCall, MethodCallHandler, MethodResult, MethodChannel, Any } from '@ohos/flutter_ohos';
import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { avSession } from '@kit.AVSessionKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MediaController';
const DB_NAME = 'shengqi_media.db';
const KEY_PLAYBACK = 'playback';

/** 卡片/原生侧推送的播放状态（Dart 侧同步，卡片初始渲染兜底）。 */
export interface PlaybackState {
  title: string;
  artist: string;
  isPlaying: boolean;
  color1: string;
  color2: string;
  sceneId: string;
}

/**
 * 声栖媒体控制器（App 进程 + 卡片进程共享类）。
 *
 * - App 进程：接收 Dart `attach`/`updatePlayback`；管理唯一的应用级 AVSession
 *   （通知栏播放条）；把播控命令（通知栏/卡片）转发给 Dart；向全部桌面卡片
 *   推送状态（formProvider.updateForm）。
 * - 卡片进程：由 EntryFormAbility 调用，负责 formId 持久化与卡片状态回填
 *   （RDB 跨进程共享同一数据库文件）。
 *
 * 命令在 Dart 未挂载（冷启动窗口期）时排队，attach 后补发。
 */
export class MediaControllerHandler implements MethodCallHandler {
  private static instance: MediaControllerHandler | undefined = undefined;

  /** 进程内单例（App 进程与卡片进程各自独立实例）。 */
  static getInstance(): MediaControllerHandler {
    if (MediaControllerHandler.instance === undefined) {
      MediaControllerHandler.instance = new MediaControllerHandler();
    }
    return MediaControllerHandler.instance;
  }

  /** Flutter MethodChannel（仅 App 进程，插件注册时由 Plugin 注入）。 */
  private channel: MethodChannel | null = null;
  /** Dart 侧是否已 attach。 */
  private dartAttached: boolean = false;
  /** 冷启动窗口期排队的播控命令。 */
  private pendingCommands: string[] = [];
  /** 应用级 AVSession（通知栏播放条数据源）。 */
  private session: avSession.AVSession | null = null;
  /** 跨进程共享状态库（App 进程与卡片进程读写同一文件）。 */
  private store: relationalStore.RdbStore | null = null;
  /** App 进程：EntryAbility 显式注入的 UIAbilityContext（AVSession/RDB 用）。 */
  private appContext: common.UIAbilityContext | undefined = undefined;
  /** 卡片进程注入的 context（App 进程用 AppStorage 'entryContext'）。 */
  private formContext: common.Context | undefined = undefined;
  /** 最近一次推送状态（避免重复推卡片）。 */
  private lastPush: string = '';

  private constructor() {
  }

  /** App 进程：插件挂载时注入通道。 */
  setChannel(channel: MethodChannel): void {
    this.channel = channel;
  }

  /** App 进程：EntryAbility 注入 UIAbilityContext（不依赖 AppStorage 时序）。 */
  setAppContext(context: common.UIAbilityContext): void {
    this.appContext = context;
  }

  /** 卡片进程：注入 FormExtensionAbility context（RDB 用）。 */
  setFormContext(context: common.Context): void {
    this.formContext = context;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'attach':
        this.dartAttached = true;
        this.flushPendingCommands();
        result.success(true);
        break;
      case 'updatePlayback': {
        const state = this.parseState(call);
        this.applyPlayback(state);
        result.success(null);
        break;
      }
      default:
        result.notImplemented();
    }
  }

  /** 桌面卡片 call 命令入口（EntryAbility callee 转发，App 进程）。 */
  onCardCommand(method: string): void {
    this.forwardToDart(method);
  }

  /* ------------------------- Dart ↔ 原生命令流转 ------------------------- */

  private forwardToDart(method: string): void {
    if (this.channel === null || !this.dartAttached) {
      if (this.pendingCommands.length < 16) {
        this.pendingCommands.push(method);
      }
      return;
    }
    // flutter_ohos invokeMethod 为 void + 可选 MethodResult 回调（无 Promise），
    // Dart 侧 handler 回 null 即完成应答，这里 fire-and-forget。
    const args: Map<string, string> = new Map<string, string>();
    args.set('method', method);
    this.channel.invokeMethod('command', args);
  }

  private flushPendingCommands(): void {
    if (this.pendingCommands.length === 0) {
      return;
    }
    const queued = this.pendingCommands;
    this.pendingCommands = [];
    for (const method of queued) {
      hilog.info(0x0000, TAG, 'flush pending command: %{public}s', method);
      this.forwardToDart(method);
    }
  }

  /* ------------------------------ AVSession ------------------------------ */

  private async ensureSession(): Promise<void> {
    if (this.session !== null) {
      return;
    }
    // 优先 EntryAbility 显式注入的 context，回退 AppStorage（configureFlutterEngine 写入）。
    const ctx: common.UIAbilityContext | undefined =
      this.appContext ?? AppStorage.get<common.UIAbilityContext>('entryContext');
    if (ctx === undefined) {
      hilog.warn(0x0000, TAG, 'entryContext missing, skip AVSession');
      return;
    }
    this.session = await avSession.createAVSession(ctx, 'ShengQiMedia', 'audio');
    hilog.info(0x0000, TAG, 'createAVSession ok');
    await this.session.activate();
    hilog.info(0x0000, TAG, 'activate ok');
    const agent: WantAgent = await wantAgent.getWantAgent({
      wants: [
        {
          bundleName: ctx.abilityInfo.bundleName,
          abilityName: ctx.abilityInfo.name,
        },
      ],
      // operationType 必填，省略会 401 Invalid input parameter。
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    });
    hilog.info(0x0000, TAG, 'getWantAgent ok');
    await this.session.setLaunchAbility(agent);
    hilog.info(0x0000, TAG, 'setLaunchAbility ok');
    // 通知栏播放条播控命令 → 转发 Dart。
    this.session.on('play', () => {
      this.forwardToDart('play');
    });
    this.session.on('pause', () => {
      this.forwardToDart('pause');
    });
    this.session.on('playNext', () => {
      this.forwardToDart('playNext');
    });
    this.session.on('playPrevious', () => {
      this.forwardToDart('playPrevious');
    });
    hilog.info(0x0000, TAG, 'AVSession created: %{public}s', ctx.abilityInfo.bundleName);
  }

  private async applyPlayback(state: PlaybackState): Promise<void> {
    try {
      await this.ensureSession();
      if (this.session !== null) {
        const metadata: avSession.AVMetadata = {
          assetId: state.sceneId !== '' ? state.sceneId : 'shengqi-mix',
          title: state.title,
          artist: state.artist,
        };
        await this.session.setAVMetadata(metadata);
        hilog.info(0x0000, TAG, 'setAVMetadata ok');
        // updateTime 须为相对时间（官方示例用 0），Date.now() 的 epoch 毫秒会被
        // 系统按非法参数拒绝（code=401）。
        const playback: avSession.AVPlaybackState = {
          state: state.isPlaying
            ? avSession.PlaybackState.PLAYBACK_STATE_PLAY
            : avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
          position: { elapsedTime: 0, updateTime: 0 },
        };
        await this.session.setAVPlaybackState(playback);
        hilog.info(0x0000, TAG, 'setAVPlaybackState ok: %{public}s | isPlaying=%{public}s',
          state.title, `${state.isPlaying}`);
      } else {
        hilog.warn(0x0000, TAG, 'AVSession null, only persist + cards');
      }
      await this.persistState(state);
      await this.updateAllCards(state);
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, TAG, 'applyPlayback failed: code=%{public}d msg=%{public}s',
        err.code, err.message);
    }
  }

  private parseState(call: MethodCall): PlaybackState {
    // flutter_ohos MethodCall 经 argument(key) 读取（无 arguments 属性）；
    // 返回 Any（ESObject），须显式标注满足 arkts-no-any-unknown。
    const str = (k: string, d: string): string => {
      const v: Any = call.argument(k);
      return v === null || v === undefined ? d : `${v}`;
    };
    const flag = (k: string): boolean => {
      const v: Any = call.argument(k);
      return v === true;
    };
    return {
      title: str('title', '声栖'),
      artist: str('artist', '白噪音 · 混音助眠'),
      isPlaying: flag('isPlaying'),
      color1: str('color1', '#3D6B5E'),
      color2: str('color2', '#2C4B41'),
      sceneId: str('sceneId', ''),
    };
  }

  /* --------------------------- RDB（跨进程共享） --------------------------- */

  private async ensureStore(): Promise<relationalStore.RdbStore | null> {
    if (this.store !== null) {
      return this.store;
    }
    const ctx: common.Context | undefined =
      this.formContext ?? this.appContext
        ?? AppStorage.get<common.UIAbilityContext>('entryContext');
    if (ctx === undefined) {
      hilog.warn(0x0000, TAG, 'context missing, skip RDB');
      return null;
    }
    const store = await relationalStore.getRdbStore(ctx, {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
    });
    await store.executeSql(
      'CREATE TABLE IF NOT EXISTS media_state(k TEXT PRIMARY KEY, v TEXT NOT NULL)');
    await store.executeSql(
      'CREATE TABLE IF NOT EXISTS card_forms(form_id TEXT PRIMARY KEY)');
    this.store = store;
    return store;
  }

  /** App 进程：写播放状态（卡片进程 onAddForm 兜底读取）。 */
  private async persistState(state: PlaybackState): Promise<void> {
    const store = await this.ensureStore();
    if (store === null) {
      return;
    }
    await store.executeSql('INSERT OR REPLACE INTO media_state(k, v) VALUES(?, ?)',
      [KEY_PLAYBACK, JSON.stringify(state)]);
  }

  /** 读播放状态（卡片进程初始渲染用）。 */
  async readState(): Promise<PlaybackState | null> {
    try {
      const store = await this.ensureStore();
      if (store === null) {
        return null;
      }
      const rs = await store.querySql(
        'SELECT v FROM media_state WHERE k = ?', [KEY_PLAYBACK]);
      let value: string | null = null;
      if (rs.goToNextRow()) {
        value = rs.getString(rs.getColumnIndex('v'));
      }
      rs.close();
      if (value === null) {
        return null;
      }
      const obj = JSON.parse(value) as Record<string, Object>;
      return {
        title: `${obj.title ?? '声栖'}`,
        artist: `${obj.artist ?? '白噪音 · 混音助眠'}`,
        isPlaying: obj.isPlaying === true || `${obj.isPlaying}` === 'true',
        color1: `${obj.color1 ?? '#3D6B5E'}`,
        color2: `${obj.color2 ?? '#2C4B41'}`,
        sceneId: `${obj.sceneId ?? ''}`,
      };
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, TAG, 'readState failed: %{public}s', err.message);
      return null;
    }
  }

  /** 卡片进程：登记/移除 formId（主进程据此推送更新）。 */
  async persistForm(formId: string, added: boolean): Promise<void> {
    try {
      const store = await this.ensureStore();
      if (store === null) {
        return;
      }
      if (added) {
        await store.executeSql('INSERT OR REPLACE INTO card_forms(form_id) VALUES(?)',
          [formId]);
      } else {
        await store.executeSql('DELETE FROM card_forms WHERE form_id = ?', [formId]);
      }
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, TAG, 'persistForm failed: %{public}s', err.message);
    }
  }

  private async queryForms(): Promise<string[]> {
    const store = await this.ensureStore();
    if (store === null) {
      return [];
    }
    const rs = await store.querySql('SELECT form_id FROM card_forms', []);
    const ids: string[] = [];
    while (rs.goToNextRow()) {
      ids.push(rs.getString(rs.getColumnIndex('form_id')));
    }
    rs.close();
    return ids;
  }

  /* ------------------------------ 卡片更新 ------------------------------ */

  /** App 进程：向全部已添加卡片推送最新状态。 */
  private async updateAllCards(state: PlaybackState): Promise<void> {
    const push = JSON.stringify(state);
    if (push === this.lastPush) {
      return;
    }
    this.lastPush = push;
    try {
      const formIds = await this.queryForms();
      if (formIds.length === 0) {
        return;
      }
      const binding = this.buildBinding(state);
      for (const formId of formIds) {
        await formProvider.updateForm(formId, binding);
      }
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, TAG, 'updateAllCards failed: %{public}s', err.message);
    }
  }

  /** 卡片进程：onAddForm 后按持久化状态回填单张卡片。 */
  async refreshCardFromStore(formId: string): Promise<void> {
    try {
      const state = await this.readState();
      if (state === null) {
        return;
      }
      await formProvider.updateForm(formId, this.buildBinding(state));
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, TAG, 'refreshCard failed: %{public}s', err.message);
    }
  }

  private buildBinding(state: PlaybackState): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData({
      'title': state.title,
      'artist': state.artist,
      'isPlaying': state.isPlaying,
      'color1': state.color1,
      'color2': state.color2,
    });
  }
}
