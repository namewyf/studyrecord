# 纯数据驱动重构方案（最终版）

## 核心原则

🔥 **绝对规则**：
1. ✅ 数据结构中**不允许**出现任何业务相关的值（如 "easy", "completed" 等）
2. ✅ 所有ID由系统自动生成（时间戳或UUID），**用户不可指定**
3. ✅ 所有业务内容（名称、颜色、图标等）都是**普通数据字段**，用户可随时修改
4. ✅ 代码中**不允许**判断ID值来处理业务逻辑
5. ✅ 重构后功能**完全不变**，只是实现方式改变

---

## 一、数据模型设计（纯数据，无业务逻辑）

### 1.1 打卡选项（CheckInOption）

```typescript
export interface CheckInOption {
  id: string              // 系统生成，如 "1728123456789" 或 "uuid-xxxxx"
  name: string            // 用户填写，如 "小菜一碟"
  icon: string            // 用户选择，如 "icon_check"（图标库key）
  color?: string          // 用户选择，如 "#00FF00"
  order: number           // 显示顺序，用户可调整
  createdAt: number       // 创建时间戳
}
```

**示例数据**：
```typescript
{
  id: "1728123456789",        // ✅ 纯技术ID
  name: "小菜一碟",            // ✅ 用户可修改
  icon: "icon_check",         // ✅ 用户可选择
  color: "#00FF00",           // ✅ 用户可选择
  order: 1,                   // ✅ 用户可调整
  createdAt: 1728123456789
}
```

**❌ 错误示例**：
```typescript
{
  id: "easy",  // ❌ 业务含义的ID，绝对禁止！
  name: "小菜一碟"
}
```

---

### 1.2 打卡本（Notebook）

```typescript
export interface Notebook {
  id: string                      // 系统生成
  title: string                   // 用户填写
  icon: string                    // 用户选择
  color?: string                  // 用户选择

  // 该打卡本支持的选项列表
  checkInOptions: CheckInOption[]  // 用户自定义的选项

  // 打卡事项列表
  items: NotebookItem[]

  createdAt: number
  updatedAt?: number
}
```

**示例数据**：
```typescript
{
  id: "1728123456790",
  title: "数学试卷打卡",         // ✅ 用户填写
  icon: "icon_paper",
  color: "#4CAF50",
  checkInOptions: [
    {
      id: "1728123456791",       // ✅ 系统生成的ID
      name: "小菜一碟",           // ✅ 用户填写的名称
      icon: "icon_check",
      color: "#00FF00",
      order: 1,
      createdAt: 1728123456791
    },
    {
      id: "1728123456792",       // ✅ 系统生成的ID
      name: "有点难度",           // ✅ 用户填写的名称
      icon: "icon_warning",
      color: "#FFA500",
      order: 2,
      createdAt: 1728123456792
    }
  ],
  items: [...],
  createdAt: 1728123456790
}
```

---

### 1.3 打卡事项（NotebookItem）

```typescript
export interface NotebookItem {
  id: string              // 系统生成
  name: string            // 用户填写
  icon: string            // 用户选择
  notebookId: string      // 所属打卡本ID
  order: number           // 显示顺序
  createdAt: number
}
```

---

### 1.4 打卡记录（StudyRecord）

```typescript
export interface StudyRecord {
  id: string              // 系统生成
  date: string            // 打卡日期 "YYYY-MM-DD"
  notebookId: string      // 所属打卡本（引用Notebook.id）
  itemId: string          // 所属事项（引用NotebookItem.id）
  optionId: string        // 用户选择的选项（引用CheckInOption.id）
  note?: string           // 用户输入的笔记
  createdAt: number       // 创建时间戳
  updatedAt?: number      // 修改时间戳
}
```

**示例数据**：
```typescript
{
  id: "1728123456793",
  date: "2025-10-04",
  notebookId: "1728123456790",    // 引用打卡本ID
  itemId: "1728123456800",        // 引用事项ID
  optionId: "1728123456791",      // 引用选项ID（不是"easy"！）
  note: "今天试卷很简单",
  createdAt: 1728123456793
}
```

**关键点**：
- ✅ optionId 是 "1728123456791"，不是 "easy" 或 "completed"
- ✅ 要知道用户选了什么，需要查找 checkInOptions 数组
- ✅ UI显示时：`notebook.checkInOptions.find(opt => opt.id === record.optionId).name`

---

## 二、数据查询逻辑（服务层）

```typescript
// ==================== NotebookService.ets ====================

export class NotebookService {

  /**
   * 获取打卡记录对应的选项信息
   * 用途：UI显示记录时，获取选项名称、颜色等
   */
  static async getRecordOption(record: StudyRecord): Promise<CheckInOption | null> {
    // 1. 获取打卡本
    const notebook = await StorageService.getInstance().getNotebookById(record.notebookId)
    if (!notebook) return null

    // 2. 在打卡本的选项列表中查找
    const option = notebook.checkInOptions.find(opt => opt.id === record.optionId)
    return option || null
  }

  /**
   * 获取打卡本的所有选项（用于打卡对话框）
   */
  static async getNotebookOptions(notebookId: string): Promise<CheckInOption[]> {
    const notebook = await StorageService.getInstance().getNotebookById(notebookId)
    return notebook?.checkInOptions || []
  }

  /**
   * 生成唯一ID
   */
  static generateId(prefix: string = 'id'): string {
    return `${prefix}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }

  /**
   * 创建新的打卡选项
   */
  static createCheckInOption(name: string, icon: string, color?: string): CheckInOption {
    return {
      id: this.generateId('opt'),   // ✅ 系统生成ID
      name: name,                    // ✅ 用户提供的名称
      icon: icon,
      color: color,
      order: Date.now(),
      createdAt: Date.now()
    }
  }
}
```

---

## 三、UI层使用示例

### 3.1 ActionDialog（打卡对话框）

```typescript
// ==================== ActionDialog.ets ====================

@CustomDialog
export struct ActionDialog {
  @State options: CheckInOption[] = []  // 动态加载的选项
  notebookId: string = ''
  onOptionSelected: (optionId: string) => void = () => {}

  async aboutToAppear() {
    // 动态加载该打卡本的选项
    this.options = await NotebookService.getNotebookOptions(this.notebookId)
  }

  build() {
    Column() {
      Text('这张试卡怎么样')
        .fontSize(18)
        .fontColor('#FFFFFF')

      // 🔥 动态渲染选项（不是硬编码）
      ForEach(this.options, (option: CheckInOption) => {
        Column() {
          Row() {
            Circle()
              .fill(option.color || '#FFFFFF')  // ✅ 从数据读取颜色
              .width(40)
              .height(40)

            Text(option.name)                    // ✅ 从数据读取名称
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .onClick(() => {
            this.onOptionSelected(option.id)    // ✅ 传递纯技术ID
          })
        }
      }, (option: CheckInOption) => option.id)
    }
  }
}
```

**关键点**：
- ✅ 不再硬编码 "小菜一碟"、"有点难度"
- ✅ 所有内容从 `options` 数组读取
- ✅ 用户添加新选项，UI自动渲染

---

### 3.2 NotebookCalendar（记录列表）

```typescript
// ==================== NotebookCalendar.ets ====================

@Builder
async buildRecordItem(record: StudyRecord) {
  // 🔥 动态获取选项信息
  const option = await NotebookService.getRecordOption(record)

  Column() {
    // 显示选项名称（不是硬编码判断）
    Text(option?.name || '未知选项')      // ✅ 显示 "小菜一碟" 或用户自定义的名称
      .fontSize(24)
      .fontColor('#FFFFFF')

    // 显示用户笔记
    if (record.note) {
      Text(record.note)
        .fontSize(18)
        .fontColor('#999999')
    }
  }
}
```

**关键点**：
- ✅ 不再写 `if (record.status === 'completed') return '小菜一碟'`
- ✅ 通过 `getRecordOption()` 动态查询
- ✅ 用户修改选项名称，历史记录显示也会更新（如果需要的话）

---

## 四、数据迁移方案

### 4.1 旧数据结构
```typescript
// 旧版
StudyRecord {
  date: "2025-10-04",
  status: "completed",      // ❌ 硬编码值
  notebookId: "paper"       // ❌ 业务含义的ID
}

Notebook {
  id: "paper",              // ❌ 业务含义的ID
  title: "数学试卷打卡"
}
```

### 4.2 迁移逻辑

```typescript
// ==================== MigrationService.ets ====================

export class MigrationService {

  /**
   * 迁移打卡本
   */
  static async migrateNotebooks(): Promise<void> {
    const oldNotebooks = await StorageService.getInstance().loadNotebooks()

    for (const oldNotebook of oldNotebooks) {
      // 生成新的ID（如果是旧的业务ID）
      const newId = this.isOldBusinessId(oldNotebook.id)
        ? NotebookService.generateId('notebook')
        : oldNotebook.id

      // 为该打卡本创建默认选项（基于现有功能）
      const defaultOptions: CheckInOption[] = [
        {
          id: NotebookService.generateId('opt'),  // ✅ 生成新ID
          name: '小菜一碟',                        // ✅ 保留原功能
          icon: 'icon_check',
          color: '#00FF00',
          order: 1,
          createdAt: Date.now()
        },
        {
          id: NotebookService.generateId('opt'),  // ✅ 生成新ID
          name: '有点难度',                        // ✅ 保留原功能
          icon: 'icon_warning',
          color: '#FFA500',
          order: 2,
          createdAt: Date.now()
        }
      ]

      const newNotebook: Notebook = {
        ...oldNotebook,
        id: newId,
        checkInOptions: defaultOptions,  // 新增字段
        createdAt: oldNotebook.createdAt || Date.now()
      }

      await StorageService.getInstance().saveNotebook(newNotebook)
    }
  }

  /**
   * 迁移打卡记录
   */
  static async migrateRecords(): Promise<void> {
    const oldRecords = await StorageService.getInstance().loadRecords()
    const notebooks = await StorageService.getInstance().loadNotebooks()

    for (const oldRecord of oldRecords) {
      // 找到对应的打卡本
      const notebook = notebooks.find(n =>
        this.matchOldNotebookId(n, oldRecord.notebookId)
      )

      if (!notebook) continue

      // 根据旧的 status 值映射到新的 optionId
      const optionId = this.mapStatusToOptionId(
        oldRecord.status,
        notebook.checkInOptions
      )

      const newRecord: StudyRecord = {
        id: NotebookService.generateId('record'),  // ✅ 生成新ID
        date: oldRecord.date,
        notebookId: notebook.id,
        itemId: notebook.items[0]?.id || '',       // 默认第一个事项
        optionId: optionId,                        // ✅ 映射到新选项ID
        note: oldRecord.note,
        createdAt: oldRecord.timestamp || Date.now()
      }

      await StorageService.getInstance().saveRecord(newRecord)
    }
  }

  /**
   * 将旧的 status 值映射到新的 optionId
   */
  private static mapStatusToOptionId(
    status: string,
    options: CheckInOption[]
  ): string {
    // 根据名称匹配（而不是ID）
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
    // 旧ID特征：短、有业务含义（如 "paper", "exercise"）
    return id.length < 15 && !id.includes('_')
  }
}
```

---

## 五、存储层扩展

```typescript
// ==================== StorageService.ets 新增方法 ====================

export class StorageService {

  // 现有方法保持不变...

  /**
   * 根据ID获取打卡本
   */
  async getNotebookById(id: string): Promise<Notebook | null> {
    const notebooks = await this.loadNotebooks()
    return notebooks.find(n => n.id === id) || null
  }

  /**
   * 更新打卡本的选项
   */
  async updateNotebookOptions(
    notebookId: string,
    options: CheckInOption[]
  ): Promise<void> {
    const notebooks = await this.loadNotebooks()
    const notebook = notebooks.find(n => n.id === notebookId)

    if (notebook) {
      notebook.checkInOptions = options
      notebook.updatedAt = Date.now()
      await this.saveNotebooks(notebooks)
    }
  }

  /**
   * 添加选项到打卡本
   */
  async addOptionToNotebook(
    notebookId: string,
    option: CheckInOption
  ): Promise<void> {
    const notebook = await this.getNotebookById(notebookId)
    if (notebook) {
      notebook.checkInOptions.push(option)
      await this.updateNotebookOptions(notebookId, notebook.checkInOptions)
    }
  }

  /**
   * 删除打卡本的选项
   */
  async deleteOptionFromNotebook(
    notebookId: string,
    optionId: string
  ): Promise<void> {
    const notebook = await this.getNotebookById(notebookId)
    if (notebook) {
      notebook.checkInOptions = notebook.checkInOptions.filter(
        opt => opt.id !== optionId
      )
      await this.updateNotebookOptions(notebookId, notebook.checkInOptions)
    }
  }
}
```

---

## 六、功能对比（重构前 vs 重构后）

### 功能1：用户打卡

#### 重构前
```typescript
// UI硬编码
<Text>小菜一碟</Text>  onClick={() => onSelect('completed')}
<Text>有点难度</Text>  onClick(() => onSelect('copied')}

// 记录存储
{ status: 'completed' }  // ❌ 硬编码
```

#### 重构后
```typescript
// UI动态渲染
ForEach(options, option =>
  <Text>{option.name}</Text>  onClick={() => onSelect(option.id)}
)

// 记录存储
{ optionId: '1728123456791' }  // ✅ 引用数据ID
```

**结果**：功能完全一样，但实现方式解耦

---

### 功能2：显示记录

#### 重构前
```typescript
// UI判断
if (record.status === 'completed') {
  displayText = '小菜一碟'  // ❌ 硬编码
}
```

#### 重构后
```typescript
// UI查询
const option = await getRecordOption(record)
displayText = option.name  // ✅ 从数据读取
```

**结果**：功能完全一样，但可扩展

---

### 功能3：用户自定义

#### 重构前
❌ 不支持，选项固定为 "小菜一碟" 和 "有点难度"

#### 重构后
```typescript
// 用户可以添加新选项
const newOption = NotebookService.createCheckInOption(
  '中等难度',     // 用户输入
  'icon_medium',  // 用户选择
  '#FFD700'       // 用户选择
)
await StorageService.getInstance().addOptionToNotebook(notebookId, newOption)
```

**结果**：✅ 新功能，不影响原有功能

---

## 七、首次安装默认数据

```typescript
// ==================== DefaultData.ets ====================

export class DefaultData {

  /**
   * 创建默认打卡本（保持现有功能）
   */
  static createDefaultNotebooks(): Notebook[] {
    // 默认选项1：难度评价
    const difficultyOptions: CheckInOption[] = [
      {
        id: NotebookService.generateId('opt'),
        name: '小菜一碟',
        icon: 'icon_check',
        color: '#00FF00',
        order: 1,
        createdAt: Date.now()
      },
      {
        id: NotebookService.generateId('opt'),
        name: '有点难度',
        icon: 'icon_warning',
        color: '#FFA500',
        order: 2,
        createdAt: Date.now()
      }
    ]

    // 默认打卡本
    return [
      {
        id: NotebookService.generateId('notebook'),
        title: '数学试卷打卡',
        icon: 'icon_paper',
        color: '#4CAF50',
        checkInOptions: [...difficultyOptions],  // 拷贝选项
        items: [
          {
            id: NotebookService.generateId('item'),
            name: '打卡事项一',
            icon: 'icon_item',
            notebookId: '',  // 稍后设置
            order: 1,
            createdAt: Date.now()
          }
        ],
        createdAt: Date.now()
      }
    ]
  }
}
```

---

## 八、实施步骤

### 阶段1：准备阶段（不影响现有功能）
1. ✅ 创建新的类型定义文件
2. ✅ 创建 NotebookService.ets
3. ✅ 创建 MigrationService.ets
4. ✅ 创建 DefaultData.ets

### 阶段2：存储层扩展（向后兼容）
1. ✅ StorageService 添加新方法
2. ✅ 保留旧方法，确保现有代码仍可运行

### 阶段3：数据迁移（一次性）
1. ✅ App启动时检测数据版本
2. ✅ 如果是旧数据，执行迁移
3. ✅ 迁移完成后标记版本

### 阶段4：UI层重构（逐个页面）
1. ✅ ActionDialog.ets - 改为动态渲染
2. ✅ NotebookCalendar.ets - 改为动态查询
3. ✅ RecordDetail.ets - 改为动态查询
4. ✅ CreateNotebook.ets - 支持自定义选项

### 阶段5：测试与优化
1. ✅ 功能测试（确保所有原功能正常）
2. ✅ 数据迁移测试
3. ✅ 新功能测试（自定义选项）

---

## 九、关键检查清单

在实施前，请确认：

- [ ] ✅ 所有ID都是系统生成的（时间戳或UUID）
- [ ] ✅ 代码中没有判断ID值的业务逻辑（如 `if (id === 'easy')`）
- [ ] ✅ 所有业务内容都是普通数据字段
- [ ] ✅ 重构后现有功能完全不变
- [ ] ✅ 支持用户自定义新选项
- [ ] ✅ 数据迁移方案可靠

---

## 十、你需要确认的最后3个问题

1. **图标库选择**：使用 HarmonyOS 官方 SymbolGlyph？还是你有其他资源？

2. **打卡事项的作用**：
   - 是否需要每个事项有独立的选项？
   - 还是打卡本的所有事项共享同一组选项？

3. **ID生成方式**：
   - 时间戳 + 随机数（如 `opt_1728123456_abc123`）
   - 还是纯UUID（如 `550e8400-e29b-41d4-a716-446655440000`）

   我推荐时间戳+随机数，因为可读性更好，调试方便。

**确认后立即开始编码实施！** 🚀
