import preferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'
import { StudyRecord, Notebook } from '../models/types'

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

    // 检测是否在预览器环境
    try {
      if (!this.dataPreferences) {
        console.info('Creating preferences with name:', this.STORE_NAME)
        this.dataPreferences = await preferences.getPreferences(context, this.STORE_NAME)
        console.info('StorageService initialized successfully with preferences')
        this.isPreviewMode = false
      } else {
        console.info('StorageService already initialized')
      }
    } catch (error) {
      // 在预览器环境中，使用内存存储
      console.warn('Failed to initialize preferences, using memory storage for preview mode')
      console.warn('Error details:', JSON.stringify(error, null, 2))
      this.isPreviewMode = true
      this.memoryStorage.set(this.RECORDS_KEY, '[]')
      console.info('StorageService initialized with memory storage (preview mode)')
    }
  }

  async saveRecords(records: StudyRecord[]): Promise<void> {
    console.info('saveRecords called with records count:', records.length)

    const recordsStr = JSON.stringify(records)

    if (this.isPreviewMode) {
      // 预览器模式：使用内存存储
      console.info('Using memory storage (preview mode)')
      this.memoryStorage.set(this.RECORDS_KEY, recordsStr)
      console.info(`Successfully saved ${records.length} records to memory`)
    } else {
      // 真实设备模式：使用preferences
      if (!this.dataPreferences) {
        console.error('StorageService not initialized - dataPreferences is null')
        // 尝试使用内存存储作为后备
        this.memoryStorage.set(this.RECORDS_KEY, recordsStr)
        console.info(`Fallback: saved ${records.length} records to memory`)
        return
      }

      try {
        console.info('Saving records string length:', recordsStr.length)
        await this.dataPreferences.put(this.RECORDS_KEY, recordsStr)
        console.info('Put operation completed')
        await this.dataPreferences.flush()
        console.info(`Successfully saved ${records.length} records to preferences`)
      } catch (error) {
        console.error('Failed to save to preferences, using memory storage')
        console.error('Error details:', JSON.stringify(error, null, 2))
        // 失败时使用内存存储
        this.memoryStorage.set(this.RECORDS_KEY, recordsStr)
        console.info(`Fallback: saved ${records.length} records to memory`)
      }
    }
  }

  async loadRecords(): Promise<StudyRecord[]> {
    console.info('loadRecords called')

    if (this.isPreviewMode) {
      // 预览器模式：从内存加载
      console.info('Loading from memory storage (preview mode)')
      const recordsStr = this.memoryStorage.get(this.RECORDS_KEY) || '[]'
      const records = JSON.parse(recordsStr) as StudyRecord[]
      console.info(`Loaded ${records.length} records from memory`)
      return records
    } else {
      // 真实设备模式：从preferences加载
      if (!this.dataPreferences) {
        console.warn('StorageService not initialized, loading from memory')
        const recordsStr = this.memoryStorage.get(this.RECORDS_KEY) || '[]'
        const records = JSON.parse(recordsStr) as StudyRecord[]
        console.info(`Loaded ${records.length} records from memory (fallback)`)
        return records
      }

      try {
        const recordsStr = await this.dataPreferences.get(this.RECORDS_KEY, '[]') as string
        const records = JSON.parse(recordsStr) as StudyRecord[]
        console.info(`Successfully loaded ${records.length} records from preferences`)
        return records
      } catch (error) {
        console.error('Failed to load from preferences, using memory storage')
        console.error('Error details:', JSON.stringify(error, null, 2))
        const recordsStr = this.memoryStorage.get(this.RECORDS_KEY) || '[]'
        const records = JSON.parse(recordsStr) as StudyRecord[]
        console.info(`Loaded ${records.length} records from memory (fallback)`)
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
}