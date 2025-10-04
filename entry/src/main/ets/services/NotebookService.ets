import { Notebook, CheckInOption, NotebookItem, StudyRecord } from '../models/types'
import { StorageService } from './StorageService'

/**
 * 打卡本业务逻辑服务
 */
export class NotebookService {

  /**
   * 生成唯一ID（时间戳 + 随机数）
   */
  static generateId(prefix: string = 'id'): string {
    const timestamp = Date.now()
    const random = Math.random().toString(36).substr(2, 9)
    return `${prefix}_${timestamp}_${random}`
  }

  /**
   * 创建打卡选项
   */
  static createCheckInOption(
    name: string,
    icon: string,
    color?: string,
    order?: number
  ): CheckInOption {
    return {
      id: NotebookService.generateId('opt'),
      name: name,
      icon: icon,
      color: color,
      order: order !== undefined ? order : Date.now(),
      createdAt: Date.now()
    }
  }

  /**
   * 创建打卡事项
   */
  static createNotebookItem(
    name: string,
    icon: string,
    notebookId: string,
    order?: number
  ): NotebookItem {
    return {
      id: NotebookService.generateId('item'),
      name: name,
      icon: icon,
      notebookId: notebookId,
      order: order !== undefined ? order : Date.now(),
      createdAt: Date.now()
    }
  }

  /**
   * 创建打卡本
   */
  static createNotebook(
    title: string,
    icon: string,
    checkInOptions: CheckInOption[],
    items: NotebookItem[],
    color?: string
  ): Notebook {
    const notebookId = NotebookService.generateId('notebook')

    // 设置事项的 notebookId
    items.forEach(item => {
      item.notebookId = notebookId
    })

    return {
      id: notebookId,
      title: title,
      icon: icon,
      color: color,
      checkInOptions: checkInOptions,
      items: items,
      createdAt: Date.now()
    }
  }

  /**
   * 创建打卡记录
   */
  static createStudyRecord(
    date: string,
    notebookId: string,
    itemId: string,
    optionId: string,
    note?: string
  ): StudyRecord {
    return {
      id: NotebookService.generateId('record'),
      date: date,
      notebookId: notebookId,
      itemId: itemId,
      optionId: optionId,
      note: note,
      createdAt: Date.now()
    }
  }

  /**
   * 获取打卡记录对应的选项信息
   */
  static async getRecordOption(record: StudyRecord): Promise<CheckInOption | null> {
    try {
      const storageService = StorageService.getInstance()
      const notebook = await storageService.getNotebookById(record.notebookId)

      if (!notebook) {
        console.warn(`Notebook not found: ${record.notebookId}`)
        return null
      }

      const option = notebook.checkInOptions.find(opt => opt.id === record.optionId)

      if (!option) {
        console.warn(`Option not found: ${record.optionId} in notebook ${notebook.id}`)
        return null
      }

      return option
    } catch (error) {
      console.error('Error getting record option:', error)
      return null
    }
  }

  /**
   * 获取打卡本的所有选项（按 order 排序）
   */
  static async getNotebookOptions(notebookId: string): Promise<CheckInOption[]> {
    try {
      const storageService = StorageService.getInstance()
      const notebook = await storageService.getNotebookById(notebookId)

      if (!notebook) {
        console.warn(`Notebook not found: ${notebookId}`)
        return []
      }

      // 按 order 排序
      return notebook.checkInOptions.sort((a, b) => a.order - b.order)
    } catch (error) {
      console.error('Error getting notebook options:', error)
      return []
    }
  }

  /**
   * 获取打卡本的所有事项（按 order 排序）
   */
  static async getNotebookItems(notebookId: string): Promise<NotebookItem[]> {
    try {
      const storageService = StorageService.getInstance()
      const notebook = await storageService.getNotebookById(notebookId)

      if (!notebook) {
        console.warn(`Notebook not found: ${notebookId}`)
        return []
      }

      // 按 order 排序
      return notebook.items.sort((a, b) => a.order - b.order)
    } catch (error) {
      console.error('Error getting notebook items:', error)
      return []
    }
  }

  /**
   * 添加选项到打卡本
   */
  static async addOptionToNotebook(
    notebookId: string,
    option: CheckInOption
  ): Promise<void> {
    const storageService = StorageService.getInstance()
    await storageService.addOptionToNotebook(notebookId, option)
  }

  /**
   * 删除打卡本的选项
   */
  static async deleteOptionFromNotebook(
    notebookId: string,
    optionId: string
  ): Promise<void> {
    const storageService = StorageService.getInstance()
    await storageService.deleteOptionFromNotebook(notebookId, optionId)
  }

  /**
   * 更新打卡本的选项
   */
  static async updateNotebookOption(
    notebookId: string,
    optionId: string,
    updates: Partial<CheckInOption>
  ): Promise<void> {
    const storageService = StorageService.getInstance()
    const notebook = await storageService.getNotebookById(notebookId)

    if (!notebook) {
      throw new Error(`Notebook not found: ${notebookId}`)
    }

    const optionIndex = notebook.checkInOptions.findIndex(opt => opt.id === optionId)
    if (optionIndex === -1) {
      throw new Error(`Option not found: ${optionId}`)
    }

    // 更新选项（ArkTS不支持对象展开，手动更新）
    const oldOption = notebook.checkInOptions[optionIndex]
    notebook.checkInOptions[optionIndex] = {
      id: oldOption.id,
      name: updates.name !== undefined ? updates.name : oldOption.name,
      icon: updates.icon !== undefined ? updates.icon : oldOption.icon,
      color: updates.color !== undefined ? updates.color : oldOption.color,
      order: updates.order !== undefined ? updates.order : oldOption.order,
      createdAt: oldOption.createdAt
    }

    notebook.updatedAt = Date.now()
    await storageService.updateNotebook(notebook)
  }
}
