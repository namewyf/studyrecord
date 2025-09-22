// Router is now accessed through UIContext
// PromptAction is now accessed through UIContext
import preferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'
import { ActionDialog } from '../components/ActionDialog'
import { StudyRecord } from '../models/types'

@Entry
@Component
struct Index {
  @State currentMonth: number = new Date().getMonth() + 1
  @State currentYear: number = new Date().getFullYear()
  @State currentDate: Date = new Date()
  @State records: StudyRecord[] = []
  @State showActionDialog: boolean = false
  @State selectedDate: string = ''

  private weekDays: string[] = ['日', '一', '二', '三', '四', '五', '六']
  dialogController: CustomDialogController = new CustomDialogController({
    builder: ActionDialog({
      onCompleted: (): void => this.onActionSelect('completed'),
      onCopied: (): void => this.onActionSelect('copied')
    }),
    customStyle: true,
    alignment: DialogAlignment.Bottom
  })

  aboutToAppear() {
    this.loadRecords()
  }

  onPageShow() {
    this.loadRecords()
  }

  async loadRecords() {
    try {
      const dataPreferences = await preferences.getPreferences((this.getUIContext().getHostContext() as common.UIAbilityContext), 'study_records')
      const recordsStr = await dataPreferences.get('records', '[]') as string
      this.records = JSON.parse(recordsStr)
    } catch (error) {
      console.error('Failed to load records:', error)
      this.records = []
    }
  }

  getDaysInMonth(year: number, month: number): number {
    return new Date(year, month, 0).getDate()
  }

  getFirstDayOfMonth(year: number, month: number): number {
    return new Date(year, month - 1, 1).getDay()
  }

  formatDate(day: number): string {
    const month = this.currentMonth.toString().padStart(2, '0')
    const dayStr = day.toString().padStart(2, '0')
    return `${this.currentYear}-${month}-${dayStr}`
  }

  hasRecord(date: string): StudyRecord | undefined {
    return this.records.find(r => r.date === date)
  }

  onDateClick(day: number) {
    this.selectedDate = this.formatDate(day)
    this.dialogController.open()
  }

  onActionSelect(status: 'completed' | 'copied') {
    this.dialogController.close()
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RecordDetail',
      params: {
        date: this.selectedDate,
        status: status
      }
    })
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .visibility(Visibility.Hidden)

        Row() {
          Text('日历')
            .fontSize(18)
            .fontColor('#FFFFFF')
          Text('统计')
            .fontSize(18)
            .fontColor('#666666')
            .margin({ left: 40 })
          Text('记录')
            .fontSize(18)
            .fontColor('#666666')
            .margin({ left: 40 })
        }

        Image($r('app.media.more'))
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)

      // 月份选择
      Row() {
        Text(`${this.currentMonth.toString().padStart(2, '0')} 月`)
          .fontSize(20)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
        Image($r('app.media.arrow_down'))
          .width(16)
          .height(16)
          .margin({ left: 8 })
      }
      .margin({ top: 20, bottom: 10 })

      Text('今年写过多少作业？')
        .fontSize(16)
        .fontColor('#999999')
        .margin({ bottom: 10 })

      Row() {
        Text(this.records.length.toString())
          .fontSize(32)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
        Text(' *')
          .fontSize(20)
          .fontColor('#666666')
      }
      .margin({ bottom: 30 })

      // 星期标题
      Row() {
        ForEach(this.weekDays, (day: string) => {
          Text(day)
            .width('14.28%')
            .textAlign(TextAlign.Center)
            .fontSize(14)
            .fontColor('#666666')
        })
      }
      .width('100%')
      .margin({ bottom: 10 })

      // 日历网格
      Column() {
        this.buildCalendarGrid()
      }
      .width('100%')

      // 底部按钮
      Row() {
        Column() {
          Text('月')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .layoutWeight(1)

        Column() {
          Text('年')
            .fontSize(16)
            .fontColor('#666666')
        }
        .layoutWeight(1)

        Column() {
          Button('计一下')
            .fontSize(16)
            .fontColor('#000000')
            .backgroundColor('#FFA500')
            .width(120)
            .height(40)
            .onClick(() => {
              const today = new Date()
              this.selectedDate = this.formatDate(today.getDate())
              this.dialogController.open()
            })
        }
        .layoutWeight(2)
      }
      .width('100%')
      .height(60)
      .position({ bottom: 0 })
      .backgroundColor('#1A1A1A')
      .padding({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  buildCalendarGrid() {
    Grid() {
      // 填充空白
      ForEach(Array(this.getFirstDayOfMonth(this.currentYear, this.currentMonth)).fill(0), (_: number, index?: number) => {
        GridItem() {
          Text('')
        }
      }, (item: number, index?: number) => index?.toString())

      // 填充日期
      ForEach(Array(this.getDaysInMonth(this.currentYear, this.currentMonth)).fill(0).map((_: number, i: number) => i + 1), (day: number) => {
        GridItem() {
          this.buildDayItem(day)
        }
      }, (day: number) => day.toString())
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsGap(15)
    .columnsGap(0)
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  buildDayItem(day: number) {
    Column() {
      Text(day.toString())
        .fontSize(16)
        .fontColor(this.hasRecord(this.formatDate(day)) ? '#FFFFFF' : '#666666')

      if (this.hasRecord(this.formatDate(day))) {
        Circle()
          .width(6)
          .height(6)
          .fill(this.hasRecord(this.formatDate(day))?.status === 'completed' ? '#00FF00' : '#FFA500')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.onDateClick(day))
  }
}