import preferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'
import { StudyRecord, Notebook, CheckInOption } from '../models/types'

export class StorageService {
  private static instance: StorageService
  private dataPreferences: preferences.Preferences | null = null
  private readonly STORE_NAME = 'study_records'
  private readonly RECORDS_KEY = 'records'
  private readonly NOTEBOOKS_KEY = 'notebooks'

  // 内存存储作为预览器的后备方案
  private memoryStorage: Map<string, string> = new Map()
  private isPreviewMode: boolean = false

  private constructor() {}

  static getInstance(): StorageService {
    if (!StorageService.instance) {
      StorageService.instance = new StorageService()
    }
    return StorageService.instance
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    console.info('StorageService.init called')
    console.info('Current isPreviewMode:', this.isPreviewMode)
    console.info('Current dataPreferences:', this.dataPreferences ? 'exists' : 'null')

    // 如果已经成功初始化preferences，直接返回
    if (this.dataPreferences && !this.isPreviewMode) {
      console.info('StorageService already initialized with preferences')
      return
    }

    // 如果已经是预览器模式，不需要重复尝试
    if (this.isPreviewMode) {
      console.info('Already in preview mode, using memory storage')
      return
    }

    // 检测是否在预览器环境
    try {
      console.info('Creating preferences with name:', this.STORE_NAME)
      this.dataPreferences = await preferences.getPreferences(context, this.STORE_NAME)
      console.info('✅ StorageService initialized successfully with PERSISTENT storage')
      console.info('✅ Data will be saved to device and persist after app restart')
      this.isPreviewMode = false
    } catch (error) {
      // 在预览器环境中，使用内存存储
      console.warn('❌ Failed to initialize preferences, using memory storage')
      console.warn('⚠️ This is likely PREVIEWER mode - data will NOT persist after refresh')
      console.warn('⚠️ To test persistence, please deploy to EMULATOR or REAL DEVICE')
      console.warn('Error details:', JSON.stringify(error, null, 2))
      this.isPreviewMode = true
      // 只在第一次初始化时设置空数组，避免清空已有数据
      if (!this.memoryStorage.has(this.RECORDS_KEY)) {
        this.memoryStorage.set(this.RECORDS_KEY, '[]')
      }
      if (!this.memoryStorage.has(this.NOTEBOOKS_KEY)) {
        this.memoryStorage.set(this.NOTEBOOKS_KEY, '[]')
      }
      console.info('StorageService initialized with memory storage (preview mode)')
    }
  }

  async saveRecords(records: StudyRecord[]): Promise<void> {
    console.info('saveRecords called with records count:', records.length)

    const recordsStr = JSON.stringify(records)

    if (this.isPreviewMode) {
      // 预览器模式：使用内存存储
      console.warn('⚠️ Using memory storage (PREVIEW MODE - data will be lost on refresh)')
      this.memoryStorage.set(this.RECORDS_KEY, recordsStr)
      console.info(`Saved ${records.length} records to memory`)
    } else {
      // 真实设备模式：使用preferences
      if (!this.dataPreferences) {
        console.error('StorageService not initialized - dataPreferences is null')
        // 尝试使用内存存储作为后备
        this.memoryStorage.set(this.RECORDS_KEY, recordsStr)
        console.warn(`⚠️ Fallback: saved ${records.length} records to memory`)
        return
      }

      try {
        console.info('Saving to persistent storage...')
        await this.dataPreferences.put(this.RECORDS_KEY, recordsStr)
        await this.dataPreferences.flush()
        console.info(`✅ Successfully saved ${records.length} records to PERSISTENT storage`)
        console.info(`✅ Data will persist after app restart`)
      } catch (error) {
        console.error('❌ Failed to save to preferences, using memory storage')
        console.error('Error details:', JSON.stringify(error, null, 2))
        // 失败时使用内存存储
        this.memoryStorage.set(this.RECORDS_KEY, recordsStr)
        console.warn(`⚠️ Fallback: saved ${records.length} records to memory`)
      }
    }
  }

  async loadRecords(): Promise<StudyRecord[]> {
    console.info('loadRecords called')

    if (this.isPreviewMode) {
      // 预览器模式：从内存加载
      console.warn('⚠️ Loading from memory storage (PREVIEW MODE)')
      const recordsStr = this.memoryStorage.get(this.RECORDS_KEY) || '[]'
      const records = JSON.parse(recordsStr) as StudyRecord[]
      console.info(`Loaded ${records.length} records from memory`)
      return records
    } else {
      // 真实设备模式：从preferences加载
      if (!this.dataPreferences) {
        console.warn('⚠️ StorageService not initialized, loading from memory')
        const recordsStr = this.memoryStorage.get(this.RECORDS_KEY) || '[]'
        const records = JSON.parse(recordsStr) as StudyRecord[]
        console.warn(`Loaded ${records.length} records from memory (fallback)`)
        return records
      }

      try {
        const recordsStr = await this.dataPreferences.get(this.RECORDS_KEY, '[]') as string
        const records = JSON.parse(recordsStr) as StudyRecord[]
        console.info(`✅ Successfully loaded ${records.length} records from PERSISTENT storage`)
        return records
      } catch (error) {
        console.error('❌ Failed to load from preferences, using memory storage')
        console.error('Error details:', JSON.stringify(error, null, 2))
        const recordsStr = this.memoryStorage.get(this.RECORDS_KEY) || '[]'
        const records = JSON.parse(recordsStr) as StudyRecord[]
        console.warn(`⚠️ Loaded ${records.length} records from memory (fallback)`)
        return records
      }
    }
  }

  async saveRecord(newRecord: StudyRecord): Promise<void> {
    console.info('saveRecord called with:', JSON.stringify(newRecord))
    try {
      const records = await this.loadRecords()
      console.info('Loaded existing records count:', records.length)

      const existingIndex = records.findIndex((r: StudyRecord) => r.date === newRecord.date)
      if (existingIndex >= 0) {
        records[existingIndex] = newRecord
        console.info(`Updated existing record for date: ${newRecord.date}`)
      } else {
        records.push(newRecord)
        console.info(`Added new record for date: ${newRecord.date}`)
      }

      await this.saveRecords(records)
      console.info('saveRecord completed successfully')
    } catch (error) {
      console.error('Failed to save record')
      console.error('Error details:', JSON.stringify(error, null, 2))
      throw new Error('Failed to save record')
    }
  }

  async deleteRecord(date: string): Promise<void> {
    try {
      const records = await this.loadRecords()
      const filteredRecords = records.filter((r: StudyRecord) => r.date !== date)

      if (filteredRecords.length < records.length) {
        await this.saveRecords(filteredRecords)
        console.info(`Deleted record for date: ${date}`)
      } else {
        console.warn(`No record found for date: ${date}`)
      }
    } catch (error) {
      console.error('Failed to delete record')
      console.error('Error details:', JSON.stringify(error, null, 2))
      throw new Error('Failed to delete record')
    }
  }

  async clear(): Promise<void> {
    console.info('Clearing all records')

    if (this.isPreviewMode) {
      // 预览器模式：清空内存
      this.memoryStorage.set(this.RECORDS_KEY, '[]')
      console.info('Cleared memory storage')
    } else {
      // 真实设备模式：清空preferences
      if (!this.dataPreferences) {
        this.memoryStorage.set(this.RECORDS_KEY, '[]')
        console.info('Cleared memory storage (fallback)')
        return
      }

      try {
        await this.dataPreferences.delete(this.RECORDS_KEY)
        await this.dataPreferences.flush()
        console.info('Cleared preferences storage')
      } catch (error) {
        console.error('Failed to clear preferences')
        console.error('Error details:', JSON.stringify(error, null, 2))
        this.memoryStorage.set(this.RECORDS_KEY, '[]')
        console.info('Cleared memory storage (fallback)')
      }
    }
  }

  // Notebook storage methods
  async saveNotebooks(notebooks: Notebook[]): Promise<void> {
    console.info('saveNotebooks called with notebooks count:', notebooks.length)
    const notebooksStr = JSON.stringify(notebooks)

    if (this.isPreviewMode) {
      this.memoryStorage.set(this.NOTEBOOKS_KEY, notebooksStr)
      console.info(`Successfully saved ${notebooks.length} notebooks to memory`)
    } else {
      if (!this.dataPreferences) {
        this.memoryStorage.set(this.NOTEBOOKS_KEY, notebooksStr)
        console.info(`Fallback: saved ${notebooks.length} notebooks to memory`)
        return
      }

      try {
        await this.dataPreferences.put(this.NOTEBOOKS_KEY, notebooksStr)
        await this.dataPreferences.flush()
        console.info(`Successfully saved ${notebooks.length} notebooks to preferences`)
      } catch (error) {
        console.error('Failed to save to preferences, using memory storage')
        this.memoryStorage.set(this.NOTEBOOKS_KEY, notebooksStr)
      }
    }
  }

  async loadNotebooks(): Promise<Notebook[]> {
    console.info('loadNotebooks called')

    if (this.isPreviewMode) {
      const notebooksStr = this.memoryStorage.get(this.NOTEBOOKS_KEY) || '[]'
      const notebooks = JSON.parse(notebooksStr) as Notebook[]
      console.info(`Loaded ${notebooks.length} notebooks from memory`)
      return notebooks
    } else {
      if (!this.dataPreferences) {
        const notebooksStr = this.memoryStorage.get(this.NOTEBOOKS_KEY) || '[]'
        const notebooks = JSON.parse(notebooksStr) as Notebook[]
        console.info(`Loaded ${notebooks.length} notebooks from memory (fallback)`)
        return notebooks
      }

      try {
        const notebooksStr = await this.dataPreferences.get(this.NOTEBOOKS_KEY, '[]') as string
        const notebooks = JSON.parse(notebooksStr) as Notebook[]
        console.info(`Successfully loaded ${notebooks.length} notebooks from preferences`)
        return notebooks
      } catch (error) {
        console.error('Failed to load from preferences, using memory storage')
        const notebooksStr = this.memoryStorage.get(this.NOTEBOOKS_KEY) || '[]'
        const notebooks = JSON.parse(notebooksStr) as Notebook[]
        console.info(`Loaded ${notebooks.length} notebooks from memory (fallback)`)
        return notebooks
      }
    }
  }

  async saveNotebook(newNotebook: Notebook): Promise<void> {
    console.info('saveNotebook called with:', JSON.stringify(newNotebook))
    try {
      const notebooks = await this.loadNotebooks()
      notebooks.push(newNotebook)
      await this.saveNotebooks(notebooks)
      console.info('saveNotebook completed successfully')
    } catch (error) {
      console.error('Failed to save notebook')
      throw new Error('Failed to save notebook')
    }
  }

  async deleteNotebook(id: string): Promise<void> {
    try {
      const notebooks = await this.loadNotebooks()
      const filteredNotebooks = notebooks.filter((n: Notebook) => n.id !== id)
      await this.saveNotebooks(filteredNotebooks)
      console.info(`Deleted notebook with id: ${id}`)
    } catch (error) {
      console.error('Failed to delete notebook')
      throw new Error('Failed to delete notebook')
    }
  }

  // ==================== 新版数据模型支持方法 ====================

  /**
   * 根据ID获取打卡本
   */
  async getNotebookById(id: string): Promise<Notebook | null> {
    try {
      const notebooks = await this.loadNotebooks()
      return notebooks.find((n: Notebook) => n.id === id) || null
    } catch (error) {
      console.error('Failed to get notebook by id')
      return null
    }
  }

  /**
   * 更新打卡本
   */
  async updateNotebook(notebook: Notebook): Promise<void> {
    try {
      const notebooks = await this.loadNotebooks()
      const index = notebooks.findIndex((n: Notebook) => n.id === notebook.id)

      if (index === -1) {
        throw new Error(`Notebook not found: ${notebook.id}`)
      }

      notebooks[index] = notebook
      await this.saveNotebooks(notebooks)
      console.info(`Updated notebook: ${notebook.id}`)
    } catch (error) {
      console.error('Failed to update notebook')
      throw new Error('Failed to update notebook')
    }
  }

  /**
   * 添加选项到打卡本
   */
  async addOptionToNotebook(notebookId: string, option: CheckInOption): Promise<void> {
    try {
      const notebook = await this.getNotebookById(notebookId)
      if (!notebook) {
        throw new Error(`Notebook not found: ${notebookId}`)
      }

      notebook.checkInOptions.push(option)
      notebook.updatedAt = Date.now()
      await this.updateNotebook(notebook)
      console.info(`Added option to notebook: ${notebookId}`)
    } catch (error) {
      console.error('Failed to add option to notebook')
      throw new Error('Failed to add option to notebook')
    }
  }

  /**
   * 删除打卡本的选项
   */
  async deleteOptionFromNotebook(notebookId: string, optionId: string): Promise<void> {
    try {
      const notebook = await this.getNotebookById(notebookId)
      if (!notebook) {
        throw new Error(`Notebook not found: ${notebookId}`)
      }

      notebook.checkInOptions = notebook.checkInOptions.filter(opt => opt.id !== optionId)
      notebook.updatedAt = Date.now()
      await this.updateNotebook(notebook)
      console.info(`Deleted option from notebook: ${notebookId}`)
    } catch (error) {
      console.error('Failed to delete option from notebook')
      throw new Error('Failed to delete option from notebook')
    }
  }

  /**
   * 获取数据版本
   */
  async getDataVersion(): Promise<number> {
    const VERSION_KEY = 'data_version'

    if (this.isPreviewMode) {
      const version = this.memoryStorage.get(VERSION_KEY) || '1'
      return parseInt(version, 10)
    } else {
      if (!this.dataPreferences) {
        return 1
      }

      try {
        const version = await this.dataPreferences.get(VERSION_KEY, '1') as string
        return parseInt(version, 10)
      } catch (error) {
        console.error('Failed to get data version')
        return 1
      }
    }
  }

  /**
   * 设置数据版本
   */
  async setDataVersion(version: number): Promise<void> {
    const VERSION_KEY = 'data_version'

    if (this.isPreviewMode) {
      this.memoryStorage.set(VERSION_KEY, version.toString())
      console.info(`Set data version to ${version} (memory)`)
    } else {
      if (!this.dataPreferences) {
        this.memoryStorage.set(VERSION_KEY, version.toString())
        return
      }

      try {
        await this.dataPreferences.put(VERSION_KEY, version.toString())
        await this.dataPreferences.flush()
        console.info(`Set data version to ${version}`)
      } catch (error) {
        console.error('Failed to set data version')
        this.memoryStorage.set(VERSION_KEY, version.toString())
      }
    }
  }
}