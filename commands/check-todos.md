---
name: check-todos
description: 检查代码中的 TODO 注释，评估是否适合处理
parameters:
  - name: path
    type: string
    required: false
    description: 要检查的路径，默认为当前目录
  - name: pattern
    type: string
    required: false
    description: 文件匹配模式，如 '*.rs' 或 '*.{py,js}'
tags:
  - code-quality
  - maintenance
  - todos
---

# TODO 检查命令

## 快速使用

```bash
# 检查当前目录所有文件
todo-check {{path}} {{pattern}}
```

## 功能说明

该命令用于：
1. **扫描代码库**中的 TODO 注释（支持多种格式和大小写）
2. **分析上下文**，判断是否适合立即处理
3. **优先级排序**，帮助决定处理顺序

## 支持的 TODO 格式

支持大小写混合和多种格式：

- `TODO:`
- `todo:`
- `ToDo:`
- `FIXME:`
- `fixme:`
- `HACK:`
- `hack:`
- `XXX:`
- `NOTE:`
- `@todo`

## 使用示例

```bash
# 检查整个项目
todo-check .

# 只检查 Rust 文件
todo-check . '*.rs'

# 检查特定目录
todo-check ./src

# 检查多种文件类型
todo-check . '*.{py,js,ts}'
```

## 输出信息

命令会输出：

```
找到 N 个 TODO 注释:

src/main.rs:42: TODO: 添加错误处理
  上下文: 在函数 parse_config 中
  优先级: 高 - 影响错误处理
  建议: 适合立即处理

src/utils.rs:15: todo: 重构这个函数
  上下文: 在辅助函数中
  优先级: 低 - 代码改进
  建议: 可以后续处理
```

## 优先级判断标准

- **高优先级**: 错误处理、安全问题、功能缺失
- **中优先级**: 性能优化、代码清理
- **低优先级**: 重构、文档补充、代码改进

## 实现方式

使用 grep 搜索：

```bash
# 忽略大小写搜索 TODO
grep -rn "TODO:" --include="*.rs" . \
  | grep -i "todo\|fixme\|hack\|xxx\|note"

# 或使用 ripgrep (更快)
rg -i "TODO|FIXME|HACK|XXX|NOTE" --type rust
```
