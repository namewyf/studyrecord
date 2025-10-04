import { Notebook, StudyRecord, CheckInOption, NotebookItem } from '../models/types'
import { StorageService } from './StorageService'
import { NotebookService } from './NotebookService'
import common from '@ohos.app.ability.common'

/**
 * 数据迁移服务
 * 负责将旧版数据结构迁移到新版
 */
export class MigrationService {
  private static readonly DATA_VERSION_KEY = 'data_version'
  private static readonly CURRENT_VERSION = 2  // 新版本号

  /**
   * 检查并执行数据迁移
   */
  static async checkAndMigrate(context: common.UIAbilityContext): Promise<void> {
    const storageService = StorageService.getInstance()
    await storageService.init(context)

    const currentVersion = await MigrationService.getDataVersion()
    console.info(`Current data version: ${currentVersion}`)

    if (currentVersion < MigrationService.CURRENT_VERSION) {
      console.info('Starting data migration...')
      await MigrationService.migrateFromV1ToV2()
      await MigrationService.setDataVersion(MigrationService.CURRENT_VERSION)
      console.info('✅ Data migration completed')
    } else {
      console.info('No migration needed')
    }
  }

  /**
   * 获取当前数据版本
   */
  private static async getDataVersion(): Promise<number> {
    const storageService = StorageService.getInstance()
    try {
      const version = await storageService.getDataVersion()
      return version || 1  // 默认版本1（旧版）
    } catch (error) {
      console.warn('Failed to get data version, assuming version 1')
      return 1
    }
  }

  /**
   * 设置数据版本
   */
  private static async setDataVersion(version: number): Promise<void> {
    const storageService = StorageService.getInstance()
    await storageService.setDataVersion(version)
  }

  /**
   * 从V1迁移到V2
   */
  private static async migrateFromV1ToV2(): Promise<void> {
    console.info('Migrating from V1 to V2...')

    // 1. 迁移打卡本
    await MigrationService.migrateNotebooks()

    // 2. 迁移打卡记录
    await MigrationService.migrateRecords()

    console.info('✅ V1 to V2 migration completed')
  }

  /**
   * 迁移打卡本
   */
  private static async migrateNotebooks(): Promise<void> {
    const storageService = StorageService.getInstance()
    const oldNotebooks = await storageService.loadNotebooks()

    console.info(`Migrating ${oldNotebooks.length} notebooks...`)

    const newNotebooks: Notebook[] = []

    for (const oldNotebook of oldNotebooks) {
      // 检查是否已经是新版数据
      if (oldNotebook.checkInOptions && oldNotebook.checkInOptions.length > 0) {
        console.info(`Notebook ${oldNotebook.id} already migrated, skipping`)
        newNotebooks.push(oldNotebook)
        continue
      }

      // 生成新ID（如果是旧的业务ID）
      const newId = MigrationService.isOldBusinessId(oldNotebook.id)
        ? NotebookService.generateId('notebook')
        : oldNotebook.id

      // 创建默认选项
      const defaultOptions: CheckInOption[] = [
        NotebookService.createCheckInOption('小菜一碟', 'checkmark_circle', '#00FF00', 1),
        NotebookService.createCheckInOption('有点难度', 'exclamationmark_triangle', '#FFA500', 2)
      ]

      // 迁移事项
      const items: NotebookItem[] = []
      const oldItems = oldNotebook.items || []
      for (let index = 0; index < oldItems.length; index++) {
        const item = oldItems[index]
        const itemId = MigrationService.isOldBusinessId(item.id)
          ? NotebookService.generateId('item')
          : item.id

        const newItem: NotebookItem = {
          id: itemId,
          name: item.name,
          icon: item.icon || 'circle',
          notebookId: newId,
          order: index + 1,
          createdAt: Date.now()
        }
        items.push(newItem)
      }

      // 如果没有事项，创建一个默认事项
      if (items.length === 0) {
        items.push(NotebookService.createNotebookItem('打卡事项一', 'circle', newId, 1))
      }

      // 创建新版打卡本
      const newNotebook: Notebook = {
        id: newId,
        title: oldNotebook.title,
        icon: oldNotebook.icon || 'doc_text',
        color: oldNotebook.color,
        checkInOptions: defaultOptions,
        items: items,
        createdAt: Date.now()
      }

      newNotebooks.push(newNotebook)

      // 记录ID映射（用于迁移记录）
      if (newId !== oldNotebook.id) {
        await MigrationService.saveIdMapping('notebook', oldNotebook.id, newId)
      }

      console.info(`✅ Migrated notebook: ${oldNotebook.title} (${oldNotebook.id} → ${newId})`)
    }

    // 保存迁移后的打卡本
    await storageService.saveNotebooks(newNotebooks)
    console.info(`✅ ${newNotebooks.length} notebooks migrated`)
  }

  /**
   * 迁移打卡记录
   */
  private static async migrateRecords(): Promise<void> {
    const storageService = StorageService.getInstance()
    const oldRecords = await storageService.loadRecords()
    const notebooks = await storageService.loadNotebooks()

    console.info(`Migrating ${oldRecords.length} records...`)

    const newRecords: StudyRecord[] = []

    for (const oldRecord of oldRecords) {
      // 检查是否已经是新版数据
      if (oldRecord.optionId && oldRecord.itemId) {
        console.info(`Record ${oldRecord.date} already migrated, skipping`)
        newRecords.push(oldRecord)
        continue
      }

      // 找到对应的打卡本（可能ID已改变）
      let notebookId = oldRecord.notebookId || ''
      const mappedId = await MigrationService.getIdMapping('notebook', notebookId)
      if (mappedId) {
        notebookId = mappedId
      }

      const notebook = notebooks.find(n => n.id === notebookId)
      if (!notebook) {
        console.warn(`Notebook not found for record: ${oldRecord.date}, skipping`)
        continue
      }

      // 映射 status 到 optionId
      const optionId = MigrationService.mapStatusToOptionId(
        oldRecord.status || 'completed',
        notebook.checkInOptions
      )

      // 使用第一个事项
      const itemId = notebook.items[0]?.id || ''

      // 生成新记录
      const newRecord: StudyRecord = {
        id: NotebookService.generateId('record'),
        date: oldRecord.date,
        notebookId: notebookId,
        itemId: itemId,
        optionId: optionId,
        note: oldRecord.note,
        createdAt: oldRecord.timestamp || Date.now()
      }

      newRecords.push(newRecord)
      console.info(`✅ Migrated record: ${oldRecord.date}`)
    }

    // 保存迁移后的记录
    await storageService.saveRecords(newRecords)
    console.info(`✅ ${newRecords.length} records migrated`)
  }

  /**
   * 将旧的 status 值映射到新的 optionId
   */
  private static mapStatusToOptionId(
    status: string,
    options: CheckInOption[]
  ): string {
    if (status === 'completed') {
      const easyOption = options.find(opt => opt.name === '小菜一碟')
      return easyOption?.id || options[0]?.id || ''
    } else if (status === 'copied') {
      const hardOption = options.find(opt => opt.name === '有点难度')
      return hardOption?.id || options[1]?.id || ''
    }
    return options[0]?.id || ''
  }

  /**
   * 判断是否是旧的业务ID
   */
  private static isOldBusinessId(id: string): boolean {
    // 旧ID特征：短、有业务含义（如 "paper", "exercise", "item1"）
    // 新ID特征：包含下划线和时间戳（如 "notebook_1728123456_abc123"）
    return id.length < 15 && !id.includes('_')
  }

  /**
   * 保存ID映射（用于记录迁移）
   */
  private static idMappings: Map<string, Map<string, string>> = new Map()

  private static async saveIdMapping(
    type: string,
    oldId: string,
    newId: string
  ): Promise<void> {
    if (!MigrationService.idMappings.has(type)) {
      MigrationService.idMappings.set(type, new Map())
    }
    const typeMap = MigrationService.idMappings.get(type)
    if (typeMap) {
      typeMap.set(oldId, newId)
    }
  }

  private static async getIdMapping(
    type: string,
    oldId: string
  ): Promise<string | undefined> {
    const typeMap = MigrationService.idMappings.get(type)
    return typeMap ? typeMap.get(oldId) : undefined
  }
}
