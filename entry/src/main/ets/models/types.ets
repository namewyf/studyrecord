// ==================== 新版数据模型（纯数据驱动） ====================

/**
 * 打卡选项
 * 代表一个可选的打卡状态（如"小菜一碟"、"有点难度"）
 */
export interface CheckInOption {
  id: string              // 系统生成的唯一ID，如 "opt_1728123456_abc123"
  name: string            // 用户定义的选项名称，如 "小菜一碟"
  icon: string            // 图标库中的key，如 "checkmark_circle"
  color?: string          // 选项颜色，如 "#00FF00"
  order: number           // 显示顺序
  createdAt: number       // 创建时间戳
}

/**
 * 打卡本
 */
export interface Notebook {
  id: string                      // 系统生成的唯一ID
  title: string                   // 打卡本标题
  icon: string                    // 打卡本图标
  color?: string                  // 打卡本颜色
  checkInOptions: CheckInOption[] // 该打卡本支持的选项列表
  items: NotebookItem[]           // 打卡事项列表
  createdAt: number               // 创建时间戳
  updatedAt?: number              // 更新时间戳
}

/**
 * 打卡事项
 */
export interface NotebookItem {
  id: string              // 系统生成的唯一ID
  name: string            // 事项名称
  icon: string            // 事项图标
  notebookId: string      // 所属打卡本ID
  order: number           // 显示顺序
  createdAt: number       // 创建时间戳
}

/**
 * 打卡记录
 */
export interface StudyRecord {
  id: string              // 系统生成的唯一ID
  date: string            // 打卡日期 "YYYY-MM-DD"
  notebookId: string      // 所属打卡本ID
  itemId: string          // 所属事项ID
  optionId: string        // 用户选择的选项ID（引用CheckInOption.id）
  note?: string           // 用户输入的笔记
  createdAt: number       // 创建时间戳
  updatedAt?: number      // 更新时间戳

  // ==================== 旧版字段（用于数据迁移兼容） ====================
  status?: 'completed' | 'copied'  // 旧版字段，迁移后会移除
  timestamp?: number               // 旧版字段，迁移后会移除
}

/**
 * 路由参数
 */
export interface RouterParams {
  date?: string
  status?: string           // 旧版字段
  optionId?: string         // 新版字段
  text?: string
  notebookId?: string
  notebook?: Notebook
  itemId?: string
}

export interface ItemStatistic {
  name: string
  count: number
}

export interface MonthInfo {
  year: number
  month: number
  count: number
}