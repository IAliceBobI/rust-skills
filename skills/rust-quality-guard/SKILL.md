---
name: rust-quality-guard
description: Rust 代码质量守护助手 - 提供全面的 Rust 代码质量检查、测试分析和错误容忍检测。在以下场景使用：(1) 检查 Rust 代码中的错误容忍和掩盖错误问题，(2) 执行 Rust 测试并分析失败原因，(3) 审查 Rust 代码质量和最佳实践，(4) 检查 clippy 警告和代码格式问题，(5) 准备提交代码前进行全面的代码质量检查。
---

# Rust Quality Guard

## Overview

Rust Quality Guard 是一个全面的 Rust 代码质量助手，结合了错误容忍检查、测试执行分析和代码审查功能，帮助开发者遵循 Rust 最佳实践，避免生产事故。

## When to Use This Skill

在以下场景激活此技能：

- **检查错误容忍问题**: 检测 `unwrap()`、`ok()`、`unwrap_or_default()` 等可能掩盖错误的模式
- **执行测试**: 运行 `cargo test` 并分析失败原因，提供修复建议
- **代码审查**: 全面检查代码质量，包括 clippy、格式、最佳实践等
- **提交前检查**: 在提交代码前执行完整的质量检查流程
- **学习最佳实践**: 查询 Rust 错误处理和测试的最佳实践模式

## Quick Start

### 1. 检查错误容忍问题

使用脚本检查代码中的错误容忍和掩盖错误问题：

```bash
# 检查当前目录
python3 scripts/check_error_tolerance.py

# 检查指定目录
python3 scripts/check_error_tolerance.py src/

# 检查其他项目
python3 scripts/check_error_tolerance.py ../my-project
```

**检查项目**:
- 🔴 高严重度: `unwrap()`, `unwrap_or_default()`, `unwrap_or()`, `let _ =`, `assert!`
- 🟡 中严重度: `expect()`, `panic!`, `ok()`, `parse().unwrap()`, 直接数组索引
- 🟢 低严重度: `todo!()`, `unimplemented!()`

### 2. 执行测试

使用脚本运行 Rust 测试并分析失败：

```bash
# 运行所有测试
python3 scripts/run_rust_tests.py

# 运行指定测试
python3 scripts/run_rust_tests.py test_login

# 运行指定包的测试
python3 scripts/run_rust_tests.py --package my-package

# 启用 features
python3 scripts/run_rust_tests.py --features "full"
```

### 3. 完整的质量检查流程

按照以下步骤执行完整的代码质量检查：

```bash
# 1. 代码格式检查
cargo fmt --check

# 2. Clippy 检查（启用严格模式）
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used

# 3. 错误容忍检查
python3 scripts/check_error_tolerance.py

# 4. 运行测试
python3 scripts/run_rust_tests.py

# 5. 检查测试覆盖率（可选）
cargo llvm-cov --html
```

## 核心标准

### FAIL FAST 原则

**最重要**的错误处理原则：错误必须传播，不能静默失败。

#### ❌ 禁止模式

```rust
// 记录但继续执行
if let Err(e) = operation() {
    log::error!("Failed: {}", e);
}
// 继续执行 - 这是错误的！

// unwrap_or 静默回退
let value = risky_operation().unwrap_or(default_value);

// ok() 丢弃错误
let value = risky_operation().ok();

// let _ = 忽略结果
let _ = risky_operation();
```

#### ✅ 正确模式

```rust
// 使用 ? 传播错误
operation()?;

// 添加错误上下文
operation().context("Failed to initialize service")?;

// 记录并传播
operation()
    .map_err(|e| {
        tracing::error!("Operation failed: {e}");
        e
    })?;

// 显式 match 处理
match operation() {
    Ok(value) => process(value),
    Err(e) => return Err(e.into()),
}
```

**记住**: 添加日志**不是**处理错误。错误必须传播！

### 错误类型选择

- **Library 代码** (src/lib.rs, 模块): 使用 `thiserror` 定义结构化错误
- **Binary 代码** (main.rs): 使用 `anyhow` 简化错误处理
- **测试代码**: 使用 `anyhow` 或简单的 `expect()`

### 测试标准

- ✅ 每个公共函数都有测试
- ✅ 测试命名清晰描述被测试的场景
- ✅ 使用 mock 减少测试依赖
- ✅ 测试边界条件和错误情况
- ✅ 保持测试简单和独立
- ❌ 避免在测试中使用 `std::env::set_var()`

## 工作流程

### 场景 1: 新功能开发

1. 编写代码时遵循 FAIL FAST 原则
2. 添加测试覆盖正常和错误情况
3. 运行 `cargo test` 确保测试通过
4. 运行 `cargo clippy` 修复警告
5. 提交前运行完整检查流程

### 场景 2: 代码审查

1. 运行 `check_error_tolerance.py` 检查错误容忍问题
2. 运行 `run_rust_tests.py` 确保所有测试通过
3. 运行 `cargo clippy` 检查代码质量
4. 查看 `references/error_handling_patterns.md` 了解最佳实践
5. 根据检查结果修复问题

### 场景 3: 调试测试失败

1. 运行 `run_rust_tests.py <test_name>` 单独执行失败的测试
2. 查看错误信息和修复建议
3. 如果可以自动修复，按照建议修改代码
4. 重新运行测试验证修复
5. 如果问题复杂，查看 `references/testing_best_practices.md` 寻求帮助

### 场景 4: CI/CD 集成

在 CI/CD 流程中添加以下检查：

```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable

      # 格式检查
      - name: Check formatting
        run: cargo fmt --check

      # Clippy 检查
      - name: Run Clippy
        run: cargo clippy -- -D warnings

      # 错误容忍检查
      - name: Check error tolerance
        run: python3 scripts/check_error_tolerance.py

      # 运行测试
      - name: Run tests
        run: cargo test --all-features
```

## 常见问题修复

### 问题 1: unwrap() 在生产代码中

**错误**: 直接使用 `unwrap()` 可能导致 panic

**修复**:
```rust
// ❌ 之前
let user = get_user(id).unwrap();

// ✅ 之后
let user = get_user(id)
    .map_err(|e| Error::UserNotFound { id, source: e })?;
```

### 问题 2: 数据库操作静默失败

**错误**: 使用 `.ok()` 忽略数据库错误

**修复**:
```rust
// ❌ 之前
let _ = db.execute(query).await.ok();

// ✅ 之后
db.execute(query)
    .await
    .inspect_err(|e| {
        tracing::error!("Database operation failed: {}", e);
    })?;
```

### 问题 3: unwrap_or_default() 掩盖错误

**错误**: 余额查询失败返回 0

**修复**:
```rust
// ❌ 之前
let balance = query_balance(user_id).unwrap_or_default();

// ✅ 之后
let balance = query_balance(user_id)
    .map_err(|e| {
        tracing::error!("Failed to query balance for {:?}: {:?}", user_id, e);
        Error::BalanceQueryFailed
    })?;
```

### 问题 4: 测试中使用 env::set_var

**错误**: 测试污染环境

**修复**:
```rust
// ❌ 之前
#[test]
fn test_client() {
    std::env::set_var("API_KEY", "test-key");
    let client = Client::new();
}

// ✅ 之后
pub struct Client {
    api_key: String,
}

impl Client {
    pub fn new(api_key: String) -> Self {
        Self { api_key }
    }
}

#[test]
fn test_client() {
    let client = Client::new("test-key".to_string());
    assert_eq!(client.api_key, "test-key");
}
```

## Clippy 配置

在项目根目录创建 `clippy.toml` 启用严格检查：

```toml
# 禁止 unwrap 和 expect
warn-on-all-wildcard-imports = true
allow-expect-in-tests = true
allow-unwrap-in-tests = true

# 错误处理
disallowed-methods = [
    { path = "std::result::Result::unwrap", reason = "Use ? operator instead" },
    { path = "std::option::Option::unwrap", reason = "Use ? operator or ok_or instead" },
]
```

运行 Clippy：

```bash
# 基础检查
cargo clippy

# 严格模式
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used

# 将警告视为错误
cargo clippy -- -D warnings
```

## Resources

### scripts/

- `check_error_tolerance.py`: 检查错误容忍和掩盖错误问题
  - 支持指定目录检查
  - 按严重度分类问题
  - 提供详细的修复建议和示例

- `run_rust_tests.py`: 执行和分析 Rust 测试
  - 运行所有或指定测试
  - 分析失败原因
  - 提供修复建议

### references/

- `error_handling_patterns.md`: 错误处理最佳实践
  - FAIL FAST 原则详细说明
  - 错误类型选择指南
  - 常见错误处理模式
  - 错误日志记录模式

- `testing_best_practices.md`: 测试最佳实践
  - 测试组织策略
  - 命名规范
  - Mock 和测试替身
  - 性能测试模式
  - 测试覆盖率工具

## 检查清单

在提交代码前，请确认：

### 错误处理
- [ ] 生产代码中没有 `unwrap()`（除非有明确注释）
- [ ] 所有 `expect()` 都包含有用的上下文信息
- [ ] 数据库操作失败都有适当的错误处理
- [ ] 关键业务逻辑（金额、余额等）不会使用默认值掩盖错误
- [ ] 配置加载失败会在启动时明确报错

### 测试
- [ ] 每个公共函数都有测试
- [ ] 测试覆盖边界条件和错误情况
- [ ] 测试命名清晰
- [ ] 没有在测试中使用 `std::env::set_var()`
- [ ] 所有测试通过

### 代码质量
- [ ] 通过 `cargo fmt --check` 格式检查
- [ ] 通过 `cargo clippy` 检查，没有警告
- [ ] 通过 `check_error_tolerance.py` 检查，没有高严重度问题
- [ ] 测试覆盖率 > 80%（如果适用）

## 命令速查

```bash
# 格式检查
cargo fmt --check

# 自动格式化
cargo fmt

# Clippy 检查
cargo clippy

# Clippy 严格模式
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used

# 运行测试
cargo test

# 运行测试并显示输出
cargo test -- --show-output

# 运行被忽略的测试
cargo test -- --ignored

# 检查测试覆盖率
cargo llvm-cov --html

# 错误容忍检查
python3 scripts/check_error_tolerance.py

# 测试分析
python3 scripts/run_rust_tests.py

# 完整检查流程
cargo fmt --check && \
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used && \
python3 scripts/check_error_tolerance.py && \
cargo test
```

## 进阶使用

### 自定义错误容忍检查

编辑 `scripts/check_error_tolerance.py` 中的 `CHECK_PATTERNS` 字典添加自定义检查模式：

```python
CHECK_PATTERNS = {
    "my_custom_check": {
        "pattern": r"my_pattern",
        "severity": Severity.HIGH,
        "category": "我的自定义检查",
        "risk": "风险描述",
        "suggestion": "修复建议",
        "example": """代码示例"""
    },
}
```

### 集成到 Git Hooks

创建 `.git/hooks/pre-commit`:

```bash
#!/bin/bash
set -e

echo "🔍 Running pre-commit checks..."

cargo fmt --check
cargo clippy -- -D warnings
python3 scripts/check_error_tolerance.py
cargo test --all-features

echo "✅ All checks passed!"
```

## 参考资源

- [The Rust Book - Error Handling](https://doc.rust-lang.org/book/ch09-00-error-handling.html)
- [To panic! or Not to panic!](https://doc.rust-lang.org/book/ch09-03-to-panic-or-not-to-panic.html)
- [Rust Error Handling Best Practices](https://blog.csdn.net/StepLens/article/details/153835257)
- [Cloudflare Outage 2025 - Lessons from unwrap()](https://www.reddit.com/r/rust/comments/1p0susm/cloudflare_outage_on_november_18_2025_caused_by/?tl=zh-hans)
