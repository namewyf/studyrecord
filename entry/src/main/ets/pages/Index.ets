// Router is now accessed through UIContext
// PromptAction is now accessed through UIContext
import { Notebook } from '../models/types'

@Entry
@Component
struct Index {
  @State notebooks: Notebook[] = [
    {
      id: 'reading',
      title: '今年看过多少本书?',
      icon: '📗',
      color: '#4CAF50'
    },
    {
      id: 'love',
      title: '今天做爱了吗?',
      icon: '💕',
      color: '#FF4081'
    },
    {
      id: 'onboarding',
      title: '新用户看一眼，就看一眼',
      icon: '🙋',
      color: '#FF9800'
    }
  ]

  navigateToNotebook(notebook: Notebook) {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/NotebookCalendar',
      params: {
        notebook: notebook
      }
    })
  }

  navigateToCreateNotebook() {
    // TODO: 实现创建日记本功能
    this.getUIContext().getPromptAction().showToast({
      message: '创建日记本功能待实现',
      duration: 2000
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

      Text('创建日记本')
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
        Text('心生一计')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)

        Image($r('app.media.more'))
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      // 日记本网格
      Column() {
        // 第一行：前两个日记本
        Row() {
          this.notebookCard(this.notebooks[0])
          Blank()
          this.notebookCard(this.notebooks[1])
        }
        .width('100%')
        .margin({ bottom: 20 })

        // 第二行：第三个日记本和创建按钮
        Row() {
          this.notebookCard(this.notebooks[2])
          Blank()
          this.createNotebookCard()
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
