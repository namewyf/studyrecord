// Router is now accessed through UIContext
// PromptAction is now accessed through UIContext
import common from '@ohos.app.ability.common'
import { StudyRecord, RouterParams } from '../models/types'
import { StorageService } from '../services/StorageService'

@Entry
@Component
struct NoteInput {
  @State text: string = ''
  @State date: string = ''
  @State status: string = ''
  @State notebookId: string = ''

  aboutToAppear() {
    const params = (this.getUIContext().getRouter().getParams() || {}) as RouterParams
    this.text = params?.text || ''
    this.date = params?.date || ''
    this.status = params?.status || ''
    this.notebookId = params?.notebookId || ''
  }

  async saveAndReturn() {
    console.info('Starting saveAndReturn')
    try {
      const storageService = StorageService.getInstance()
      const context = getContext(this) as common.UIAbilityContext
      await storageService.init(context)

      // 创建新记录
      const newRecord: StudyRecord = {
        date: this.date,
        status: this.status as 'completed' | 'copied',
        note: this.text,
        timestamp: Date.now(),
        notebookId: this.notebookId
      }

      // 保存记录
      await storageService.saveRecord(newRecord)

      this.getUIContext().getPromptAction().showToast({
        message: '记录保存成功',
        duration: 2000
      })

      // 返回主页
      this.getUIContext().getRouter().clear()
      this.getUIContext().getRouter().pushUrl({ url: 'pages/Index' })
    } catch (error) {
      console.error('Failed to save and return:', error)
      this.getUIContext().getPromptAction().showToast({
        message: '保存失败，请重试',
        duration: 2000
      })
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Image($r('app.media.close'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })

        Blank()

        Text('确认')
          .fontSize(16)
          .fontColor('#FFA500')
          .onClick(() => {
            this.saveAndReturn()
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 56, bottom: 16 })

      // 文字输入区域
      TextArea({ placeholder: '写点什么...', text: this.text })
        .placeholderColor('#666666')
        .fontColor('#FFFFFF')
        .fontSize(16)
        .backgroundColor('#000000')
        .borderRadius(0)
        .padding(16)
        .onChange((value: string) => {
          this.text = value
        })
        .height('80%')
        .width('100%')

      // 底部工具栏
      Row() {
        Image($r('app.media.add'))
          .width(24)
          .height(24)
          .margin({ left: 16 })
      }
      .width('100%')
      .height(50)
      .backgroundColor('#1A1A1A')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}