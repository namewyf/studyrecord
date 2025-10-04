// Router is now accessed through UIContext
// PromptAction is now accessed through UIContext
import common from '@ohos.app.ability.common'
import { Notebook, NotebookItem } from '../models/types'
import { StorageService } from '../services/StorageService'
import { NotebookService } from '../services/NotebookService'
import { DefaultData } from '../services/DefaultData'
import { SlideButton } from '../components/SlideButton'

@Entry
@Component
struct CreateNotebook {
  @State notebookName: string = ''
  @State notebookIcon: string = '🚴'
  @State itemNames: string[] = ['打卡事项一', '打卡事项二']
  @State itemIcons: string[] = ['✳️', '❌']

  private availableIcons: string[] = ['🚴', '📗', '💕', '🙋', '⚽', '🎮', '🎵', '✈️', '🍕', '☕']
  private availableItemIcons: string[] = ['✳️', '❌', '✅', '⭐', '❤️', '🔥', '💡', '📌']
  private maxNameLength: number = 12

  aboutToAppear() {
    // 随机选择一个初始图标
    this.notebookIcon = this.availableIcons[Math.floor(Math.random() * this.availableIcons.length)]
  }

  refreshIcon() {
    // 随机更换图标
    const currentIndex = this.availableIcons.indexOf(this.notebookIcon)
    let newIndex = Math.floor(Math.random() * this.availableIcons.length)
    while (newIndex === currentIndex) {
      newIndex = Math.floor(Math.random() * this.availableIcons.length)
    }
    this.notebookIcon = this.availableIcons[newIndex]
  }

  addItem() {
    const newName = `打卡事项${this.itemNames.length + 1}`
    const newIcon = this.availableItemIcons[this.itemNames.length % this.availableItemIcons.length]
    this.itemNames.push(newName)
    this.itemIcons.push(newIcon)
  }

  deleteItem(index: number) {
    this.itemNames.splice(index, 1)
    this.itemIcons.splice(index, 1)
  }

  async createNotebook() {
    if (!this.notebookName.trim()) {
      this.getUIContext().getPromptAction().showToast({
        message: '请输入打卡本名称',
        duration: 2000
      })
      return
    }

    try {
      const storageService = StorageService.getInstance()
      const context = getContext(this) as common.UIAbilityContext
      await storageService.init(context)

      // 创建打卡本的ID
      const notebookId = NotebookService.generateId('notebook')

      // 创建打卡事项
      const items: NotebookItem[] = []
      for (let i = 0; i < this.itemNames.length; i++) {
        const item = NotebookService.createNotebookItem(
          this.itemNames[i],
          this.itemIcons[i],
          notebookId,
          i + 1
        )
        items.push(item)
      }

      // 创建默认选项
      const checkInOptions = DefaultData.createDifficultyOptions()

      // 创建新打卡本
      const newNotebook: Notebook = {
        id: notebookId,
        title: this.notebookName,
        icon: this.notebookIcon,
        checkInOptions: checkInOptions,
        items: items,
        createdAt: Date.now()
      }

      await storageService.saveNotebook(newNotebook)

      this.getUIContext().getPromptAction().showToast({
        message: '打卡本创建成功',
        duration: 2000
      })

      // 返回首页
      this.getUIContext().getRouter().back()
    } catch (error) {
      console.error('Failed to create notebook:', error)
      this.getUIContext().getPromptAction().showToast({
        message: '创建失败，请重试',
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

      Scroll() {
        Column() {
          // 图标选择
          Column() {
            Text(this.notebookIcon)
              .fontSize(80)
              .margin({ bottom: 20 })

            Row() {
              Text('打卡图标')
                .fontSize(16)
                .fontColor('#FFFFFF')

              Blank()

              // 刷新图标按钮
              Image($r('app.media.startIcon'))
                .width(20)
                .height(20)
                .fillColor('#999999')
                .onClick(() => {
                  this.refreshIcon()
                })
            }
            .width('90%')
            .margin({ bottom: 40 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 20 })

          // 打卡本名称输入
          Column() {
            Row() {
              Text('打卡本名称')
                .fontSize(16)
                .fontColor('#FFFFFF')
            }
            .width('100%')
            .margin({ bottom: 10 })

            Column() {
              TextInput({ placeholder: '记录什么呢…' })
                .placeholderColor('#666666')
                .fontColor('#FFFFFF')
                .fontSize(16)
                .backgroundColor('transparent')
                .border({ width: 0 })
                .onChange((value: string) => {
                  if (value.length <= this.maxNameLength) {
                    this.notebookName = value
                  }
                })

              Row() {
                Blank()
                Text(`${this.notebookName.length}/${this.maxNameLength}`)
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .width('100%')
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#1A1A1A')
            .borderRadius(8)
          }
          .width('90%')
          .alignSelf(ItemAlign.Center)
          .margin({ bottom: 40 })

          // 打卡事项
          Column() {
            Row() {
              Text('打卡事项')
                .fontSize(16)
                .fontColor('#FFFFFF')
            }
            .width('100%')
            .margin({ bottom: 20 })

            // 事项列表
            ForEach(this.itemNames, (itemName: string, index: number) => {
              Row() {
                // 拖动手柄
                Text('::')
                  .fontSize(20)
                  .fontColor('#666666')
                  .margin({ right: 16 })

                // 图标
                Text(this.itemIcons[index])
                  .fontSize(32)
                  .margin({ right: 16 })

                // 名称
                Text(itemName)
                  .fontSize(16)
                  .fontColor('#FFFFFF')
                  .layoutWeight(1)

                // 右箭头
                Image($r('app.media.arrow_down'))
                  .width(16)
                  .height(16)
                  .fillColor('#666666')
                  .rotate({ angle: -90 })
              }
              .width('100%')
              .height(60)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#1A1A1A')
              .borderRadius(8)
              .margin({ bottom: 12 })
              .gesture(
                LongPressGesture()
                  .onAction(() => {
                    // 长按删除
                    this.deleteItem(index)
                  })
              )
            }, (itemName: string, index: number) => `${index}_${itemName}`)

            // 新增事项按钮
            Row() {
              Image($r('app.media.startIcon'))
                .width(24)
                .height(24)
                .fillColor('#666666')
                .margin({ right: 12 })

              Text('新增打卡事项')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .height(60)
            .justifyContent(FlexAlign.Start)
            .padding({ left: 12 })
            .onClick(() => {
              this.addItem()
            })
          }
          .width('90%')
          .alignSelf(ItemAlign.Center)
          .margin({ bottom: 40 })

          // 滑动创建按钮
          SlideButton({
            text: '滑动创建打卡本',
            onConfirm: () => {
              this.createNotebook()
            }
          })
          .width('90%')
          .alignSelf(ItemAlign.Center)
          .margin({ bottom: 60 })
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
