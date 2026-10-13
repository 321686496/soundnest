let storage2x4 = new LocalStorage();

/**
 * 声栖音乐播控卡片（2x4 动态卡片）。
 *
 * 在 2x2 基础上增加上一场景/下一场景（按最近播放循环切换），
 * 状态由主进程（media_controller 插件）经 formProvider.updateForm 推送。
 */
@Entry(storage2x4)
@Component
struct MusicWidget2x4 {
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('title') title: string = '声栖';
  @LocalStorageProp('artist') artist: string = '白噪音 · 混音助眠';
  @LocalStorageProp('isPlaying') isPlaying: boolean = false;
  @LocalStorageProp('color1') color1: string = '#3D6B5E';
  @LocalStorageProp('color2') color2: string = '#2C4B41';

  build() {
    Column() {
      // 品牌行（点击打开应用）
      Row() {
        Text('声栖')
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.72)')
          .letterSpacing(2)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14 })
      .onClick(() => {
        postCardAction(this, { action: 'router', abilityName: 'EntryAbility' });
      })

      // 标题区（点击打开应用）
      Column() {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.artist)
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.66)')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 16, right: 16, top: 10 })
      .onClick(() => {
        postCardAction(this, { action: 'router', abilityName: 'EntryAbility' });
      })

      Blank()

      // 播控区：上一场景 / 播放暂停 / 下一场景
      Row() {
        // 上一场景
        Column() {
          Path()
            .commands('M6 4 h2 v16 h-2 Z M18 4 L9 12 L18 20 Z')
            .fill(Color.White)
            .width(15)
            .height(15)
        }
        .width(34)
        .height(34)
        .borderRadius(17)
        .backgroundColor('rgba(255,255,255,0.14)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          postCardAction(this, {
            action: 'call',
            abilityName: 'EntryAbility',
            params: { method: 'playPrevious', formId: this.formId },
          });
        })

        // 播放/暂停
        Column() {
          if (this.isPlaying) {
            Path()
              .commands('M7 4 h3 v16 h-3 Z M14 4 h3 v16 h-3 Z')
              .fill(Color.White)
              .width(16)
              .height(16)
          } else {
            Path()
              .commands('M8 4 L20 12 L8 20 Z')
              .fill(Color.White)
              .width(16)
              .height(16)
          }
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('rgba(255,255,255,0.22)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ left: 8, right: 8 })
        .onClick(() => {
          postCardAction(this, {
            action: 'call',
            abilityName: 'EntryAbility',
            params: { method: 'playPause', formId: this.formId },
          });
        })

        // 下一场景
        Column() {
          Path()
            .commands('M16 4 h2 v16 h-2 Z M6 4 L15 12 L6 20 Z')
            .fill(Color.White)
            .width(15)
            .height(15)
        }
        .width(34)
        .height(34)
        .borderRadius(17)
        .backgroundColor('rgba(255,255,255,0.14)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          postCardAction(this, {
            action: 'call',
            abilityName: 'EntryAbility',
            params: { method: 'playNext', formId: this.formId },
          });
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .padding({ left: 16, right: 16, bottom: 14 })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 135,
      colors: [[this.color1, 0.0], [this.color2, 1.0]],
    })
    .borderRadius(16)
  }
}
