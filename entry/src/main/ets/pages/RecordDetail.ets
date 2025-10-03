// Router is now accessed through UIContext
// PromptAction is now accessed through UIContext
import common from '@ohos.app.ability.common'
import { StudyRecord, RouterParams } from '../models/types'
import { StorageService } from '../services/StorageService'

@Entry
@Component
struct RecordDetail {
  @State date: string = ''
  @State status: string = ''
  @State note: string = ''
  @State notebookId: string = ''
  @State currentWeekDates: number[] = []
  @State records: StudyRecord[] = []

  private weekDays: string[] = ['日', '一', '二', '三', '四', '五', '六']

  aboutToAppear() {
    const params = this.getUIContext().getRouter().getParams() as RouterParams
    this.date = params?.date || ''
    this.status = params?.status || ''
    this.notebookId = params?.notebookId || ''
    this.calculateWeekDates()
    this.loadRecords()
  }

  async loadRecords() {
    try {
      const storageService = StorageService.getInstance()
      const context = getContext(this) as common.UIAbilityContext
      await storageService.init(context)
      const allRecords = await storageService.loadRecords()
      // Filter records by notebook ID
      this.records = allRecords.filter(r => r.notebookId === this.notebookId)
    } catch (error) {
      console.error('Failed to load records:', error)
      this.records = []
    }
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
    return `${month}.${day} 打卡`
  }

  hasRecord(day: number): StudyRecord | undefined {
    const dateObj = new Date(this.date)
    const year = dateObj.getFullYear()
    const month = (dateObj.getMonth() + 1).toString().padStart(2, '0')
    const dayStr = day.toString().padStart(2, '0')
    const checkDate = `${year}-${month}-${dayStr}`
    return this.records.find(r => r.date === checkDate)
  }

  getStatusIcon(): string {
    return '⏳'
  }

  getStatusText(): string {
    return '完成了作业'
  }

  async saveRecord() {
    console.info('Starting saveRecord')
    try {
      const storageService = StorageService.getInstance()
      console.info('Got StorageService instance')

      // Ensure StorageService is initialized
      const context = getContext(this) as common.UIAbilityContext
      console.info('Got UIAbility context')

      await storageService.init(context)
      console.info('StorageService initialized')

      // 创建新记录
      const newRecord: StudyRecord = {
        date: this.date,
        status: this.status as 'completed' | 'copied',
        note: this.note,
        timestamp: Date.now(),
        notebookId: this.notebookId
      }
      console.info('Created new record:', JSON.stringify(newRecord))

      // 保存记录
      await storageService.saveRecord(newRecord)
      console.info('Record saved successfully')

      this.getUIContext().getPromptAction().showToast({
        message: '记录保存成功',
        duration: 2000
      })

      // 返回主页
      this.getUIContext().getRouter().back()
    } catch (error) {
      console.error('Failed to save record - Error type:', typeof error)
      console.error('Failed to save record - Error message:', error instanceof Error ? error.message : 'Unknown error')
      console.error('Failed to save record - Full error:', JSON.stringify(error))
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
      .padding({ left: 16, right: 16, top: 56, bottom: 16 })

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
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 })

            if (this.currentWeekDates[index] === new Date(this.date).getDate()) {
              // 当前选中的日期，显示白色圆圈背景
              Stack() {
                Circle()
                  .width(36)
                  .height(36)
                  .fill('#FFFFFF')
                Text(this.currentWeekDates[index]?.toString() || '')
                  .fontSize(16)
                  .fontColor('#000000')
                  .fontWeight(FontWeight.Medium)
              }
            } else {
              Text(this.currentWeekDates[index]?.toString() || '')
                .fontSize(16)
                .fontColor('#FFFFFF')
            }

            // 显示记录指示点
            if (this.hasRecord(this.currentWeekDates[index])) {
              Circle()
                .width(6)
                .height(6)
                .fill(this.hasRecord(this.currentWeekDates[index])?.status === 'completed' ? '#FFA500' : '#FFA500')
                .margin({ top: 8 })
            } else {
              // 空白占位，保持对齐
              Text('')
                .height(6)
                .margin({ top: 8 })
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
        TextInput({ placeholder: '写写复盘心得...' })
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
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/NoteInput',
              params: {
                text: this.note,
                date: this.date,
                status: this.status,
                notebookId: this.notebookId
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