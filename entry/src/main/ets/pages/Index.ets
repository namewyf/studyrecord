// Router is now accessed through UIContext
// PromptAction is now accessed through UIContext
import common from '@ohos.app.ability.common'
import { Notebook } from '../models/types'
import { StorageService } from '../services/StorageService'

@Entry
@Component
struct Index {
  @State notebooks: Notebook[] = []
  @State isLoading: boolean = true

  // 默认打卡本列表（首次使用时）
  private defaultNotebooks: Notebook[] = [
    {
      id: 'paper',
      title: '数学试卷打卡',
      icon: '📝',
      color: '#4CAF50'
    },
    {
      id: 'exercise',
      title: '教辅练习打卡',
      icon: '📚',
      color: '#FF4081'
    },
    {
      id: 'onboarding',
      title: '新用户看一眼，就看一眼',
      icon: '🙋',
      color: '#FF9800'
    }
  ]

  aboutToAppear() {
    this.loadNotebooks()
  }

  onPageShow() {
    this.loadNotebooks()
  }

  async loadNotebooks() {
    try {
      const storageService = StorageService.getInstance()
      const context = getContext(this) as common.UIAbilityContext
      await storageService.init(context)

      let notebooks = await storageService.loadNotebooks()

      // 如果是首次使用，保存默认打卡本
      if (notebooks.length === 0) {
        await storageService.saveNotebooks(this.defaultNotebooks)
        notebooks = this.defaultNotebooks
      }

      this.notebooks = notebooks
      this.isLoading = false
      console.info(`Loaded ${this.notebooks.length} notebooks`)
    } catch (error) {
      console.error('Failed to load notebooks:', error)
      this.notebooks = this.defaultNotebooks
      this.isLoading = false
    }
  }

  navigateToNotebook(notebook: Notebook) {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/NotebookCalendar',
      params: {
        notebook: notebook
      }
    })
  }

  navigateToCreateNotebook() {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/CreateNotebook'
    })
  }

  @Builder
  notebookCard(notebook: Notebook) {
    Column() {
      Text(notebook.icon)
        .fontSize(64)
        .margin({ bottom: 20 })

      Text(notebook.title)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
    }
    .width('45%')
    .height(200)
    .backgroundColor('#1A1A1A')
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.navigateToNotebook(notebook))
  }

  @Builder
  createNotebookCard() {
    Column() {
      Text('+')
        .fontSize(64)
        .fontColor('#666666')
        .margin({ bottom: 20 })

      Text('创建打卡本')
        .fontSize(16)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
    }
    .width('45%')
    .height(200)
    .backgroundColor('#1A1A1A')
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.navigateToCreateNotebook())
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('学霸打卡')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)

        Image($r('app.media.more'))
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16, top: 40 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      // 打卡本网格
      if (this.isLoading) {
        Text('加载中...')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ top: 100 })
      } else {
        Grid() {
          ForEach(this.notebooks, (notebook: Notebook) => {
            GridItem() {
              this.notebookCard(notebook)
            }
          }, (notebook: Notebook) => notebook.id)

          // 创建按钮
          GridItem() {
            this.createNotebookCard()
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(20)
        .columnsGap(20)
        .width('100%')
        .padding({ left: 16, right: 16, top: 40 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
