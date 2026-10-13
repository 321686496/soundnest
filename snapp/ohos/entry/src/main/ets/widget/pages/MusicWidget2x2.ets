let storage2x2 = new LocalStorage();

/**
 * 声栖音乐播控卡片（2x2 动态卡片）。
 *
 * - 背景取场景渐变主色（沉浸式），标题=场景名、副标题=音轨摘要；
 * - 标题区点击 router 拉起应用；播放按钮 call 事件驱动播控；
 * - 状态由主进程（media_controller 插件）经 formProvider.updateForm 推送。
 */
@Entry(storage2x2)
@Component
struct MusicWidget2x2 {
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
          .maxLines(1)
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

      // 播控区（call 事件 → EntryAbility callee）
      Row() {
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
        .onClick(() => {
          postCardAction(this, {
            action: 'call',
            abilityName: 'EntryAbility',
            params: { method: 'playPause', formId: this.formId },
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
