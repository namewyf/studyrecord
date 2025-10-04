// Router is now accessed through UIContext
// PromptAction is now accessed through UIContext
import common from '@ohos.app.ability.common'
import { ActionDialog } from '../components/ActionDialog'
import { CalendarView } from '../components/CalendarView'
import { StudyRecord, Notebook, RouterParams, MonthInfo } from '../models/types'
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
  @State notebook: Notebook = {
    id: '',
    title: '',
    icon: '',
    checkInOptions: [],
    items: [],
    createdAt: Date.now()
  }
  @State currentTab: 'calendar' | 'records' = 'calendar'
  @State viewMode: 'month' | 'year' = 'month'
  @State showMonthPicker: boolean = false
  @State notebookCreatedDate: Date = new Date()
  dialogController: CustomDialogController = new CustomDialogController({
    builder: ActionDialog({
      notebookId: this.notebook.id,
      onOptionSelected: (optionId: string): void => this.onOptionSelected(optionId)
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
      console.info(`All records loaded: ${allRecords.length}`)
      console.info(`All records: ${JSON.stringify(allRecords)}`)
      // Filter records by notebook ID
      this.records = allRecords.filter(r => r.notebookId === this.notebook.id)
      console.info(`Loaded ${this.records.length} records for notebook ${this.notebook.id}`)
      console.info(`Filtered records: ${JSON.stringify(this.records)}`)
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

  onOptionSelected(optionId: string) {
    this.dialogController.close()
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RecordDetail',
      params: {
        date: this.selectedDate,
        optionId: optionId,
        notebookId: this.notebook.id
      }
    })
  }

  getMonthRecordsCount(month: number, year?: number): number {
    const targetYear = year !== undefined ? year : this.currentYear
    return this.records.filter(r => {
      const recordDate = new Date(r.date)
      return recordDate.getFullYear() === targetYear && recordDate.getMonth() + 1 === month
    }).length
  }


  getAvailableMonths(): MonthInfo[] {
    const months: MonthInfo[] = []
    const startDate = this.notebookCreatedDate
    const endDate = new Date()

    let current = new Date(startDate.getFullYear(), startDate.getMonth(), 1)
    const end = new Date(endDate.getFullYear(), endDate.getMonth(), 1)

    while (current <= end) {
      const year = current.getFullYear()
      const month = current.getMonth() + 1
      const count = this.getMonthRecordsCount(month, year)
      const monthInfo: MonthInfo = {
        year: year,
        month: month,
        count: count
      }
      months.push(monthInfo)
      current.setMonth(current.getMonth() + 1)
    }

    return months.reverse()
  }

  getSortedRecords(): StudyRecord[] {
    return [...this.records].sort((a, b) => {
      return new Date(b.date).getTime() - new Date(a.date).getTime()
    })
  }

  getOptionName(optionId: string): string {
    const option = this.notebook.checkInOptions.find(opt => opt.id === optionId)
    return option ? option.name : ''
  }

  build() {
    Stack() {
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
              .fontColor(this.currentTab === 'calendar' ? '#FFFFFF' : '#666666')
              .onClick(() => {
                this.currentTab = 'calendar'
              })
            Text('记录')
              .fontSize(18)
              .fontColor(this.currentTab === 'records' ? '#FFFFFF' : '#666666')
              .margin({ left: 40 })
              .onClick(() => {
                this.currentTab = 'records'
              })
          }

          Image($r('app.media.more'))
            .width(24)
            .height(24)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16, top: 40 })
        .justifyContent(FlexAlign.SpaceBetween)

        // 内容区域
        if (this.currentTab === 'calendar') {
          this.buildCalendarView()
        } else if (this.currentTab === 'records') {
          this.buildRecordsView()
        }

        // 底部按钮
        if (this.currentTab === 'calendar') {
          // 日历tab的底部按钮
          Row() {
            Column() {
              Text('月')
                .fontSize(16)
                .fontColor(this.viewMode === 'month' ? '#FFFFFF' : '#666666')
            }
            .layoutWeight(1)
            .onClick(() => {
              this.viewMode = 'month'
            })

            Column() {
              Text('年')
                .fontSize(16)
                .fontColor(this.viewMode === 'year' ? '#FFFFFF' : '#666666')
            }
            .layoutWeight(1)
            .onClick(() => {
              this.viewMode = 'year'
            })

            Column() {
              Button('打卡')
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
          .backgroundColor('#1A1A1A')
          .padding({ top: 10 })
        }
      }
      .width('100%')
      .height('100%')

      // 月份选择器 (overlay)
      if (this.showMonthPicker) {
        this.buildMonthPicker()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  buildCalendarView() {
    Column() {
      // 月份/年份选择
      Row() {
        if (this.viewMode === 'month') {
          Text(`${this.currentMonth.toString().padStart(2, '0')} 月`)
            .fontSize(20)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
          Image($r('app.media.arrow_down'))
            .width(16)
            .height(16)
            .margin({ left: 8 })
        } else {
          Text(`${this.currentYear} 年`)
            .fontSize(20)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
          Image($r('app.media.arrow_down'))
            .width(16)
            .height(16)
            .margin({ left: 8 })
        }
      }
      .margin({ top: 20, bottom: 10 })
      .onClick(() => {
        if (this.viewMode === 'month') {
          this.showMonthPicker = true
        }
      })

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

      // 日历/年视图
      if (this.viewMode === 'month') {
        CalendarView({
          currentMonth: this.currentMonth,
          currentYear: this.currentYear,
          records: this.records,
          onDateClick: (day: number): void => this.onDateClick(day)
        })
        .padding({ left: 16, right: 16 })
      } else {
        this.buildYearView()
      }
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  buildYearView() {
    Column() {
      Grid() {
        ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], (month: number) => {
          GridItem() {
            Column() {
              Text(month.toString())
                .fontSize(16)
                .fontColor('#FFFFFF')
                .margin({ bottom: 8 })

              if (this.getMonthRecordsCount(month) > 0) {
                Text(this.notebook.icon)
                  .fontSize(24)
                  .margin({ bottom: 4 })
              } else {
                Text('·')
                  .fontSize(24)
                  .fontColor('#333333')
                  .margin({ bottom: 4 })
              }
            }
            .width('100%')
            .height(60)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.currentMonth = month
              this.viewMode = 'month'
            })
          }
        }, (month: number) => month.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(20)
      .columnsGap(20)
      .padding(16)
      .width('100%')

      // 分享日历按钮
      Button() {
        Row() {
          Text('分享日历')
            .fontSize(16)
            .fontColor('#FFFFFF')
          Text(' >')
            .fontSize(16)
            .fontColor('#666666')
        }
      }
      .backgroundColor('transparent')
      .margin({ top: 40 })
    }
    .width('100%')
  }


  @Builder
  buildRecordsView() {
    Column() {
      Text(`${this.currentYear} 年`)
        .fontSize(20)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
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

      // 记录列表
      List({ space: 20 }) {
        ForEach(this.getSortedRecords(), (record: StudyRecord) => {
          ListItem() {
            Column() {
              // 顶部：日期和操作按钮
              Row() {
                // 左侧图标和日期
                Row() {
                  Text(this.notebook.icon)
                    .fontSize(32)
                    .margin({ right: 12 })

                  Text(`${new Date(record.date).getDate()}. /${new Date(record.date).getMonth() + 1}月`)
                    .fontSize(18)
                    .fontColor('#999999')
                }

                Blank()

                // 右侧操作按钮
                Row({ space: 16 }) {
                  Image($r('app.media.startIcon'))
                    .width(24)
                    .height(24)
                    .fillColor('#FFFFFF')

                  Image($r('app.media.more'))
                    .width(24)
                    .height(24)
                }
              }
              .width('100%')
              .margin({ bottom: 20 })

              // 中间：选项文字（白色）
              Text(this.getOptionName(record.optionId || ''))
                .fontSize(24)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .margin({ bottom: 12 })

              // 底部：具体记录内容（灰色）
              if (record.note && record.note.length > 0) {
                Text(record.note)
                  .fontSize(18)
                  .fontColor('#999999')
                  .width('100%')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 20, bottom: 20 })
            .backgroundColor('#1A1A1A')
            .borderRadius(12)
            .onClick(() => {
              // 跳转到记录详情
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/RecordDetail',
                params: {
                  date: record.date,
                  optionId: record.optionId,
                  notebookId: this.notebook.id
                }
              })
            })
          }
        }, (record: StudyRecord) => record.date + record.status)
      }
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  buildMonthPicker() {
    Column() {
      Blank()
        .onClick(() => {
          this.showMonthPicker = false
        })

      Column() {
        // 月份列表
        List() {
          ForEach(this.getAvailableMonths(), (item: MonthInfo) => {
            ListItem() {
              Column() {
                if (item.month === 1) {
                  Text(item.year.toString())
                    .fontSize(14)
                    .fontColor('#666666')
                    .alignSelf(ItemAlign.Start)
                    .margin({ top: 16, bottom: 8, left: 16 })
                }

                Row() {
                  Text(`${item.month} 月`)
                    .fontSize(16)
                    .fontColor('#FFFFFF')
                    .layoutWeight(1)

                  if (item.count > 0) {
                    Text(this.notebook.icon)
                      .fontSize(20)
                      .margin({ right: 8 })
                  }

                  Text(item.count.toString())
                    .fontSize(16)
                    .fontColor('#FFFFFF')

                  Image($r('app.media.arrow_right'))
                    .width(16)
                    .height(16)
                    .margin({ left: 8 })
                }
                .width('100%')
                .padding(16)
                .onClick(() => {
                  this.currentMonth = item.month
                  this.currentYear = item.year
                  this.showMonthPicker = false
                })
              }
            }
          }, (item: MonthInfo) => `${item.year}-${item.month}`)
        }
        .backgroundColor('#1A1A1A')
        .borderRadius({ topLeft: 16, topRight: 16 })
        .padding({ bottom: 16 })

        // 收起按钮
        Column() {
          Text('收起')
            .fontSize(16)
            .fontColor('#FFFFFF')
          Image($r('app.media.arrow_up'))
            .width(16)
            .height(16)
            .margin({ top: 8 })
        }
        .width('100%')
        .height(60)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#1A1A1A')
        .onClick(() => {
          this.showMonthPicker = false
        })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
  }

}
