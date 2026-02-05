---
name: refactor-large-files
description: 识别项目中的大文件（>800行），分析重构方案，帮助分模块拆分
parameters:
  - name: path
    type: string
    required: false
    description: 要检查的路径，默认为当前目录
  - name: lines
    type: number
    required: false
    description: 行数阈值，默认为800行
  - name: pattern
    type: string
    required: false
    description: 文件匹配模式，如 '*.rs' 或 '*.{py,js,ts}'
tags:
  - refactoring
  - code-quality
  - maintenance
  - large-files
---

# 大文件重构分析命令

## 快速使用

```bash
# 查找超过800行的文件
refactor-large-files {{path}} {{lines}} {{pattern}}
```

## 功能说明

该命令用于：
1. **扫描代码库**中的大文件（超过指定行数）
2. **分析文件结构**，识别可以拆分的模块
3. **提供重构建议**，包括拆分策略和步骤
4. **生成行动计划**，帮助有序地进行重构

## 默认配置

- **行数阈值**: 800 行（可通过参数调整）
- **文件类型**: 源代码文件（默认排除配置、测试、生成文件）

## 使用示例

```bash
# 查找当前项目中超过800行的文件
refactor-large-files

# 查找指定目录中超过500行的文件
refactor-large-files ./src 500

# 只分析 Rust 文件
refactor-large-files . 800 '*.rs'

# 分析多种文件类型
refactor-large-files . 800 '*.{py,js,ts,rs,go}'

# 分析 JavaScript/TypeScript 文件，降低阈值到300行
refactor-large-files ./src 300 '*.{js,ts}'
```

## 输出信息

命令会输出：

```
找到 N 个超过 800 行的文件:

1. src/main.rs (1,245 行)
   问题识别:
   - 包含 15 个函数/方法
   - 包含 3 个结构体定义
   - 包含 2 个 trait 实现
   - 职责分析: 混合了配置解析、业务逻辑、数据处理

   重构建议:
   方案 1: 按功能模块拆分
   ├── config.rs - 配置解析相关（预计 200 行）
   ├── processor.rs - 业务逻辑处理（预计 400 行）
   ├── models.rs - 数据结构定义（预计 150 行）
   └── main.rs - 主入口和协调（预计 100 行）

   方案 2: 按层次拆分
   ├── models/ - 数据模型层
   ├── services/ - 业务服务层
   └── utils/ - 工具函数层

   推荐优先级: 高 - 影响可维护性和团队协作
   预计工作量: 2-3 小时

2. lib/api/handlers.rs (956 行)
   问题识别:
   - 包含 12 个 API 处理器
   - 包含 5 个中间件函数
   - 包含辅助工具函数

   重构建议:
   按端点分组拆分:
   ├── auth_handlers.rs - 认证相关
   ├── user_handlers.rs - 用户管理
   ├── admin_handlers.rs - 管理功能
   └── middleware.rs - 中间件

   推荐优先级: 中 - 模块边界相对清晰
   预计工作量: 1-2 小时
```

## 重构策略

### 1. 按功能域拆分
适用于：业务逻辑明确的大文件
```
user_service.rs (800行)
  → auth.rs - 认证功能
  → profile.rs - 个人资料
  → settings.rs - 设置管理
  → notification.rs - 通知功能
```

### 2. 按层次拆分
适用于：MVC 或分层架构
```
controller.rs (900行)
  → models/ - 数据模型
  → views/ - 视图逻辑
  → controllers/ - 控制器
```

### 3. 按抽象层级拆分
适用于：工具类或辅助函数
```
utils.rs (750行)
  → string_utils.rs - 字符串处理
  → date_utils.rs - 日期处理
  → validation.rs - 验证函数
```

### 4. 提取策略模式
适用于：大量 switch/case 或 if-else
```
handler.rs (850行)
  → handler_trait.rs - 处理器接口
  → handlers/ - 具体实现
  → dispatcher.rs - 分发器
```

## 重构步骤

### 第一步：分析依赖关系
```bash
# 查看文件内部结构
refactor-large-files analyze-dependencies src/main.rs

# 输出:
# - 函数/类之间的调用关系
# - 数据流分析
# - 外部依赖
```

### 第二步：设计模块边界
- 确定每个新模块的职责
- 识别共享状态和依赖
- 设计模块间的接口

### 第三步：逐步迁移
```bash
# 生成重构计划
refactor-large-files generate-plan src/main.rs

# 输出详细的重构步骤清单
```

### 第四步：验证
- 运行测试确保功能不变
- 检查编译错误
- 代码审查

## 实现方式

### 查找大文件
```bash
# 使用 find 统计行数
find . -type f -name "*.rs" -exec wc -l {} + | awk '$1 > 800 {print}'

# 或使用 ripgrep + 排除特定目录
rg --files -g '*.rs' --no-ignore-vcs | xargs wc -l | sort -rn | head -20
```

### 排除的文件类型
```bash
# 排除测试文件、生成文件、配置文件
--glob='!*_test.*'
--glob='!*.test.*'
--glob='!*.mock.*'
--glob='!*.generated.*'
--glob='!*.min.js'
--glob='!package-lock.json'
--glob='!vendor/**'
```

## 常见反模式

### ❌ 上帝类 (God Class)
单个类/文件承担过多职责，超过 1000 行

**解决方案**: 按单一职责原则拆分

### ❌ 长方法
单个方法超过 50-100 行

**解决方案**: 提取方法 (Extract Method)

### ❌ 重复代码
大量相似的代码块

**解决方案**: 提取公共函数/模板方法模式

## 质量标准

重构后应达到：
- ✅ 每个文件 < 500 行（推荐 < 300 行）
- ✅ 每个函数 < 50 行（推荐 < 30 行）
- ✅ 单一职责原则
- ✅ 低耦合、高内聚
- ✅ 所有测试通过
- ✅ 代码可读性提升

## 注意事项

1. **渐进式重构**: 不要一次性修改太多，小步快跑
2. **保持测试**: 每一步都要确保测试通过
3. **版本控制**: 每个阶段提交一次，方便回滚
4. **团队沟通**: 重构核心模块时与团队同步
5. **性能验证**: 重构后验证性能未下降

## 相关技能

- `superpowers:brainstorming` - 重构前规划架构
- `superpowers:writing-plans` - 制定详细重构计划
- `superpowers:test-driven-development` - 使用 TDD 安全重构
- `myskills:rust-quality-guard` - Rust 项目特定重构建议
