import { StudyRecord } from '../models/types'

@Component
export struct CalendarView {
  @Prop currentMonth: number
  @Prop currentYear: number
  @Prop records: StudyRecord[]
  onDateClick: (day: number) => void = () => {}

  private weekDays: string[] = ['日', '一', '二', '三', '四', '五', '六']

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

  isToday(day: number): boolean {
    const today = new Date()
    return this.currentYear === today.getFullYear() &&
           this.currentMonth === today.getMonth() + 1 &&
           day === today.getDate()
  }

  build() {
    Column() {
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
    }
    .width('100%')
  }

  @Builder
  buildDayItem(day: number) {
    Column() {
      Stack() {
        // 如果是今天，显示白色圆圈背景
        if (this.isToday(day)) {
          Circle()
            .width(36)
            .height(36)
            .fill('#333333')
        }

        Text(day.toString())
          .fontSize(16)
          .fontColor(this.hasRecord(this.formatDate(day)) ? '#FFFFFF' :
                     this.isToday(day) ? '#FFFFFF' : '#666666')
          .fontWeight(this.isToday(day) ? FontWeight.Medium : FontWeight.Normal)
      }

      // 记录指示点
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