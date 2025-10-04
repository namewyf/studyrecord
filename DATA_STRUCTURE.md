# 学霸打卡 - 数据结构文档

## 1. 核心数据模型

### 1.1 StudyRecord (打卡记录)

**文件位置**: `entry/src/main/ets/models/types.ets`

**用途**: 存储用户每次打卡的记录信息

```typescript
interface StudyRecord {
  date: string              // 打卡日期，格式: "YYYY-MM-DD" (如 "2025-10-04")
  status: 'completed' | 'copied'  // 打卡状态
  note?: string            // 用户输入的复盘心得（可选）
  timestamp?: number       // 记录创建的时间戳（可选）
  notebookId?: string      // 所属打卡本ID（可选）
}
```

**字段说明**:

| 字段 | 类型 | 必填 | 说明 | 示例值 |
|------|------|------|------|--------|
| date | string | ✅ | 打卡日期，使用ISO格式的日期字符串 | "2025-10-04" |
| status | 'completed' \| 'copied' | ✅ | 打卡难度选项<br/>• 'completed' = "小菜一碟"<br/>• 'copied' = "有点难度" | "completed" |
| note | string | ❌ | 用户输入的复盘心得，支持多行文本 | "今天的试卷很简单" |
| timestamp | number | ❌ | 记录创建时的时间戳（毫秒） | 1696406400000 |
| notebookId | string | ❌ | 所属打卡本的唯一标识符 | "paper" |

**当前使用情况**:
- UI显示: 在记录列表中，`status === 'completed'` 显示为"小菜一碟"，否则显示"有点难度"
- 唯一性: 同一天（同一个date）只能有一条记录，新记录会覆盖旧记录

---

### 1.2 Notebook (打卡本)

**文件位置**: `entry/src/main/ets/models/types.ets`

**用途**: 打卡本的配置信息，每个打卡本代表一个主题（如试卷、教辅）

```typescript
interface Notebook {
  id: string               // 打卡本唯一标识符
  title: string            // 打卡本标题
  icon: string             // 打卡本图标（emoji）
  color?: string           // 打卡本主题色（可选）
  items?: NotebookItem[]   // 打卡事项列表（可选）
}
```

**字段说明**:

| 字段 | 类型 | 必填 | 说明 | 示例值 |
|------|------|------|------|--------|
| id | string | ✅ | 打卡本的唯一标识符 | "paper" |
| title | string | ✅ | 打卡本的显示标题 | "数学试卷打卡" |
| icon | string | ✅ | 用于显示的emoji图标 | "📝" |
| color | string | ❌ | 主题色，HEX格式 | "#4CAF50" |
| items | NotebookItem[] | ❌ | 该打卡本下的具体事项 | [见NotebookItem] |

**默认打卡本**:
```typescript
[
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
```

---

### 1.3 NotebookItem (打卡事项)

**文件位置**: `entry/src/main/ets/models/types.ets`

**用途**: 打卡本下的具体事项，用于细分打卡内容

```typescript
interface NotebookItem {
  id: string      // 事项唯一标识符
  name: string    // 事项名称
  icon: string    // 事项图标（emoji）
}
```

**字段说明**:

| 字段 | 类型 | 必填 | 说明 | 示例值 |
|------|------|------|------|--------|
| id | string | ✅ | 事项的唯一标识符 | "item1" |
| name | string | ✅ | 事项的显示名称 | "打卡事项一" |
| icon | string | ✅ | 用于显示的emoji图标 | "✳️" |

**默认事项**:
```typescript
[
  { id: 'item1', name: '打卡事项一', icon: '✳️' },
  { id: 'item2', name: '打卡事项二', icon: '❌' }
]
```

---

### 1.4 辅助数据结构

#### RouterParams (路由参数)

**用途**: 页面间传递参数

```typescript
interface RouterParams {
  date: string
  status: string
  text?: string
  notebookId?: string
  notebook?: Notebook
}
```

#### ItemStatistic (事项统计)

**用途**: 统计tab中显示各事项的打卡次数

```typescript
interface ItemStatistic {
  name: string    // 事项名称
  count: number   // 打卡次数
}
```

#### MonthInfo (月份信息)

**用途**: 月份选择器中显示每月的打卡数量

```typescript
interface MonthInfo {
  year: number    // 年份
  month: number   // 月份 (1-12)
  count: number   // 该月的打卡次数
}
```

---

## 2. 数据存储机制

**存储服务**: `StorageService` (单例模式)
**文件位置**: `entry/src/main/ets/services/StorageService.ets`

### 2.1 存储方式

- **持久化存储**: 使用HarmonyOS的 `@ohos.data.preferences` API
- **存储名称**: `study_records`
- **存储键值**:
  - `records`: 存储所有打卡记录（StudyRecord[]）
  - `notebooks`: 存储所有打卡本（Notebook[]）

### 2.2 核心方法

#### 打卡记录相关

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| saveRecord() | newRecord: StudyRecord | Promise\<void\> | 保存单条记录，同日期记录会被覆盖 |
| loadRecords() | - | Promise\<StudyRecord[]\> | 加载所有记录 |
| deleteRecord() | date: string | Promise\<void\> | 删除指定日期的记录 |
| clear() | - | Promise\<void\> | 清空所有记录 |

#### 打卡本相关

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| saveNotebook() | newNotebook: Notebook | Promise\<void\> | 保存新的打卡本 |
| loadNotebooks() | - | Promise\<Notebook[]\> | 加载所有打卡本 |
| deleteNotebook() | id: string | Promise\<void\> | 删除指定ID的打卡本 |
| saveNotebooks() | notebooks: Notebook[] | Promise\<void\> | 批量保存打卡本（覆盖） |

### 2.3 存储特性

- **预览器模式**: 当在DevEco预览器中运行时，自动降级为内存存储（数据不持久化）
- **持久化检测**: 初始化时会尝试使用preferences，失败则使用内存存储
- **错误处理**: 所有存储操作都有错误处理和降级机制
- **数据格式**: 使用JSON序列化存储

---

## 3. 数据流转示意

```
┌─────────────────┐
│   用户操作      │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│  UI组件 (*.ets)             │
│  - Index.ets (首页)         │
│  - NotebookCalendar.ets     │
│  - RecordDetail.ets         │
│  - NoteInput.ets            │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  StorageService (单例)      │
│  - saveRecord()             │
│  - loadRecords()            │
│  - saveNotebook()           │
│  - loadNotebooks()          │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  Preferences / Memory       │
│  Key: "records"             │
│  Value: StudyRecord[]       │
│  Key: "notebooks"           │
│  Value: Notebook[]          │
└─────────────────────────────┘
```

---

## 4. 当前数据层存在的问题与改进建议

### 🔴 严重问题

#### 4.1 记录与事项未关联
**问题**: `StudyRecord` 中缺少 `itemId` 字段，无法知道一条记录属于哪个具体事项

**影响**:
- 统计功能无法准确统计各事项的打卡次数
- `NotebookItem` 功能形同虚设
- `ItemStatistic` 的统计逻辑不准确（目前只能将所有记录算到第一个事项上）

**建议修改**:
```typescript
interface StudyRecord {
  date: string
  status: 'completed' | 'copied'
  note?: string
  timestamp?: number
  notebookId: string      // 改为必填
  itemId?: string         // 新增：所属事项ID
}
```

#### 4.2 状态值语义不清
**问题**: `status` 字段使用 `'completed' | 'copied'`，但实际含义是"小菜一碟"和"有点难度"

**影响**:
- 代码可读性差
- 未来扩展困难（如果要增加其他难度选项）

**建议修改**:
```typescript
type DifficultyLevel = 'easy' | 'hard' | 'medium'  // 更清晰的命名

interface StudyRecord {
  // ...
  difficulty: DifficultyLevel  // 替代 status
}
```

或者使用枚举：
```typescript
enum Difficulty {
  EASY = 'easy',      // 小菜一碟
  HARD = 'hard'       // 有点难度
}
```

### 🟡 中等问题

#### 4.3 日期格式未统一
**问题**: 代码中使用 `"YYYY-MM-DD"` 格式，但没有统一的日期工具类

**建议**: 创建日期工具类
```typescript
export class DateUtil {
  static format(date: Date): string {
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  static parse(dateStr: string): Date {
    return new Date(dateStr)
  }
}
```

#### 4.4 缺少数据验证
**问题**: 保存数据前没有验证字段的有效性

**建议**: 添加验证函数
```typescript
export class RecordValidator {
  static validate(record: StudyRecord): boolean {
    if (!record.date || !this.isValidDate(record.date)) return false
    if (!record.status) return false
    if (!record.notebookId) return false
    return true
  }

  private static isValidDate(dateStr: string): boolean {
    const date = new Date(dateStr)
    return !isNaN(date.getTime())
  }
}
```

#### 4.5 缺少记录更新字段
**问题**: 无法追踪记录的修改历史

**建议**: 添加更新时间
```typescript
interface StudyRecord {
  // ... 现有字段
  createdAt: number    // 创建时间戳
  updatedAt?: number   // 最后修改时间戳
}
```

### 🟢 轻微问题

#### 4.6 NotebookItem 的 icon 使用率低
**问题**: 创建时定义了事项图标，但UI中很少使用

**建议**:
- 在选择打卡事项时显示图标
- 在记录列表中显示事项图标，而非打卡本图标

#### 4.7 缺少分页或性能优化
**问题**: 当记录数量很大时，一次性加载所有记录可能影响性能

**建议**:
- 添加按月份或年份过滤的加载方法
- 实现分页加载机制

```typescript
async loadRecordsByMonth(year: number, month: number): Promise<StudyRecord[]>
async loadRecordsRange(startDate: string, endDate: string): Promise<StudyRecord[]>
```

---

## 5. 推荐的数据结构改进方案

### 5.1 优化后的 StudyRecord

```typescript
export interface StudyRecord {
  id: string                          // 新增：记录唯一ID
  date: string                        // 日期 "YYYY-MM-DD"
  notebookId: string                  // 改为必填
  itemId: string                      // 新增：所属事项ID
  difficulty: 'easy' | 'hard'         // 难度（替代status）
  note?: string                       // 复盘心得
  createdAt: number                   // 创建时间戳
  updatedAt?: number                  // 最后修改时间戳
}
```

### 5.2 添加数据版本管理

```typescript
export interface DataVersion {
  version: number                     // 数据结构版本号
  migrations?: MigrationFunction[]    // 数据迁移函数
}
```

### 5.3 添加用户偏好设置

```typescript
export interface UserPreferences {
  defaultNotebookId?: string         // 默认打卡本
  notificationEnabled: boolean       // 是否启用提醒
  dailyGoal?: number                 // 每日打卡目标
}
```

---

## 6. 数据迁移建议

如果要实施上述改进，需要数据迁移策略：

1. **添加版本号**: 在存储中增加 `data_version` 字段
2. **迁移脚本**: 编写从旧结构到新结构的转换函数
3. **兼容性**: 保持向后兼容，逐步迁移数据

---

## 7. 使用示例

### 7.1 创建新记录

```typescript
const newRecord: StudyRecord = {
  date: "2025-10-04",
  status: "completed",  // 小菜一碟
  note: "今天的数学试卷很简单，都是基础题",
  timestamp: Date.now(),
  notebookId: "paper"
}

await StorageService.getInstance().saveRecord(newRecord)
```

### 7.2 查询某月的记录

```typescript
const records = await StorageService.getInstance().loadRecords()
const octoberRecords = records.filter(r => {
  const date = new Date(r.date)
  return date.getFullYear() === 2025 && date.getMonth() === 9  // 10月
})
```

### 7.3 统计某打卡本的记录数

```typescript
const records = await StorageService.getInstance().loadRecords()
const paperCount = records.filter(r => r.notebookId === 'paper').length
```

---

## 8. 总结

### 优点
✅ 数据结构简洁清晰
✅ 使用TypeScript类型安全
✅ 存储服务设计合理（单例模式）
✅ 支持预览器降级策略

### 待改进
❌ 记录与事项缺少关联（itemId）
❌ status字段命名不够语义化
❌ 缺少数据验证机制
❌ 缺少日期工具类
❌ 缺少性能优化（大数据量）

**建议优先级**:
1. 🔥 **高优先级**: 添加 `itemId` 字段，修正统计逻辑
2. 🔥 **高优先级**: 重命名 `status` 为 `difficulty`，提高代码可读性
3. 🟡 **中优先级**: 添加数据验证和日期工具类
4. 🟢 **低优先级**: 性能优化和分页加载
