// Router is now accessed through UIContext
// PromptAction is now accessed through UIContext
import preferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'
import { StudyRecord, RouterParams } from '../models/types'

@Entry
@Component
struct RecordDetail {
  @State date: string = ''
  @State status: string = ''
  @State note: string = ''
  @State currentWeekDates: number[] = []

  private weekDays: string[] = ['六', '日', '一', '二', '三', '四', '五']

  aboutToAppear() {
    const params = this.getUIContext().getRouter().getParams() as RouterParams
    this.date = params?.date || ''
    this.status = params?.status || ''
    this.calculateWeekDates()
  }

  calculateWeekDates() {
    const dateObj = new Date(this.date)
    const day = dateObj.getDate()
    const weekDay = dateObj.getDay()

    // 计算本周日期
    const startOfWeek = day - weekDay
    this.currentWeekDates = []
    for (let i = 0; i < 7; i++) {
      this.currentWeekDates.push(startOfWeek + i)
    }
  }

  formatDisplayDate(): string {
    const dateObj = new Date(this.date)
    const month = (dateObj.getMonth() + 1).toString().padStart(2, '0')
    const day = dateObj.getDate().toString().padStart(2, '0')
    return `${month}.${day} 计数`
  }

  getStatusIcon(): string {
    return this.status === 'completed' ? '✅' : '📝'
  }

  getStatusText(): string {
    return this.status === 'completed' ? '作业做完了' : '做了，准备抄了'
  }

  async saveRecord() {
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
        note: this.note,
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
      this.getUIContext().getRouter().back()
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
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })

        Blank()
      }
      .width('100%')
      .padding(16)

      // 状态图标
      Text(this.getStatusIcon())
        .fontSize(60)
        .margin({ top: 40, bottom: 20 })

      // 状态文字
      Text(this.getStatusText())
        .fontSize(24)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 40 })

      // 日期显示
      Row() {
        Text(this.formatDisplayDate())
          .fontSize(16)
          .fontColor('#999999')

        Blank()

        Text('日历')
          .fontSize(16)
          .fontColor('#999999')
      }
      .width('90%')
      .margin({ bottom: 20 })

      // 周日期显示
      Row() {
        ForEach(this.weekDays, (day: string, index: number) => {
          Column() {
            Text(day)
              .fontSize(12)
              .fontColor('#666666')
              .margin({ bottom: 4 })

            Text(this.currentWeekDates[index]?.toString() || '')
              .fontSize(14)
              .fontColor('#999999')

            if (this.currentWeekDates[index] === new Date(this.date).getDate()) {
              Circle()
                .width(4)
                .height(4)
                .fill(this.status === 'completed' ? '#00FF00' : '#FFA500')
                .margin({ top: 4 })
            }
          }
          .width('14.28%')
          .alignItems(HorizontalAlign.Center)
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 40 })

      // 输入框
      Column() {
        TextInput({ placeholder: '写点什么...' })
          .placeholderColor('#666666')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .backgroundColor('#1A1A1A')
          .borderRadius(8)
          .padding(12)
          .onChange((value: string) => {
            this.note = value
          })
          .onClick(() => {
            // 跳转到文字输入页面
            this.getUIContext().getRouter().pushNamedRoute({
              name: 'pages/NoteInput',
              params: {
                text: this.note,
                date: this.date,
                status: this.status
              }
            })
          })
      }
      .width('90%')
      .margin({ bottom: 40 })

      // 确认按钮
      Button('✓')
        .fontSize(24)
        .fontColor('#FFFFFF')
        .backgroundColor('#FFA500')
        .width(60)
        .height(60)
        .borderRadius(30)
        .onClick(() => {
          this.saveRecord()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}