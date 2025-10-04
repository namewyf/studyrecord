import { CheckInOption } from '../models/types'
import { NotebookService } from '../services/NotebookService'

/**
 * 打卡选项对话框（动态渲染）
 */
@CustomDialog
export struct ActionDialog {
  controller?: CustomDialogController
  notebookId: string = ''  // 打卡本ID
  onOptionSelected: (optionId: string) => void = () => {}  // 回调：用户选择了某个选项

  @State options: CheckInOption[] = []  // 动态加载的选项列表
  @State dialogTitle: string = '打卡'  // 对话框标题
  @State isLoading: boolean = true

  async aboutToAppear() {
    await this.loadOptions()
  }

  /**
   * 动态加载该打卡本的选项
   */
  async loadOptions() {
    try {
      this.isLoading = true
      this.options = await NotebookService.getNotebookOptions(this.notebookId)
      // 这里可以根据打卡本配置加载标题，暂时硬编码
      this.dialogTitle = '这张试卷怎么样'
      this.isLoading = false
      console.info(`Loaded ${this.options.length} options for notebook ${this.notebookId}`)
    } catch (error) {
      console.error('Failed to load options:', error)
      this.isLoading = false
    }
  }

  /**
   * 渲染单个选项
   */
  @Builder
  buildOption(option: CheckInOption) {
    Column() {
      Row() {
        Row() {
          // 使用圆形色块代替图标（暂时）
          Circle()
            .width(40)
            .height(40)
            .fill(option.color || '#FFFFFF')
            .margin({ right: 12 })

          Column() {
            Text(option.name)  // ✅ 从数据读取名称
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
        this.onOptionSelected(option.id)  // ✅ 传递选项ID
        // 注意：对话框关闭由回调函数处理，避免重复关闭
      })
    }
    .width('90%')
    .backgroundColor('#1A1A1A')
    .borderRadius(8)
    .margin({ bottom: 12 })
  }

  build() {
    Column() {
      // 顶部关闭按钮
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

      // 对话框标题
      Text(this.dialogTitle)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .margin({ top: 20, bottom: 30 })

      // 加载状态或选项列表
      if (this.isLoading) {
        Text('加载中...')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 20, bottom: 20 })
      } else if (this.options.length === 0) {
        Text('暂无选项')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 20, bottom: 20 })
      } else {
        // 🔥 动态渲染所有选项
        ForEach(this.options, (option: CheckInOption) => {
          this.buildOption(option)
        }, (option: CheckInOption) => option.id)
      }

      Blank()
        .height(30)
    }
    .width('100%')
    .backgroundColor('#000000')
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}
