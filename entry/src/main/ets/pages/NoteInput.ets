// Router is now accessed through UIContext
import preferences from '@ohos.data.preferences'
// PromptAction is now accessed through UIContext
import common from '@ohos.app.ability.common'
import { StudyRecord, RouterParams } from '../models/types'

@Entry
@Component
struct NoteInput {
  @State text: string = ''
  @State date: string = ''
  @State status: string = ''

  aboutToAppear() {
    const params = (this.getUIContext().getRouter().getParams() || {}) as RouterParams
    this.text = params?.text || ''
    this.date = params?.date || ''
    this.status = params?.status || ''
  }

  async saveAndReturn() {
    try {
      // 获取preferences实例
      const dataPreferences = await preferences.getPreferences((this.getUIContext().getHostContext() as common.UIAbilityContext), 'study_records')

      // 读取现有记录
      const recordsStr = await dataPreferences.get('records', '[]') as string
      const records: StudyRecord[] = JSON.parse(recordsStr)

      // 添加新记录
      const newRecord: StudyRecord = {
        date: this.date,
        status: this.status as 'completed' | 'copied',
        note: this.text,
        timestamp: Date.now()
      }

      // 检查是否已有同日期记录，如果有则更新
      const existingIndex = records.findIndex((r: StudyRecord) => r.date === this.date)
      if (existingIndex >= 0) {
        records[existingIndex] = newRecord
      } else {
        records.push(newRecord)
      }

      // 保存记录
      await dataPreferences.put('records', JSON.stringify(records))
      await dataPreferences.flush()

      this.getUIContext().getPromptAction().showToast({
        message: '记录保存成功',
        duration: 2000
      })

      // 返回主页
      this.getUIContext().getRouter().clear()
      this.getUIContext().getRouter().replaceNamedRoute({ name: 'pages/Index' })
    } catch (error) {
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
      .padding(16)

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