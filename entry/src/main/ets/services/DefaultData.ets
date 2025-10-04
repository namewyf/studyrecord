import { Notebook, CheckInOption } from '../models/types'
import { NotebookService } from './NotebookService'

/**
 * 默认数据生成器
 * 用于首次安装时创建默认打卡本
 */
export class DefaultData {

  /**
   * 创建默认的打卡选项（难度评价）
   */
  static createDifficultyOptions(): CheckInOption[] {
    return [
      NotebookService.createCheckInOption(
        '小菜一碟',
        'checkmark_circle',
        '#00FF00',
        1
      ),
      NotebookService.createCheckInOption(
        '有点难度',
        'exclamationmark_triangle',
        '#FFA500',
        2
      )
    ]
  }

  /**
   * 创建默认的打卡本列表
   */
  static createDefaultNotebooks(): Notebook[] {
    const notebooks: Notebook[] = []

    // 1. 数学试卷打卡
    const paperNotebook = NotebookService.createNotebook(
      '数学试卷打卡',
      'doc_text',
      DefaultData.createDifficultyOptions(),
      [
        NotebookService.createNotebookItem('打卡事项一', 'circle', '', 1)
      ],
      '#4CAF50'
    )
    notebooks.push(paperNotebook)

    // 2. 教辅练习打卡
    const exerciseNotebook = NotebookService.createNotebook(
      '教辅练习打卡',
      'book',
      DefaultData.createDifficultyOptions(),
      [
        NotebookService.createNotebookItem('打卡事项一', 'circle', '', 1)
      ],
      '#FF4081'
    )
    notebooks.push(exerciseNotebook)

    // 3. 新用户引导
    const onboardingNotebook = NotebookService.createNotebook(
      '新用户看一眼，就看一眼',
      'person_wave_2',
      DefaultData.createDifficultyOptions(),
      [
        NotebookService.createNotebookItem('打卡事项一', 'circle', '', 1)
      ],
      '#FF9800'
    )
    notebooks.push(onboardingNotebook)

    return notebooks
  }
}
