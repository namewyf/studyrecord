@Component
export struct SlideButton {
  @State slideOffset: number = 0
  @State isSliding: boolean = false
  @State containerWidth: number = 0
  private maxOffset: number = 0
  private buttonSize: number = 56
  onConfirm: () => void = () => {}
  text: string = '滑动创建日记本'

  aboutToAppear() {
    // 启动时的提示动画
    setTimeout(() => {
      animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
        this.slideOffset = 30
      })
      setTimeout(() => {
        animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
          this.slideOffset = 0
        })
      }, 500)
    }, 300)
  }

  build() {
    Stack({ alignContent: Alignment.Start }) {
      // 背景轨道
      Row() {
        Row() {
          Text('向右滑动')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 70 })
        }
        .layoutWeight(1)

        Text(this.text)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 16 })
      }
      .width('100%')
      .height(this.buttonSize)
      .backgroundColor('#1A1A1A')
      .borderRadius(this.buttonSize / 2)
      .border({ width: 2, color: '#333333' })

      // 滑动按钮
      Row() {
        Text('››')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
      }
      .width(this.buttonSize)
      .height(this.buttonSize)
      .backgroundColor('#FFA500')
      .borderRadius(this.buttonSize / 2)
      .justifyContent(FlexAlign.Center)
      .shadow({
        radius: 8,
        color: '#40000000',
        offsetX: 0,
        offsetY: 2
      })
      .translate({ x: this.slideOffset })
      .gesture(
        PanGesture()
          .onActionStart(() => {
            this.isSliding = true
          })
          .onActionUpdate((event: GestureEvent) => {
            if (event.offsetX > 0) {
              // 动态计算最大偏移
              this.maxOffset = this.containerWidth - this.buttonSize - 4
              if (this.maxOffset < 0) {
                this.maxOffset = 250
              }
              this.slideOffset = Math.min(event.offsetX, this.maxOffset)
            }
          })
          .onActionEnd(() => {
            if (this.slideOffset >= this.maxOffset * 0.75) {
              // 滑动超过75%，触发确认
              animateTo({ duration: 200 }, () => {
                this.slideOffset = this.maxOffset
              })
              setTimeout(() => {
                this.onConfirm()
                this.slideOffset = 0
              }, 200)
            } else {
              // 未达到阈值，回弹
              animateTo({ duration: 300, curve: Curve.FastOutSlowIn }, () => {
                this.slideOffset = 0
              })
            }
            this.isSliding = false
          })
      )
    }
    .width('100%')
    .height(this.buttonSize)
    .margin({ top: 20, bottom: 20 })
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.containerWidth = Number(newValue.width)
    })
  }
}
