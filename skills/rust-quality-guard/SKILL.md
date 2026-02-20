---
name: rust-quality-guard
description: Rust 代码质量守护助手 - 提供全面的 Rust 代码质量检查、测试分析和错误容忍检测。在以下场景使用：(1) 编写 Rust 代码时遵循最佳实践和错误处理原则，(2) 检查 Rust 代码中的错误容忍和掩盖错误问题，(3) 执行 Rust 测试并分析失败原因，(4) 审查 Rust 代码质量和最佳实践，(5) 检查 clippy 警告和代码格式问题，(6) 准备提交代码前进行全面的代码质量检查。
---

# Rust Quality Guard

## Overview

Rust Quality Guard 是一个全面的 Rust 代码质量助手，结合了错误容忍检查、测试执行分析和代码审查功能，帮助开发者遵循 Rust 最佳实践，避免生产事故。

## When to Use This Skill

在以下场景激活此技能：

- **编写代码时**: 边写代码边遵循 FAIL FAST 原则和最佳实践，使用 `?` 传播错误，避免使用 `unwrap()`、`ok()` 等掩盖错误的模式
- **检查错误容忍问题**: 检测 `unwrap()`、`ok()`、`unwrap_or_default()` 等可能掩盖错误的模式
- **执行测试**: 运行 `cargo test` 并分析失败原因，提供修复建议
- **代码审查**: 全面检查代码质量，包括 clippy、格式、最佳实践等
- **提交前检查**: 在提交代码前执行完整的质量检查流程
- **学习最佳实践**: 查询 Rust 错误处理和测试的最佳实践模式

## Quick Start

### 0. 编写代码时遵循最佳实践

在编写代码时就应该遵循 Rust 最佳实践：

```rust
// ✅ 使用 ? 传播错误
fn get_user(id: u32) -> Result<User, Error> {
    let user = db.query_user(id)?;  // 错误会向上传播
    Ok(user)
}

// ❌ 不要使用 unwrap()
fn get_user(id: u32) -> User {
    db.query_user(id).unwrap()  // 可能 panic!
}

// ✅ 添加错误上下文
fn process_payment(amount: u64) -> Result<(), Error> {
    charge(amount)
        .context("Failed to charge payment")?;
    Ok(())
}
```

**关键原则**:
- 使用 `?` 传播错误，不要用 `unwrap()`
- 关键业务逻辑（金额、余额）必须返回错误，不要用默认值
- 添加有用的错误上下文信息

### 1. 自动修复代码问题

使用 cargo 原生工具自动修复编译器警告和 Clippy 建议：

```bash
# 1. 修复编译器警告（安全修复）
cargo fix

# 2. 修复编译失败的代码（只修复明确的问题）
cargo fix --broken-code

# 3. 修复 Clippy 产生的警告（自动应用建议）
cargo clippy --fix

# 4. 允许在有未提交更改的代码上修复
cargo clippy --fix --allow-dirty

# 5. 自动格式化代码
cargo fmt
```

**推荐工作流**:
```bash
# 一键自动修复所有可修复的问题
cargo fix && cargo clippy --fix --allow-dirty && cargo fmt
```

### 2. 执行测试

直接使用 cargo 运行测试：

```bash
# 运行所有测试
cargo test

# 运行测试并显示输出
cargo test -- --show-output

# 运行指定测试
cargo test test_login

# 运行指定包的测试
cargo test -p my-package

# 启用 features
cargo test --features "test-utils"
cargo test --all-features

# 运行被忽略的测试
cargo test -- --ignored

# 并行运行测试（默认）
cargo test

# 串行运行测试
cargo test -- --test-threads=1
```

### 3. 完整的质量检查流程

按照以下步骤执行完整的代码质量检查：

```bash
# 1. 自动修复所有可修复的问题
cargo fix --broken-code
cargo clippy --fix --allow-dirty
cargo fmt

# 2. 代码格式检查（CI 中使用）
cargo fmt --check

# 3. Clippy 检查（启用严格模式）
# 如果项目使用 test-utils 特性,需要加上 --features test-utils
cargo clippy --features test-utils -- -W clippy::unwrap_used -W clippy::expect_used

# 4. 运行测试
# 如果项目使用 test-utils 特性,需要加上 --features test-utils
cargo test --features test-utils

# 5. 检查测试覆盖率（可选）
cargo llvm-cov --html --features test-utils
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

### 测试特性（test-utils）最佳实践

在编写测试代码时,如果需要在源码中添加测试辅助功能,应该使用 **条件编译特性** 来隔离测试代码:

#### 使用 test-utils 特性

```rust
// ✅ 正确: 在 src/lib.rs 中使用特性门控
#[cfg(feature = "test-utils")]
pub mod testing {
    pub use super::internal_helpers;

    pub fn create_test_client() -> Client {
        Client::new_for_testing()
    }
}

// 生产代码不会被编译
#[cfg(not(feature = "test-utils"))]
fn internal_helpers() {
    // 只在测试时可用
}
```

#### 在 Cargo.toml 中声明

```toml
[features]
test-utils = []  # 不启用默认,测试时手动启用
```

#### 运行测试时启用特性

**重要**: 如果项目使用了 test-utils 特性,必须启用该特性:

```bash
# ❌ 错误: 如果代码依赖 test-utils,这会编译失败
cargo test
cargo check

# ✅ 正确: 启用 test-utils 特性
cargo test --features test-utils
cargo check --features test-utils
cargo clippy --features test-utils

# CI/CD 中
cargo test --all-features
```

#### 为什么这样做?

- ✅ **减小二进制大小**: 生产构建不包含测试代码
- ✅ **防止滥用**: 测试辅助函数不会在生产代码中意外调用
- ✅ **清晰分离**: 明确区分生产代码和测试代码

### 测试标准

- ✅ 每个公共函数都有测试
- ✅ 测试命名清晰描述被测试的场景
- ✅ 使用 mock 减少测试依赖
- ✅ 测试边界条件和错误情况
- ✅ 保持测试简单和独立
- ❌ 避免在测试中使用 `std::env::set_var()`
- ✅ **源码中的测试辅助代码使用 `#[cfg(feature = "test-utils")]` 门控**
- ✅ **运行测试时使用 `--features test-utils` 如果项目使用了该特性**

## 工作流程

### 场景 1: 编写代码时

1. 编写代码时遵循 FAIL FAST 原则
2. 使用 `?` 传播错误，避免 `unwrap()`、`ok()` 等模式
3. 添加测试覆盖正常和错误情况
4. 运行 `cargo test` 确保测试通过
5. 运行 `cargo clippy` 修复警告
6. 定期运行 `cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used` 检查代码质量

### 场景 2: 代码审查

1. 运行 `cargo clippy --fix --allow-dirty` 自动修复 linter 问题
2. 运行 `cargo fmt` 格式化代码
3. 运行 `cargo test` 确保所有测试通过
4. 运行 `cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used` 进行严格检查
5. 根据检查结果修复剩余问题

### 场景 3: 调试测试失败

1. 运行 `cargo test <test_name>` 单独执行失败的测试
2. 添加 `-- --nocapture` 查看测试输出
3. 如果可以自动修复，按照建议修改代码
4. 重新运行测试验证修复
5. 如果问题复杂，查看 `$CLAUDE_PLUGIN_ROOT/references/testing_best_practices.md` 寻求帮助

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

      # 运行测试
      - name: Run tests
        # 如果项目使用 test-utils 特性,使用 --all-features 或明确指定
        run: cargo test --all-features
        # 或者: cargo test --features "test-utils,other-features"
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
# 禁止 unwrap 和 expect（测试中允许）
allow-expect-in-tests = true
allow-unwrap-in-tests = true

# 启用 pedantic lints（更严格的检查）
warn-on-all-wildcard-imports = true

# 错误处理
disallowed-methods = [
    { path = "std::result::Result::unwrap", reason = "Use ? operator instead" },
    { path = "std::option::Option::unwrap", reason = "Use ? operator or ok_or instead" },
]

# 配置特定 lints
absolute-paths_allowed_modules = ["std", "core", "alloc"]

# 允许一些不太重要的警告（灵活配置）
# 配置某些复杂度阈值
too-many-lines-threshold = 150  # 提高行数阈值
function-line-threshold = 100    # 函数行数阈值
```

## 灵活配置警告 - 学会变通

**重要原则**: 不要对所有警告都一视同仁，有些警告是真正的问题，有些只是噪音。学会根据实际情况灵活配置。

### 方法一：在代码中使用属性（局部忽略）

适用于特殊情况，需要注释说明原因：

```rust
// 忽略单个函数的警告，并说明原因
#[allow(clippy::too_many_arguments)]
// 需要这么多参数因为每个参数都有明确的业务含义
fn calculate_loan_score(
    income: u64,
    debt: u64,
    age: u32,
    years_employed: u32,
    credit_history: u32,
) -> f64 {
    // ...
}

// 忽略整个模块的警告
#[allow(dead_code)]
mod legacy_code {
    // 保留用于兼容旧版本，计划在 v2.0 中移除
    fn old_function() {}
}

// 临时忽略开发中的代码
#[allow(unused_variables)]
fn developing_feature() {
    let todo_feature = 42;  // TODO: 实现这个功能
}
```

**常用允许属性**:
- `#[allow(unused_variables)]` - 未使用的变量（开发中很常见）
- `#[allow(dead_code)]` - 未使用的代码（保留的 API、计划中的功能）
- `#[allow(clippy::too_many_lines)]` - 函数太长
- `#[allow(clippy::too_many_arguments)]` - 参数太多
- `#[allow(clippy::module_name_repetitions)]` - 模块名重复

### 方法二：在 Cargo.toml 中全局配置（推荐）

#### 项目级别配置

```toml
[lints]
# 开发时放宽一些限制，提高开发效率
rust.unused_variables = "allow"  # 开发中允许未使用变量
rust.dead_code = "warn"          # 死代码降级为 warn，不阻止编译

# Clippy 配置 - 区分重要和不重要的警告
clippy::too_many_lines = "allow"           # 允许长函数
clippy::too_many_arguments = "allow"       # 允许较多参数
clippy::module_name_repetitions = "allow"  # 允许模块名重复
clippy::must_use_candidate = "allow"       # 不强制要求 must_use

# 但保持严格的错误处理
clippy::unwrap_used = "warn"      # 仍然警告 unwrap
clippy::expect_used = "warn"      # 仍然警告 expect
```

#### Workspace 级别配置

```toml
[workspace.lints]
# 在整个 workspace 中统一配置
rust.unused_variables = "allow"
rust.dead_code = "warn"

# Clippy 灵活配置
clippy::too_many_lines = "allow"
clippy::module_name_repetitions = "allow"

# 测试代码中更宽松
[workspace.lints.clippy]
# 这些在测试中通常是必要的
unwrap_used = "allow"
expect_used = "allow"
```

然后在成员的 Cargo.toml 中继承：

```toml
[lints]
workspace = true  # 继承 workspace 配置

# 也可以根据项目需求覆盖
[lints.clippy]
too_many_lines = "warn"  # 这个项目对代码长度要求更严格
```

### 方法三：命令行参数（临时调整）

```bash
# 临时允许特定警告
cargo clippy -- --allow clippy::too_many_lines

# 允许多个警告
cargo clippy -- --allow clippy::too_many_lines --allow dead_code

# CI 中严格，开发时宽松
cargo clippy -- -D warnings  # CI 中使用
cargo clippy                  # 开发时使用
```

### 常见可忽略的"无害"警告

#### 开发过程中的正常警告

```rust
// 1. 未使用的变量 - 开发中很常见
#[allow(unused_variables)]
fn in_development() {
    let planned_feature = 42;  // 计划实现的功能
}

// 2. 死代码 - 保留的 API、计划中的功能
#[allow(dead_code)]
pub fn future_api() {
    // 为下个版本预留的 API
}

// 3. 模块名重复 - 合理的项目结构
#[allow(clippy::module_name_repetitions)]
mod user {
    pub mod user_handler { }  // user.user_handler 是合理的
}
```

#### 合理的业务代码

```rust
// 1. 较多的参数 - 每个参数都有明确含义
#[allow(clippy::too_many_arguments)]
fn create_user(
    name: String,
    email: String,
    age: u32,
    address: String,
    phone: String,
) -> User {
    // 每个字段都是必需的，参数多但不影响代码质量
}

// 2. 较长的函数 - 复杂的业务逻辑
#[allow(clippy::too_many_lines)]
fn process_payment_flow() {
    // 150 行的支付流程，每个步骤都很重要
    // 不应为了缩短函数而破坏可读性
}

// 3. 显式的类型转换 - 提高可读性
#[allow(clippy::cast_possible_truncation)]
let id = user_id as i32;  // 明确知道不会溢出
```

### 方法四：使用 clippy.toml 配置

```toml
# clippy.toml

# 测试代码中允许更多
allow-expect-in-tests = true
allow-unwrap-in-tests = true

# 放宽一些复杂度限制
too-many-lines-threshold = 150    # 提高行数阈值
function-line-threshold = 100      # 函数行数阈值
type-complexity-threshold = 250    # 类型复杂度阈值

# 允许某些模式
allow-print = true           # 允许 println! 用于调试
allow-mixed-uninlined-format-args = true  # 允许混合格式参数
```

### 最佳实践建议

1. **分层配置**
   - **生产代码**: 对错误处理严格，对代码风格灵活
   - **测试代码**: 放宽限制，提高开发效率
   - **开发工具/脚本**: 可以更宽松

2. **区分重要性和噪音**
   ```
   ✅ 重要警告（必须处理）:
   - unwrap_used, expect_used       - 错误处理问题
   - panicking, panic_in_result_fn  - 可能 panic
   - empty_drop, drop_copy          - 逻辑错误
   - await_holding_lock             - 死锁风险

   ⚠️ 风格警告（可以忽略）:
   - too_many_lines                  - 代码长度
   - too_many_arguments              - 参数数量
   - module_name_repetitions         - 命名重复
   - must_use_candidate              - 建议性标记
   ```

3. **渐进式严格**
   ```toml
   # 项目初期：宽松配置
   [lints]
   rust.unused_variables = "allow"
   clippy::too_many_lines = "allow"

   # 项目成熟期：逐步严格
   [lints]
   rust.unused_variables = "warn"
   clippy::too_many_lines = "warn"
   ```

4. **注释说明**
   ```rust
   // 当你确实需要忽略警告时，添加注释说明
   #[allow(clippy::too_many_arguments)]
   // 需要 8 个参数因为每个字段都对应数据库的一列，
   // 重构为结构体会降低代码可读性
   fn complex_query(/* 8 个参数 */) { }
   ```

### 推荐配置示例

#### 严格的错误处理，宽松的代码风格

```toml
# Cargo.toml
[lints]
# 编译器警告 - 灵活配置
rust.unused_variables = "allow"   # 开发中常见
rust.dead_code = "warn"           # 不阻止编译
rust.unused_imports = "warn"      # 可以自动清理

[lints.clippy]
# 错误处理 - 保持严格
unwrap_used = "warn"
expect_used = "warn"
panicking = "warn"

# 代码风格 - 保持灵活
too_many_lines = "allow"
too_many_arguments = "allow"
module_name_repetitions = "allow"
must_use_candidate = "allow"
```

#### 不同环境的配置

```toml
# 开发环境
[lints]
rust.unused_variables = "allow"
clippy::too_many_lines = "allow"

# CI 环境（通过环境变量或 feature 控制）
# CI 中使用: cargo clippy -- -D warnings
```

### 工作流程建议

```bash
# 开发时：宽松模式，允许快速迭代
cargo clippy  # 使用 Cargo.toml 中的宽松配置

# 提交前：严格检查
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used

# CI 中：最严格
cargo clippy -- -D warnings
```

### 记住

- **不是所有警告都是问题** - 学会区分真正的质量和噪音
- **配置应该为项目服务** - 而不是为工具服务
- **灵活但不随意** - 每个放宽的规则都应该有理由
- **定期审查** - 每隔一段时间检查是否可以收紧配置

在 `Cargo.toml` 中配置 Clippy lints：

```toml
[lints.clippy]
# Pedantic lints（更严格，但可能有误报）
pedantic = "warn"

# 禁止在生产代码中使用 unwrap/expect
unwrap_used = "warn"
expect_used = "warn"

# 测试代码中允许
# (在 clippy.toml 中配置 allow-expect-in-tests 和 allow-unwrap-in-tests)
```

运行 Clippy：

```bash
# 基础检查
cargo clippy

# 自动修复可修复的问题
cargo clippy --fix

# 允许在有未提交更改时修复
cargo clippy --fix --allow-dirty

# 严格模式（命令行参数优先级更高）
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used

# 将警告视为错误（CI 中推荐）
cargo clippy -- -D warnings

# 启用 pedantic lints
cargo clippy -- -W clippy::pedantic

# 禁用特定 lint
cargo clippy -- -A clippy::too_many_arguments
```

## Rustfmt 配置

在项目根目录创建 `rustfmt.toml`：

```toml
# 使用 2024 版本格式化风格
style_edition = "2024"

# 最大代码行宽度
max_width = 100

# 硬标签（tabs）宽度
hard_tabs = false
tab_spaces = 4

# 其他常用配置
use_small_heuristics = "Default"
reorder_imports = true
reorder_modules = true
remove_nested_parens = true
```

**最佳实践**:
- ✅ **总是使用 `rustfmt.toml` 配置文件**（即使是空的），确保 `cargo fmt` 和 `rustfmt` 命令的一致性
- ✅ **在编辑器中启用保存时自动格式化**（VS Code: `editor.formatOnSave`）
- ✅ **在 CI/CD 中强制执行格式检查**: `cargo fmt --all --check`
- ✅ **使用 `rust-analyzer` 获得最佳编辑器支持**

运行 Rustfmt：

```bash
# 检查格式（不修改文件，CI 中使用）
cargo fmt --check

# 自动格式化
cargo fmt

# 查看格式化差异但不修改
cargo fmt -- --check

# 格式化所有 workspace 成员
cargo fmt --all
```

**重要**:
- `cargo fix` 和 `cargo clippy --fix` 会自动运行 `rustfmt`，但建议手动运行 `cargo fmt` 确保一致性
- `cargo fmt` 会修改代码格式，如果无法安全修改才会失败

## Resources

### Cargo 原生工具

- **cargo fix**: 自动修复编译器警告
  - `cargo fix`: 修复编译器警告（安全修复）
  - `cargo fix --broken-code`: 修复编译失败的代码
  - `cargo fix --allow-dirty`: 在有未提交更改时修复

- **cargo clippy**: Rust linter
  - `cargo clippy`: 运行 linter 检查
  - `cargo clippy --fix`: 自动应用 linter 建议
  - `cargo clippy -- -W clippy::lint_name`: 启用特定 lint
  - `cargo clippy -- -D warnings`: 将警告视为错误

- **cargo fmt**: 代码格式化工具
  - `cargo fmt`: 自动格式化代码
  - `cargo fmt --check`: 检查格式（不修改文件）
  - `cargo fmt --all`: 格式化所有 workspace 成员

### References

- `$CLAUDE_PLUGIN_ROOT/references/error_handling_patterns.md`: 错误处理最佳实践
  - FAIL FAST 原则详细说明
  - 错误类型选择指南
  - 常见错误处理模式
  - 错误日志记录模式

- `$CLAUDE_PLUGIN_ROOT/references/testing_best_practices.md`: 测试最佳实践
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
- [ ] **如果使用了 test-utils 特性,测试时启用该特性**
- [ ] **源码中的测试辅助代码使用 `#[cfg(feature = "test-utils")]` 门控**
- [ ] **生产构建不包含测试代码: `cargo build --release` 验证**

### 代码质量
- [ ] 通过 `cargo fmt --check` 格式检查
- [ ] 通过 `cargo clippy` 检查，没有警告
- [ ] 通过 `cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used` 严格检查
- [ ] 测试覆盖率 > 80%（如果适用）

## 命令速查

```bash
# ===== 代码格式化 =====
# 检查格式（CI 中使用）
cargo fmt --check

# 自动格式化
cargo fmt

# ===== 自动修复 =====
# 修复编译器警告
cargo fix

# 修复编译失败的代码
cargo fix --broken-code

# 允许在未提交更改时修复
cargo fix --allow-dirty

# Clippy 自动修复
cargo clippy --fix
cargo clippy --fix --allow-dirty

# 一键自动修复所有问题
cargo fix --broken-code --allow-dirty && cargo clippy --fix --allow-dirty && cargo fmt

# ===== Clippy 检查 =====
# 基础检查
cargo clippy

# 严格模式
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used

# 将警告视为错误（CI 中推荐）
cargo clippy -- -D warnings

# 启用 pedantic lints
cargo clippy -- -W clippy::pedantic

# 禁用特定 lint
cargo clippy -- -A clippy::too_many_arguments

# ===== 测试 =====
# 运行所有测试
cargo test

# 运行测试并显示输出
cargo test -- --show-output

# 运行指定测试
cargo test test_name

# 运行被忽略的测试
cargo test -- --ignored

# 启用 features
cargo test --features test-utils
cargo test --all-features

# 检查测试覆盖率
cargo llvm-cov --html

# ===== 完整检查流程 =====
# 如果项目使用 test-utils 特性,加上 --features test-utils
cargo fmt --check && \
cargo clippy --features test-utils -- -W clippy::unwrap_used -W clippy::expect_used && \
cargo test --features test-utils

# 或者使用 --all-features
cargo fmt --check && \
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used && \
cargo test --all-features

# ===== 自动修复 + 检查 =====
# 开发时使用（自动修复 + 检查）
cargo fix --broken-code --allow-dirty && \
cargo clippy --fix --allow-dirty && \
cargo fmt && \
cargo test
```

## 进阶使用

### 自定义 Clippy Lints

在项目根目录创建 `clippy.toml` 自定义检查：

```toml
# 自定义禁止的方法
disallowed-methods = [
    { path = "std::result::Result::unwrap", reason = "Use ? operator instead" },
    { path = "std::option::Option::unwrap", reason = "Use ? operator or ok_or instead" },
    # 添加自定义禁止的方法
    { path = "my_module::dangerous_function", reason = "Use safe_function instead" },
]

# 自定义类型
disallowed-types = [
    { path = "std::collections::HashMap", reason = "Use FxHashMap from rustc-hash" },
]

# 自定义标识符
disallowed-identifiers = [
    { path = "foo", reason = "Use a descriptive name" },
]
```

### Cargo.toml 中配置 Lints

```toml
[lints]
# 编译器 lints
rust.unused_crate_dependencies = "warn"
rust.missing_docs = "warn"

[lints.clippy]
# Clippy lints
pedantic = "warn"  # 启用 pedantic lints
unwrap_used = "warn"
expect_used = "warn"
```

### 工作空间配置

在 `Cargo.toml`（workspace 根目录）中为所有成员配置：

```toml
[workspace.lints.clippy]
pedantic = "warn"
unwrap_used = "warn"
expect_used = "warn"

[workspace.lints.rust]
unused_crate_dependencies = "warn"
missing_docs = "warn"

# 然后在成员的 Cargo.toml 中继承
[lints]
workspace = true
```

### 集成到 Git Hooks

创建 `.git/hooks/pre-commit`:

```bash
#!/bin/bash
set -e

echo "🔍 Running pre-commit checks..."

# 自动修复可修复的问题
echo "🔧 Auto-fixing issues..."
cargo fix --broken-code --allow-dirty
cargo clippy --fix --allow-dirty
cargo fmt

# 检查格式
echo "📝 Checking formatting..."
cargo fmt --check

# Clippy 检查
# 如果项目使用 test-utils 特性,加上 --features test-utils
echo "🔍 Running Clippy..."
cargo clippy --features test-utils -- -D warnings

# 运行测试
# 启用所有需要的特性运行测试
echo "🧪 Running tests..."
cargo test --all-features

echo "✅ All checks passed!"
```

## 参考资源

### 官方文档
- [The Rust Book - Error Handling](https://doc.rust-lang.org/book/ch09-00-error-handling.html)
- [To panic! or Not to panic!](https://doc.rust-lang.org/book/ch09-03-to-panic-or-not-to-panic.html)
- [Cargo Book - cargo fix](https://doc.rust-lang.org/cargo/commands/cargo-fix.html)
- [Clippy Documentation - Lint Configuration](https://doc.rust-lang.org/stable/clippy/lint_configuration.html)
- [rust-lang/rustfmt](https://github.com/rust-lang/rustfmt)
- [rust-lang/rust-clippy](https://github.com/rust-lang/rust-clippy)

### 最佳实践文章
- [Mastering Cargo Clippy: Your Code's Best Friend (2026)](https://www.oreateai.com/blog/mastering-cargo-clippy-your-codes-best-friend/9d77854e4d05a402b27907e1d20ac54b) - 2026年1月发布的综合性 Clippy 指南
- [Linting in Rust with Clippy](https://blog.logrocket.com/rust-linting-clippy/) - Clippy 的详细使用指南
- [Rust 开发最佳实践（中文）](https://www.cnblogs.com/gyc567/p/19151256) - 涵盖代码结构、错误处理、并发、测试、文档和性能优化
- [Rust Error Handling Best Practices](https://blog.csdn.net/StepLens/article/details/153835257)
- [Cloudflare Outage 2025 - Lessons from unwrap()](https://www.reddit.com/r/rust/comments/1p0susm/cloudflare_outage_on_november_18_2025_caused_by/?tl=zh-hans) - 真实案例：错误容忍导致的故障
