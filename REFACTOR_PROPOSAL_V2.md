# 数据驱动架构重构方案 V2（完全用户自定义版）

## 用户需求确认

✅ **方案选择**：方案一（配置驱动）
✅ **用户自定义**：允许用户创建自己的打卡选项
✅ **数据存储**：存储在本地数据库，可增删改查
✅ **图标方案**：使用图标库（不用emoji）
🔥 **核心原则**：**代码中不出现任何业务相关的硬编码值（如completed/easy等）**

---

## 关键架构决策讨论

### 🔴 讨论1：选项的作用域设计

**问题**：打卡选项属于谁？

#### 方案A：选项属于打卡本（独立）
```typescript
// 每个打卡本有自己的选项列表
Notebook {
  id: "paper_1"
  title: "数学试卷"
  checkInOptions: [
    { id: "opt1", name: "小菜一碟" },
    { id: "opt2", name: "有点难度" }
  ]
}

Notebook {
  id: "exercise_1"
  title: "英语练习"
  checkInOptions: [
    { id: "opt1", name: "全部完成" },
    { id: "opt2", name: "完成一半" }
  ]
}
```

**优点**：
- ✅ 每个打卡本可以有完全不同的选项
- ✅ 符合业务逻辑（试卷难度 vs 练习进度是不同的）

**缺点**：
- ❌ 用户每次创建打卡本都要重新配置选项
- ❌ 数据冗余（多个打卡本可能用相同的选项）

---

#### 方案B：选项全局共享 + 打卡本引用
```typescript
// 全局选项库
GlobalCheckInOptions: [
  { id: "opt_easy", name: "小菜一碟", icon: "..." },
  { id: "opt_hard", name: "有点难度", icon: "..." },
  { id: "opt_completed", name: "全部完成", icon: "..." },
  { id: "opt_partial", name: "完成一半", icon: "..." }
]

// 打卡本引用选项
Notebook {
  id: "paper_1"
  title: "数学试卷"
  optionIds: ["opt_easy", "opt_hard"]  // 引用全局选项
}

Notebook {
  id: "exercise_1"
  title: "英语练习"
  optionIds: ["opt_completed", "opt_partial"]  // 引用全局选项
}
```

**优点**：
- ✅ 用户可以创建选项库，重复使用
- ✅ 修改选项定义，所有打卡本同步更新
- ✅ 数据不冗余

**缺点**：
- ❌ 全局修改可能影响历史记录的显示
- ❌ 概念稍复杂（需要理解引用关系）

---

#### 方案C：模板 + 实例（推荐 ⭐⭐⭐⭐⭐）
```typescript
// 1. 用户创建"选项集模板"
OptionSetTemplate {
  id: "template_difficulty"
  name: "难度评价"
  options: [
    { id: "easy", name: "小菜一碟", icon: "icon_check" },
    { id: "hard", name: "有点难度", icon: "icon_warning" }
  ]
}

OptionSetTemplate {
  id: "template_progress"
  name: "完成进度"
  options: [
    { id: "completed", name: "全部完成", icon: "icon_done" },
    { id: "partial", name: "完成一半", icon: "icon_half" }
  ]
}

// 2. 打卡本创建时选择模板（实例化）
Notebook {
  id: "paper_1"
  title: "数学试卷"
  optionSetTemplateId: "template_difficulty"  // 使用模板

  // 实例化的选项（从模板拷贝过来，可以自定义修改）
  checkInOptions: [
    { id: "easy", name: "小菜一碟", icon: "icon_check" },
    { id: "hard", name: "有点难度", icon: "icon_warning" }
  ]
}
```

**优点**：
- ✅ 用户可以创建模板库，快速复用
- ✅ 每个打卡本可以在模板基础上自定义
- ✅ 修改模板不影响已创建的打卡本（隔离）
- ✅ 符合用户心智模型（类似Office的文档模板）

**缺点**：
- ❌ 需要管理两层数据（模板 + 实例）

---

**🤔 你的选择？**
- [ ] 方案A：选项属于打卡本
- [ ] 方案B：全局选项库 + 引用
- [ ] 方案C：模板 + 实例

我推荐：**方案C**，理由：
1. 既满足快速创建（用模板）
2. 又满足个性化（可修改实例）
3. 历史数据安全（修改模板不影响已有数据）

---

### 🔴 讨论2：图标库的选择

**问题**：HarmonyOS上使用什么图标库？

#### 选项A：HarmonyOS官方符号库（推荐）
- 使用 `SymbolGlyph` 组件
- 官方提供的图标资源
- 示例：`SymbolGlyph($r('sys.symbol.checkmark_circle'))`

**优点**：
- ✅ 官方支持，性能最优
- ✅ 风格统一，符合鸿蒙设计规范
- ✅ 无需引入第三方库

**缺点**：
- ❌ 图标数量有限（但应该够用）
- ❌ 需要查阅官方文档确定可用图标

#### 选项B：第三方图标库（如Font Awesome）
- 使用Web Font或SVG图标
- 图标丰富

**优点**：
- ✅ 图标数量多
- ✅ 开发者熟悉

**缺点**：
- ❌ 在HarmonyOS上集成可能有兼容性问题
- ❌ 增加包体积

#### 选项C：自定义SVG图标库
- 创建一个图标资源库
- 使用Image组件加载SVG

**优点**：
- ✅ 完全可控
- ✅ 可以设计符合app风格的图标

**缺点**：
- ❌ 需要设计/采购图标资源
- ❌ 维护成本高

**🤔 你的选择？**
- [ ] 选项A：HarmonyOS官方符号库（我推荐）
- [ ] 选项B：第三方图标库
- [ ] 选项C：自定义SVG库

---

### 🔴 讨论3：首次安装的初始数据策略

**问题**：用户首次安装app时，提供什么默认内容？

#### 方案A：预置几个模板 + 空数据
```typescript
// 首次安装时自动创建
OptionSetTemplates: [
  { id: "template_1", name: "难度评价", options: [...] },
  { id: "template_2", name: "完成进度", options: [...] }
]

Notebooks: []  // 空的，用户自己创建
```

#### 方案B：预置模板 + 示例打卡本
```typescript
// 提供示例，用户可以直接使用或删除
OptionSetTemplates: [...]

Notebooks: [
  { id: "demo_1", title: "试卷打卡", optionSetTemplateId: "template_1" },
  { id: "demo_2", title: "练习打卡", optionSetTemplateId: "template_2" }
]
```

#### 方案C：完全空数据 + 引导流程
- 首次安装完全空
- 通过引导流程让用户创建第一个打卡本

**🤔 你的选择？**
- [ ] 方案A：预置模板 + 空数据
- [ ] 方案B：预置模板 + 示例（我推荐）
- [ ] 方案C：完全空 + 引导

我推荐：**方案B**，理由：
- 降低上手门槛
- 用户可以快速体验功能
- 不喜欢的可以直接删除

---

### 🔴 讨论4：打卡事项（NotebookItem）的定位

**问题**：打卡事项在新架构中的作用？

#### 当前理解：
```
打卡本 = 数学试卷打卡
  ├─ 打卡事项1 = 选择题
  ├─ 打卡事项2 = 填空题
  └─ 打卡事项3 = 解答题

打卡选项 = { "小菜一碟", "有点难度" }
```

**用户打卡时的流程**：
1. 选择打卡本："数学试卡打卡"
2. 选择事项："选择题" ✅
3. 选择难度："小菜一碟" ✅
4. 输入笔记："今天选择题都是基础概念..."

**是这样吗？** 还是：

**备选理解**：
```
打卡本 = 数学学习
  ├─ 打卡事项1 = 试卷（每次打卡选择难度）
  ├─ 打卡事项2 = 练习册（每次打卡选择进度）
  └─ 打卡事项3 = 错题本（每次打卡选择...？）
```

**🤔 你的理解是？**

请确认打卡事项的使用场景，这影响数据模型设计。

---

### 🔴 讨论5：历史记录的兼容性

**问题**：重构后，旧数据如何处理？

#### 当前数据：
```typescript
StudyRecord {
  date: "2025-10-04"
  status: "completed"  // 硬编码值
  notebookId: "paper"
}
```

#### 新数据：
```typescript
StudyRecord {
  date: "2025-10-04"
  optionId: "opt_xyz_123"  // 动态ID
  notebookId: "paper"
  itemId: "item_123"
}
```

#### 迁移策略：

**方案A：自动迁移 + 创建默认选项**
```typescript
// 迁移时自动创建：
CheckInOption {
  id: "migrated_completed"
  name: "小菜一碟"  // 从旧数据推断
}

CheckInOption {
  id: "migrated_copied"
  name: "有点难度"
}

// 旧记录迁移：
status: "completed" → optionId: "migrated_completed"
status: "copied" → optionId: "migrated_copied"
```

**方案B：标记为历史数据，不迁移**
```typescript
// 旧记录保留原样，UI特殊处理
if (record.status) {
  // 显示为历史记录，不可编辑
  displayText = getLegacyStatusName(record.status)
}
```

**🤔 你的选择？**
- [ ] 方案A：自动迁移（推荐）
- [ ] 方案B：标记为历史数据

---

### 🔴 讨论6：图标的数据存储方式

**问题**：图标ID如何定义和存储？

假设使用HarmonyOS官方符号库：

#### 方案A：存储系统图标ID
```typescript
CheckInOption {
  id: "opt_1"
  name: "小菜一碟"
  iconId: "sys.symbol.checkmark_circle"  // 系统图标ID
}

// UI使用：
SymbolGlyph($r(option.iconId))
```

#### 方案B：存储图标索引
```typescript
// 创建图标枚举
IconLibrary = {
  "check": "sys.symbol.checkmark_circle",
  "warning": "sys.symbol.exclamationmark_triangle",
  "star": "sys.symbol.star",
  // ...
}

CheckInOption {
  id: "opt_1"
  name: "小菜一碟"
  icon: "check"  // 图标库中的key
}

// UI使用：
SymbolGlyph($r(IconLibrary[option.icon]))
```

**🤔 你的选择？**
- [ ] 方案A：直接存储系统图标ID
- [ ] 方案B：使用图标库映射（推荐）

我推荐：**方案B**，理由：
- 未来可以轻松更换图标库
- 图标选择器UI更友好（显示名称而非ID）

---

## 综合架构设计（等你确认后细化）

基于你的反馈，初步设计：

```typescript
// ==================== 核心数据模型 ====================

// 1. 选项集模板（用户可创建、删除、修改）
OptionSetTemplate {
  id: string
  name: string                    // 如 "难度评价"
  description?: string
  options: CheckInOption[]        // 包含的选项
  createdAt: number
  updatedAt?: number
}

// 2. 打卡选项（作为模板的一部分）
CheckInOption {
  id: string
  name: string                    // 如 "小菜一碟"
  icon: string                    // 图标库中的key
  color?: string
  description?: string
  order: number
}

// 3. 打卡本（实例化模板）
Notebook {
  id: string
  title: string
  icon: string
  color?: string
  optionSetTemplateId?: string    // 来源模板（可选）
  checkInOptions: CheckInOption[] // 实例化的选项（可自定义修改）
  items: NotebookItem[]
  createdAt: number
  updatedAt?: number
}

// 4. 打卡记录
StudyRecord {
  id: string
  date: string
  notebookId: string
  itemId: string
  optionId: string                // 引用 checkInOption.id
  note?: string
  createdAt: number
  updatedAt?: number
}

// ==================== 存储层 ====================

StorageService {
  // 选项集模板管理
  saveOptionSetTemplate(template: OptionSetTemplate): Promise<void>
  loadOptionSetTemplates(): Promise<OptionSetTemplate[]>
  deleteOptionSetTemplate(id: string): Promise<void>

  // 打卡本管理（现有方法）
  saveNotebook(notebook: Notebook): Promise<void>
  loadNotebooks(): Promise<Notebook[]>
  deleteNotebook(id: string): Promise<void>

  // 打卡记录管理（现有方法）
  saveRecord(record: StudyRecord): Promise<void>
  loadRecords(): Promise<StudyRecord[]>
  deleteRecord(id: string): Promise<void>
}
```

---

## 需要你确认的决策清单

请对以下6个问题给出你的选择：

1. **选项作用域**：方案A / 方案B / **方案C（推荐）**
2. **图标库**：**选项A（推荐）** / 选项B / 选项C
3. **初始数据**：方案A / **方案B（推荐）** / 方案C
4. **打卡事项定位**：请描述你的理解
5. **数据迁移**：**方案A（推荐）** / 方案B
6. **图标存储**：方案A / **方案B（推荐）**

**另外，请回答：**
- 打卡事项（NotebookItem）是否也需要有自己的选项？还是和打卡本共享选项？
- 用户创建打卡本时的流程应该是怎样的？（选模板 → 自定义 → 完成？）

确认后我立即开始编码实现！🚀
