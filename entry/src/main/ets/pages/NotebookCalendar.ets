// Router is now accessed through UIContext
// PromptAction is now accessed through UIContext
import common from '@ohos.app.ability.common'
import { ActionDialog } from '../components/ActionDialog'
import { CalendarView } from '../components/CalendarView'
import { StudyRecord, Notebook, RouterParams } from '../models/types'
import { StorageService } from '../services/StorageService'

@Entry
@Component
struct NotebookCalendar {
  @State currentMonth: number = new Date().getMonth() + 1
  @State currentYear: number = new Date().getFullYear()
  @State currentDate: Date = new Date()
  @State records: StudyRecord[] = []
  @State showActionDialog: boolean = false
  @State selectedDate: string = ''
  @State notebook: Notebook = { id: '', title: '', icon: '' }
  dialogController: CustomDialogController = new CustomDialogController({
    builder: ActionDialog({
      onCompleted: (): void => this.onActionSelect('completed'),
      onCopied: (): void => this.onActionSelect('copied')
    }),
    customStyle: true,
    alignment: DialogAlignment.Bottom
  })

  aboutToAppear() {
    const params = this.getUIContext().getRouter().getParams() as RouterParams
    if (params?.notebook) {
      this.notebook = params.notebook
    }
    this.loadRecords()
  }

  onPageShow() {
    this.loadRecords()
  }

  async loadRecords() {
    try {
      const storageService = StorageService.getInstance()
      const context = getContext(this) as common.UIAbilityContext
      await storageService.init(context)
      const allRecords = await storageService.loadRecords()
      // Filter records by notebook ID
      this.records = allRecords.filter(r => r.notebookId === this.notebook.id)
      console.info(`Loaded ${this.records.length} records for notebook ${this.notebook.id}`)
    } catch (error) {
      console.error('Failed to load records:', error)
      this.records = []
    }
  }

  formatDate(day: number): string {
    const month = this.currentMonth.toString().padStart(2, '0')
    const dayStr = day.toString().padStart(2, '0')
    return `${this.currentYear}-${month}-${dayStr}`
  }

  onDateClick(day: number): void {
    this.selectedDate = this.formatDate(day)
    this.dialogController.open()
  }

  onActionSelect(status: 'completed' | 'copied') {
    this.dialogController.close()
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RecordDetail',
      params: {
        date: this.selectedDate,
        status: status,
        notebookId: this.notebook.id
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
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })

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

      Text(this.notebook.title)
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

      // 日历视图组件
      CalendarView({
        currentMonth: this.currentMonth,
        currentYear: this.currentYear,
        records: this.records,
        onDateClick: (day: number): void => this.onDateClick(day)
      })
      .padding({ left: 16, right: 16 })

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

}
