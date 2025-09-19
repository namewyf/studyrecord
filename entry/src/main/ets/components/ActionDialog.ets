@CustomDialog
export struct ActionDialog {
  controller?: CustomDialogController
  onCompleted: () => void = () => {}
  onCopied: () => void = () => {}

  build() {
    Column() {
      Row() {
        Image($r('app.media.close'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.controller?.close()
          })

        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })

      Text('记录今天的作业状态')
        .fontSize(18)
        .fontColor('#FFFFFF')
        .margin({ top: 20, bottom: 30 })

      // 作业完成选项
      Column() {
        Row() {
          Row() {
            Circle()
              .width(40)
              .height(40)
              .fill('#00FF00')
              .margin({ right: 12 })

            Column() {
              Text('作业做完了')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
            }
            .alignItems(HorizontalAlign.Start)
          }

          Image($r('app.media.arrow_right'))
            .width(20)
            .height(20)
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.SpaceBetween)
        .onClick(() => {
          this.onCompleted()
        })
      }
      .width('90%')
      .backgroundColor('#1A1A1A')
      .borderRadius(8)
      .margin({ bottom: 12 })

      // 准备抄作业选项
      Column() {
        Row() {
          Row() {
            Circle()
              .width(40)
              .height(40)
              .fill('#FFA500')
              .margin({ right: 12 })

            Column() {
              Text('做了，准备抄了')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
            }
            .alignItems(HorizontalAlign.Start)
          }

          Image($r('app.media.arrow_right'))
            .width(20)
            .height(20)
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.SpaceBetween)
        .onClick(() => {
          this.onCopied()
        })
      }
      .width('90%')
      .backgroundColor('#1A1A1A')
      .borderRadius(8)
      .margin({ bottom: 30 })
    }
    .width('100%')
    .backgroundColor('#000000')
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}