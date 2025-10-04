# 数据与功能解耦重构方案

## 一、当前耦合问题分析

### 1.1 主要耦合点

#### 🔴 严重耦合：打卡选项硬编码

**问题代码位置**：
```typescript
// types.ets
status: 'completed' | 'copied'  // 硬编码的两个值

// ActionDialog.ets (第38行)
Text('小菜一碟')  // UI文案硬编码

// ActionDialog.ets (第73行)
Text('有点难度')  // UI文案硬编码

// NotebookCalendar.ets (第566行)
Text(record.status === 'completed' ? '小菜一碟' : '有点难度')  // 映射逻辑硬编码

// RecordDetail.ets (第76行)
return '完成了作业'  // 状态文案硬编码
```

**问题**：
- ❌ 选项值、名称、UI显示混在一起
- ❌ 如果要改文案（如"小菜一碟" → "轻松搞定"），需要改多个文件
- ❌ 无法动态扩展选项（如增加"中等难度"）
- ❌ 不同打卡本无法有不同的选项

#### 🔴 严重耦合：默认数据硬编码

**问题代码位置**：
```typescript
// Index.ets (第14-33行)
private defaultNotebooks: Notebook[] = [
  { id: 'paper', title: '数学试卷打卡', icon: '📝', color: '#4CAF50' },
  // ... 硬编码的默认数据
]

// CreateNotebook.ets (第14-16行)
@State items: NotebookItem[] = [
  { id: 'item1', name: '打卡事项一', icon: '✳️' },
  // ... 硬编码的默认事项
]
```

**问题**：
- ❌ 默认配置散落在各个组件中
- ❌ 修改默认值需要改代码重新编译

#### 🟡 中度耦合：NotebookItem 未被充分使用

**问题**：
```typescript
// StudyRecord 中缺少 itemId
interface StudyRecord {
  notebookId?: string  // 只关联了打卡本
  // 缺少 itemId: string  ← 应该关联具体事项
}
```

**影响**：
- NotebookItem 形同虚设
- 统计功能无法按事项统计
- 记录无法精确到具体事项

---

## 二、解耦方案设计

### 方案一：配置驱动架构（推荐 ⭐⭐⭐⭐⭐）

#### 核心思想
**将所有可变的业务规则从代码中抽离到配置数据中**

#### 2.1 数据模型重构

```typescript
// ==================== 核心配置模型 ====================

/**
 * 打卡选项配置
 * 代表一个可选的打卡状态（如"小菜一碟"、"有点难度"）
 */
export interface CheckInOption {
  id: string          // 唯一标识，如 "easy", "hard", "medium"
  name: string        // 显示名称，如 "小菜一碟"
  description?: string // 选项描述，如 "很简单，轻松完成"
  icon?: string       // 选项图标（emoji），如 "✅"
  color?: string      // 选项主题色，如 "#00FF00"
  order: number       // 显示顺序，数字越小越靠前
}

/**
 * 打卡本模板配置
 * 定义一种打卡类型的完整配置
 */
export interface NotebookTemplate {
  id: string                    // 模板ID，如 "paper_checkin"
  name: string                  // 模板名称，如 "试卷打卡模板"
  icon: string                  // 默认图标
  color?: string                // 默认颜色

  // 核心：该模板支持的打卡选项
  checkInOptions: CheckInOption[]

  // 提示文案配置
  prompts?: {
    dialogTitle?: string        // 打卡对话框标题，如 "这张试卷怎么样"
    notePlaceholder?: string    // 笔记输入提示，如 "写写复盘心得..."
    statusText?: string         // 状态显示文案，如 "完成了试卷"
  }

  // 默认事项配置
  defaultItems?: NotebookItemTemplate[]
}

/**
 * 打卡事项模板
 */
export interface NotebookItemTemplate {
  id: string
  name: string
  icon: string
  description?: string
}

/**
 * 打卡本实例（用户创建的）
 */
export interface Notebook {
  id: string                    // 实例ID，如 "user_paper_1"
  templateId: string            // 使用的模板ID
  title: string                 // 用户自定义标题
  icon: string                  // 用户选择的图标
  color?: string                // 用户选择的颜色
  items: NotebookItem[]         // 用户配置的事项
  createdAt: number             // 创建时间
}

/**
 * 打卡事项实例
 */
export interface NotebookItem {
  id: string
  name: string
  icon: string
  notebookId: string            // 所属打卡本
}

/**
 * 打卡记录（核心改动）
 */
export interface StudyRecord {
  id: string                    // 记录唯一ID
  date: string                  // 打卡日期 "YYYY-MM-DD"
  notebookId: string            // 所属打卡本
  itemId: string                // 所属事项（新增）
  optionId: string              // 选择的选项ID（替代 status）
  note?: string                 // 用户笔记
  createdAt: number             // 创建时间
  updatedAt?: number            // 更新时间
}
```

#### 2.2 预定义模板配置

```typescript
// ==================== 模板定义文件 ====================
// 文件位置: entry/src/main/ets/configs/NotebookTemplates.ets

export class NotebookTemplates {

  // 试卷打卡模板
  static PAPER_CHECKIN: NotebookTemplate = {
    id: 'paper_checkin',
    name: '试卷打卡模板',
    icon: '📝',
    color: '#4CAF50',

    checkInOptions: [
      {
        id: 'easy',
        name: '小菜一碟',
        description: '很简单，轻松完成',
        icon: '✅',
        color: '#00FF00',
        order: 1
      },
      {
        id: 'hard',
        name: '有点难度',
        description: '有挑战，需要思考',
        icon: '⚠️',
        color: '#FFA500',
        order: 2
      }
      // 未来可以轻松扩展：
      // {
      //   id: 'medium',
      //   name: '中等难度',
      //   icon: '🔸',
      //   color: '#FFD700',
      //   order: 3
      // }
    ],

    prompts: {
      dialogTitle: '这张试卷怎么样',
      notePlaceholder: '写写复盘心得...',
      statusText: '完成了试卷'
    },

    defaultItems: [
      { id: 'item1', name: '选择题', icon: '🔘', description: '单选和多选题' },
      { id: 'item2', name: '填空题', icon: '✍️', description: '填空和计算题' },
      { id: 'item3', name: '解答题', icon: '📋', description: '大题和证明题' }
    ]
  }

  // 教辅练习模板
  static EXERCISE_CHECKIN: NotebookTemplate = {
    id: 'exercise_checkin',
    name: '教辅练习模板',
    icon: '📚',
    color: '#FF4081',

    checkInOptions: [
      {
        id: 'completed',
        name: '全部完成',
        icon: '✅',
        color: '#00FF00',
        order: 1
      },
      {
        id: 'partial',
        name: '完成一部分',
        icon: '🔄',
        color: '#FFD700',
        order: 2
      },
      {
        id: 'skipped',
        name: '跳过了',
        icon: '⏭️',
        color: '#999999',
        order: 3
      }
    ],

    prompts: {
      dialogTitle: '今天练习了多少',
      notePlaceholder: '记录一下学习心得...',
      statusText: '完成了练习'
    },

    defaultItems: [
      { id: 'item1', name: '基础题', icon: '📖', description: '基础知识练习' },
      { id: 'item2', name: '提高题', icon: '🚀', description: '拓展提高练习' }
    ]
  }

  // 获取所有模板
  static getAllTemplates(): NotebookTemplate[] {
    return [
      this.PAPER_CHECKIN,
      this.EXERCISE_CHECKIN
    ]
  }

  // 根据ID获取模板
  static getTemplateById(id: string): NotebookTemplate | undefined {
    return this.getAllTemplates().find(t => t.id === id)
  }
}
```

#### 2.3 业务逻辑层（服务类）

```typescript
// ==================== 服务层 ====================
// 文件位置: entry/src/main/ets/services/NotebookService.ets

export class NotebookService {

  /**
   * 根据打卡本ID获取其模板
   */
  static async getNotebookTemplate(notebookId: string): Promise<NotebookTemplate | undefined> {
    const notebook = await this.getNotebookById(notebookId)
    if (!notebook) return undefined
    return NotebookTemplates.getTemplateById(notebook.templateId)
  }

  /**
   * 获取打卡本支持的选项列表
   */
  static async getCheckInOptions(notebookId: string): Promise<CheckInOption[]> {
    const template = await this.getNotebookTemplate(notebookId)
    return template?.checkInOptions || []
  }

  /**
   * 根据选项ID获取选项配置
   */
  static async getCheckInOption(
    notebookId: string,
    optionId: string
  ): Promise<CheckInOption | undefined> {
    const options = await this.getCheckInOptions(notebookId)
    return options.find(opt => opt.id === optionId)
  }

  /**
   * 获取打卡本的提示文案
   */
  static async getPrompts(notebookId: string) {
    const template = await this.getNotebookTemplate(notebookId)
    return template?.prompts || {
      dialogTitle: '记录打卡',
      notePlaceholder: '写点什么...',
      statusText: '完成了打卡'
    }
  }

  /**
   * 从模板创建打卡本
   */
  static createFromTemplate(
    templateId: string,
    title: string,
    icon?: string
  ): Notebook {
    const template = NotebookTemplates.getTemplateById(templateId)
    if (!template) {
      throw new Error(`Template ${templateId} not found`)
    }

    return {
      id: `notebook_${Date.now()}`,
      templateId: templateId,
      title: title,
      icon: icon || template.icon,
      color: template.color,
      items: template.defaultItems?.map(item => ({
        id: item.id,
        name: item.name,
        icon: item.icon,
        notebookId: ''  // 稍后设置
      })) || [],
      createdAt: Date.now()
    }
  }

  // ... 其他业务方法
}
```

#### 2.4 UI层调用示例

```typescript
// ==================== UI层使用 ====================

// ActionDialog.ets - 动态渲染选项
@CustomDialog
export struct ActionDialog {
  @State checkInOptions: CheckInOption[] = []
  notebookId: string = ''
  onOptionSelected: (optionId: string) => void = () => {}

  async aboutToAppear() {
    // 动态加载该打卡本支持的选项
    this.checkInOptions = await NotebookService.getCheckInOptions(this.notebookId)
    const prompts = await NotebookService.getPrompts(this.notebookId)
    this.dialogTitle = prompts.dialogTitle
  }

  build() {
    Column() {
      Text(this.dialogTitle)  // 动态标题

      // 动态渲染所有选项
      ForEach(this.checkInOptions, (option: CheckInOption) => {
        Column() {
          Row() {
            Circle()
              .fill(option.color || '#FFFFFF')  // 动态颜色
            Text(option.name)                    // 动态名称
          }
          .onClick(() => {
            this.onOptionSelected(option.id)    // 传递ID
          })
        }
      })
    }
  }
}

// NotebookCalendar.ets - 显示记录
@Builder
buildRecordItem(record: StudyRecord) {
  // 动态获取选项配置
  const option = await NotebookService.getCheckInOption(
    record.notebookId,
    record.optionId
  )

  Text(option?.name || '未知选项')  // 显示选项名称
    .fontColor(option?.color)       // 使用选项颜色
}
```

---

### 方案二：面向对象封装（备选）

如果你更喜欢OOP风格，可以使用类封装：

```typescript
// ==================== 类封装方案 ====================

class CheckInOptionModel {
  constructor(
    public id: string,
    public name: string,
    public icon?: string,
    public color?: string
  ) {}

  // 业务方法
  getDisplayText(): string {
    return `${this.icon || ''} ${this.name}`.trim()
  }

  matches(optionId: string): boolean {
    return this.id === optionId
  }
}

class NotebookTemplateModel {
  private options: CheckInOptionModel[] = []

  constructor(config: NotebookTemplate) {
    this.options = config.checkInOptions.map(
      opt => new CheckInOptionModel(opt.id, opt.name, opt.icon, opt.color)
    )
  }

  getOptions(): CheckInOptionModel[] {
    return this.options
  }

  findOption(optionId: string): CheckInOptionModel | undefined {
    return this.options.find(opt => opt.matches(optionId))
  }
}

class StudyRecordModel {
  constructor(private data: StudyRecord) {}

  async getSelectedOption(): Promise<CheckInOptionModel | undefined> {
    const template = await NotebookService.getNotebookTemplate(this.data.notebookId)
    return template?.findOption(this.data.optionId)
  }

  async getDisplayText(): Promise<string> {
    const option = await this.getSelectedOption()
    return option?.getDisplayText() || '未知'
  }
}
```

---

### 方案三：混合方案（最灵活）

结合配置驱动 + 类封装 + 工厂模式：

```typescript
// 配置 + 工厂
class NotebookFactory {
  static createPaperNotebook(title: string): Notebook {
    return NotebookService.createFromTemplate('paper_checkin', title)
  }

  static createExerciseNotebook(title: string): Notebook {
    return NotebookService.createFromTemplate('exercise_checkin', title)
  }
}

// 使用
const myPaper = NotebookFactory.createPaperNotebook('高数期中试卷')
```

---

## 三、方案对比

| 维度 | 方案一：配置驱动 | 方案二：OOP封装 | 方案三：混合 |
|------|----------------|----------------|------------|
| **解耦程度** | ⭐⭐⭐⭐⭐ 完全解耦 | ⭐⭐⭐⭐ 逻辑解耦 | ⭐⭐⭐⭐⭐ 完全解耦 |
| **扩展性** | ⭐⭐⭐⭐⭐ 只需改配置 | ⭐⭐⭐ 需改类代码 | ⭐⭐⭐⭐⭐ 两者兼得 |
| **可维护性** | ⭐⭐⭐⭐⭐ 配置集中 | ⭐⭐⭐⭐ 逻辑清晰 | ⭐⭐⭐⭐ 较复杂 |
| **学习成本** | ⭐⭐⭐ 需理解配置 | ⭐⭐⭐⭐ 熟悉OOP即可 | ⭐⭐ 概念较多 |
| **代码量** | ⭐⭐⭐⭐ 配置多但清晰 | ⭐⭐⭐⭐ 类较多 | ⭐⭐⭐ 代码较多 |
| **HarmonyOS适配** | ⭐⭐⭐⭐⭐ 完美适配 | ⭐⭐⭐⭐ 需注意ArkTS限制 | ⭐⭐⭐⭐ 适配良好 |

---

## 四、推荐方案：方案一（配置驱动）

### 为什么推荐方案一？

✅ **完全解耦**：UI、数据、逻辑三者分离
✅ **易于扩展**：新增选项只需修改配置，不改代码
✅ **个性化**：不同打卡本可以有完全不同的选项
✅ **可维护**：所有配置集中管理
✅ **HarmonyOS友好**：符合ArkTS和ArkUI的设计理念

### 实施步骤

#### 第一阶段：数据结构重构
1. ✅ 创建新的类型定义（CheckInOption, NotebookTemplate等）
2. ✅ 定义模板配置（NotebookTemplates.ets）
3. ✅ 创建服务层（NotebookService.ets）

#### 第二阶段：存储层升级
1. ✅ 添加数据迁移逻辑（旧 status → 新 optionId）
2. ✅ 更新 StorageService

#### 第三阶段：UI层重构
1. ✅ 改造 ActionDialog 为动态渲染
2. ✅ 更新 NotebookCalendar 使用服务层
3. ✅ 更新 RecordDetail 使用服务层
4. ✅ 更新 CreateNotebook 使用模板

#### 第四阶段：测试与优化
1. ✅ 数据迁移测试
2. ✅ 功能完整性测试
3. ✅ 性能优化

---

## 五、改进效果预览

### 改进前（当前）
```typescript
// ❌ 硬编码
if (record.status === 'completed') {
  return '小菜一碟'
} else {
  return '有点难度'
}
```

### 改进后
```typescript
// ✅ 配置驱动
const option = await NotebookService.getCheckInOption(
  record.notebookId,
  record.optionId
)
return option.name  // 自动从配置获取
```

### 扩展新选项（改进前 vs 改进后）

#### 改进前：需要改5个文件
1. types.ets - 添加新的 status 值
2. ActionDialog.ets - 添加新的按钮
3. NotebookCalendar.ets - 添加新的映射
4. RecordDetail.ets - 添加新的映射
5. 其他引用处 - 逐个修改

#### 改进后：只需改1个配置
```typescript
// NotebookTemplates.ets
checkInOptions: [
  { id: 'easy', name: '小菜一碟', ... },
  { id: 'hard', name: '有点难度', ... },
  { id: 'medium', name: '中等难度', icon: '🔸', order: 3 }  // 新增
]
```
**UI会自动渲染新选项，无需改任何代码！**

---

## 六、讨论问题

### 问题1：是否需要支持用户自定义选项？
- **选项A**：只允许使用预定义模板（简单）
- **选项B**：允许用户在创建打卡本时自定义选项（复杂但灵活）

我的建议：**先实现选项A**，未来有需求再升级到选项B

### 问题2：数据迁移策略
现有数据 `status: 'completed' | 'copied'` 需要迁移到 `optionId`

建议迁移映射：
- `'completed'` → `'easy'`
- `'copied'` → `'hard'`

是否同意？

### 问题3：是否需要图标库？
选项图标、打卡本图标可以：
- **选项A**：继续使用 emoji（简单）
- **选项B**：使用图标库（专业）

我的建议：**先用 emoji**，后期可升级

### 问题4：配置存储位置
- **选项A**：配置硬编码在代码中（部署简单）
- **选项B**：配置存储在文件/数据库（可动态更新）

我的建议：**选项A**（内置模板） + 选项B（用户自定义）结合

---

## 七、你的意见？

请告诉我：
1. ✅ 你倾向于哪个方案？（方案一/二/三）
2. 🤔 对于"讨论问题"中的4个问题，你的选择是？
3. 💡 还有其他需要考虑的点吗？
4. 🚀 确认后我立即开始实施重构

期待你的反馈！
