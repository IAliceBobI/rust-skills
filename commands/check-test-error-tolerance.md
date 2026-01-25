---
description: 检查 Rust 代码中的错误容忍和掩盖错误问题，遵循最佳实践避免生产事故
---

# Rust 错误容忍与掩盖问题检查

> **背景**: 2025年11月 Cloudflare 因单个 `.unwrap()` 导致服务中断。本检查旨在提前发现类似隐患。

请检查所有 `.rs` 文件，查找以下错误容忍模式：

## 检查项目

### 1. 🔴 高严重度问题（High Severity）

#### 1.1 unwrap() 的过度使用
**风险**: 生产环境中直接 panic，无法优雅降级

- 查找模式: `\bunwrap\(\)` (排除 `unwrap_or`)
- 关键操作中的 unwrap（数据库查询、gRPC 调用、余额查询、交易操作）
- 检查是否提供错误上下文

```rust
// ❌ 危险
let user_id = get_user_id().unwrap();

// ✅ 更好
let user_id = get_user_id()
    .map_err(|e| Error::UserIdNotFound(e))?;
```

#### 1.2 数据库操作静默失败
**风险**: 数据不一致，操作悄无声息地失败

- 查找模式: `\.execute\(.*\)\.await\.ok\(\)`
- 查找模式: `\.fetch_optional\(.*\)\.await\.ok\(\)`
- 查找模式: `\.execute\(.*\)\.await\.inspect_err`
- 数据库清理、更新操作的静默失败

```rust
// ❌ 错误被吞掉
let _ = db.execute("DELETE FROM temp_table").await.ok();

// ✅ 记录后传播
db.execute("DELETE FROM temp_table")
    .await
    .inspect_err(|e| log::error!("Cleanup failed: {}", e))?;
```

#### 1.3 不当的 unwrap_or_default()
**风险**: 可能掩盖真实错误，导致业务逻辑错误

- 查找模式: `unwrap_or_default\(\)`
- 金额字段、状态字段、计数器等使用默认值
- 配置加载失败使用空值

```rust
// ❌ 余额查询失败返回 0，可能导致严重业务问题
let balance = query_balance(user_id).unwrap_or_default();

// ✅ 明确处理错误
let balance = query_balance(user_id)
    .map_err(|e| {
        log::error!("Failed to query balance for {:?}: {:?}", user_id, e);
        Error::BalanceQueryFailed
    })?;
```

#### 1.4 不当的 unwrap_or()
**风险**: 网络错误、配置错误被掩盖为默认值

- 查找模式: `unwrap_or\([^)]+\)`
- 环境变量、端口、URL 配置
- RPC 调用、外部 API 请求

```rust
// ❌ 网络错误被掩盖
let price = fetch_price().unwrap_or(old_price);

// ✅ 启动时明确失败，或使用熔断机制
let price = fetch_price().await
    .map_err(|e| Error::PriceFetchFailed { context: e })?;
```

#### 1.5 let _ = 忽略 must_use 值
**风险**: 忽略重要返回值，导致资源泄漏或逻辑错误

- 查找模式: `let _ = [a-z_]+\(`
- 查找模式: `let _ = .*\.execute`
- 查找模式: `let _ = .*\.commit`
- MutexGuard、事务提交、锁释放

```rust
// ❌ 忽略事务提交结果
let _ = tx.commit();

// ❌ 忽略锁的副作用
let _ = lock.lock();

// ✅ 显式处理
drop(lock);
tx.commit()?;

// ✅ 或使用 semicolon 表示有意识丢弃
lock.lock();
```

#### 1.6 assert! 在生产代码中
**风险**: release 模式下被优化掉，debug 模式才 panic

- 查找模式: `assert!\([^,)]+(,[^)]+)?\)`
- 参数验证、业务规则检查

```rust
// ❌ release 模式下不检查
assert!(amount > 0, "Amount must be positive");

// ✅ 运行时始终检查
if amount <= 0 {
    return Err(Error::InvalidAmount { amount });
}

// ✅ 或使用 debug_assert! 用于开发期检查
debug_assert!(config.is_valid());
```

### 2. 🟡 中严重度问题（Medium Severity）

#### 2.1 expect() 缺少有用的错误信息
**风险**: panic 时缺少调试上下文，难以定位问题

- 查找模式: `expect\("([^"]{0,20})"\)` - 消息少于 20 字符
- 查找模式: `expect\("failed"\)|expect\("error"\)|expect\("not found"\)`
- 检查是否包含足够的上下文（地址、ID、参数等）

```rust
// ❌ 信息不足
let config = load_config().expect("failed");

// ✅ 包含上下文
let config = load_config().expect(
    "Failed to load config from CONFIG_PATH env var"
);
```

#### 2.2 panic! 使用不当
**风险**: panic 信息不完整，调试困难

- 查找模式: `panic!\("([^"]{0,30})"\)` - 消息少于 30 字符
- 查找模式: `panic!\("not implemented"\)|panic!\("unreachable"\)`
- 检查是否包含请求参数、时间戳、地址等调试信息

```rust
// ❌ 缺少上下文
panic!("Invalid state");

// ✅ 包含调试信息
panic!(
    "Invalid state: expected Active, got {:?} for order {}",
    state, order_id
);
```

#### 2.3 ok() 静默忽略错误
**风险**: 错误被悄无声息地忽略，可能导致后续问题

- 查找模式: `\.ok\(\)` (排除有明确注释的测试场景)
- 环境变量加载、配置加载的错误忽略
- 非关键路径的错误处理

```rust
// ❌ 错误被吞掉
let result = some_operation().ok();

// ✅ 至少记录日志
if let Err(e) = some_operation() {
    log::warn!("Operation failed: {:?}", e);
}

// ✅ 或使用 inspect_err
some_operation()
    .inspect_err(|e| log::warn!("Operation failed: {:?}", e))
    .ok();
```

#### 2.4 parse().unwrap() 模式
**风险**: 字符串解析失败导致 panic

- 查找模式: `\.parse\(\)\.unwrap\(\)`
- 查找模式: `\.parse\(\)\.expect\(`
- 用户输入、配置文件、环境变量解析

```rust
// ❌ 解析失败 panic
let port: u16 = env::var("PORT").unwrap().parse().unwrap();

// ✅ 优雅处理错误
let port: u16 = env::var("PORT")
    .map_err(|e| Error::ConfigMissing("PORT".into()))?
    .parse()
    .map_err(|e| Error::ConfigInvalid {
        key: "PORT",
        value: env::var("PORT").unwrap_or_default(),
        source: e,
    })?;
```

#### 2.5 未经检查的数组/Vec 访问
**风险**: 越界访问导致 panic

- 查找模式: `\[[0-9]+\]` (不含 `.get()`)
- 查找模式: `\.as_ref\(\)\.map\(\)` 之后的直接索引

```rust
// ❌ 可能 panic
let item = items[0];

// ✅ 安全访问
let item = items.get(0).ok_or(Error::EmptyList)?;

// ✅ 或使用迭代器
let item = items.first().ok_or(Error::EmptyList)?;
```

### 3. 🟢 低严重度问题（Low Severity）

#### 3.1 冗长的 if-else 模式
**风险**: 代码可读性差，可以简化

- 查找 `if let Some()` 但 else 分支只包含 panic 的情况
- 可以用 `unwrap_or_else` 或 `ok_or_else` 简化

```rust
// ❌ 冗长
if let Some(value) = optional {
    value
} else {
    panic!("Missing value")
}

// ✅ 简洁
optional.expect("Missing value")

// ✅ 更好（带错误处理）
optional.ok_or(Error::MissingValue)?
```

#### 3.2 未使用 #[must_use] 警告
**风险**: 调用者可能忽略重要返回值

- 查找返回 Result 但没有 `#[must_use]` 的函数
- 查找返回重要状态但没有标记的函数

```rust
// ❌ 调用者可能忽略
fn process(data: &str) -> Result<usize, Error> {
    // ...
}

// ✅ 强制检查
#[must_use]
fn process(data: &str) -> Result<usize, Error> {
    // ...
}
```

#### 3.3 todo!() 和 unimplemented!() 在生产代码
**风险**: 功能未完成，执行到时会 panic

- 查找 `todo!\(|unimplemented!\(`
- 检查是否在测试或原型代码中

```rust
// ❌ 生产代码中未完成
fn complex_feature(input: Input) -> Output {
    // TODO: implement this
    todo!()
}

// ✅ 返回明确的错误
fn complex_feature(input: Input) -> Result<Output, Error> {
    Err(Error::NotImplemented {
        feature: "complex_feature".into()
    })
}
```

## 🧪 测试特性（test-utils）最佳实践

在编写测试代码时,如果需要在源码中添加测试辅助功能,应该使用 **条件编译特性** 来隔离测试代码:

### 使用 test-utils 特性

当测试需要访问源码中的内部辅助函数或 mock 功能时:

```rust
// ✅ 正确: 在 src/lib.rs 或其他源文件中使用特性门控
#[cfg(feature = "test-utils")]
pub mod testing {
    pub use super::internal_helpers;

    pub fn create_test_client() -> Client {
        // 测试专用的构造函数
        Client::new_for_testing()
    }
}

// 生产代码不会被编译
#[cfg(not(feature = "test-utils"))]
fn internal_helpers() {
    // 只在测试时可用
}
```

### 在 Cargo.toml 中声明特性

```toml
[features]
test-utils = []  # 不启用默认,测试时手动启用
```

### 运行测试时启用特性

**重要**: 如果项目使用了 test-utils 特性,在检查和运行测试时必须启用该特性:

```bash
# ❌ 错误: 如果代码依赖 test-utils,这会编译失败
cargo test
cargo check

# ✅ 正确: 启用 test-utils 特性
cargo test --features test-utils
cargo check --features test-utils

# CI/CD 中应该启用所有相关特性
cargo test --all-features
# 或者
cargo test --features "test-utils,other-features"
```

### 为什么这样做?

- ✅ **减小二进制大小**: 生产构建不包含测试代码
- ✅ **防止滥用**: 测试辅助函数不会在生产代码中意外调用
- ✅ **清晰分离**: 明确区分生产代码和测试代码
- ✅ **避免泄露**: 内部实现细节不会暴露给生产用户

### 检查清单

在编写测试相关代码时:

- [ ] 测试辅助代码放在 `src/testing.rs` 或类似模块中
- [ ] 使用 `#[cfg(feature = "test-utils")]` 门控测试代码
- [ ] 在 `Cargo.toml` 中声明 `test-utils` 特性(不启用默认)
- [ ] 运行 `cargo test` 时加上 `--features test-utils`
- [ ] 在 CI/CD 中使用 `--all-features` 或明确指定特性
- [ ] 文档中说明如何启用 test-utils 特性进行测试

## ✅ 正确使用场景（排除规则）

以下情况**可以**使用上述模式：

### 测试代码
```rust
#[test]
fn test_something() {
    let result = function_under_test().unwrap();  // ✅ 测试中可以
}
```

### 使用 test-utils 特性的测试辅助代码
```rust
// ✅ 源码中的测试辅助函数
#[cfg(feature = "test-utils")]
pub fn setup_test_db() -> Database {
    // 测试专用的数据库设置
    Database::in_memory()
}
```

### 明确注释说明
```rust
// 我们允许配置加载失败，使用默认值
let config = load_config().ok();  // ✅ 有明确注释
```

### 不变量保证
```rust
// 我们刚刚检查过 key 存在
let value = map.get(&key).expect("key exists");  // ✅ 有前置检查
```

### 启动时验证
```rust
// 启动时配置验证，失败应该快速失败
let db_url = env::var("DATABASE_URL")
    .expect("DATABASE_URL must be set");  // ✅ 启动时可以 panic
```

## 📋 检查范围

**重要**: 本检查覆盖**整个代码库**的所有 `.rs` 文件，包括：
- `src/` 目录下的所有源代码
- `tests/` 目录下的集成测试
- `benches/` 目录下的性能测试
- `examples/` 目录下的示例代码
- 其他任何 `.rs` 文件

### 检查工具与命令

使用 Grep 工具搜索所有 `.rs` 文件：

#### 核心搜索模式
```bash
# 1. unwrap() 使用
\bunwrap\(\)\b

# 2. .ok() 静默忽略
\.ok\(\)\s*;

# 3. unwrap_or_default
unwrap_or_default\(\)

# 4. unwrap_or
unwrap_or\(

# 5. expect 短消息
expect\("[^"]{0,20}"\)

# 6. panic 短消息
panic!\("[^"]{0,30}"\)

# 7. let _ = 忽略
let _ = [a-z_]+\(

# 8. assert! 在生产代码
assert!\([^,)]+(,[^)]+)?\)

# 9. 直接数组索引
\[[0-9]+\]

# 10. parse().unwrap
\.parse\(\)\.unwrap\(\)

# 11. 数据库 .ok()
\.execute\(.*\)\.await\.ok\(\)
\.fetch_optional\(.*\)\.await\.ok\(\)

# 12. todo! / unimplemented!
(todo|unimplemented)!\(
```

#### Clippy 自动检查

强烈建议先运行 Clippy 进行自动化检查：

```bash
# 启用所有 unwrap/expect 警告
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used

# 检查被忽略的 must_use
cargo clippy -- -W clippy::let_underscore_must_use

# 检查 panic 在生产代码
cargo clippy -- -W clippy::panic

# 检查 index out of bounds
cargo clippy -- -W clippy::indexing_slicing
```

## 📊 输出格式

请按以下格式输出报告：

### 文件名: `xxx.rs`

#### 🔴 高严重度
- **行号**: `<问题代码>`
  - **风险**: [描述风险]
  - **建议**: [改进建议]
  - **示例**:
    ```rust
    // 修复示例代码
    ```

#### 🟡 中严重度
- **行号**: `<问题代码>`
  - **风险**: [描述风险]
  - **建议**: [改进建议]

#### 🟢 低严重度
- **行号**: `<问题代码>`
  - **建议**: [改进建议]

---

### 📊 汇总统计

| 严重度 | 问题数量 | 主要影响 | 优先级 |
|--------|----------|----------|--------|
| 🔴 高 | ? | ? | P0 - 立即修复 |
| 🟡 中 | ? | ? | P1 - 尽快修复 |
| 🟢 低 | ? | ? | P2 - 改进代码质量 |

### ✅ 优先修复建议

1. **生产代码中的 unwrap() / expect()**
   - 使用 `?` 传播错误
   - 添加适当的错误上下文
   - 使用 `thiserror` 或 `anyhow` 管理错误类型

2. **数据库操作的静默失败**
   - 记录所有失败操作
   - 使用事务确保数据一致性
   - 考虑重试机制（针对暂时性错误）

3. **关键业务逻辑中的 unwrap_or_default()**
   - 金额、余额、状态等字段必须显式处理错误
   - 使用 Result 类型传播失败
   - 添加适当的日志记录

4. **配置和环境变量解析**
   - 启动时验证所有必需配置
   - 提供清晰的错误消息
   - 使用配置验证库（如 `config` crate）

5. **数组/Vec 的直接索引**
   - 使用 `.get()` 返回 Option
   - 使用 `.first()` / `.last()` 等安全方法
   - 添加边界检查

---

## 🛠️ 推荐工具和库

### 错误处理库
- **anyhow**: 通用错误处理，适合应用代码
  ```toml
  anyhow = "1.0"
  ```

- **thiserror**: 结构化错误定义，适合库代码
  ```toml
  thiserror = "2.0"
  ```

### 配置验证
- **config**: 配置管理，支持验证
- **serde**: 序列化/反序列化，类型安全

### 日志记录
- **tracing**: 结构化日志和追踪
- **log**: 标准日志接口

---

## 📚 参考资源

- [The Rust Book - Error Handling](https://doc.rust-lang.org/book/ch09-00-error-handling.html)
- [To panic! or Not to panic!](https://doc.rust-lang.org/book/ch09-03-to-panic-or-not-to-panic.html)
- [Rust Error Handling Best Practices](https://blog.csdn.net/StepLens/article/details/153835257)
- [Ant Group CeresDB - 关于Rust 错误处理的思考](https://rustmagazine.github.io/rust_magazine_2021/chapter_2/rust_error_handle.html)
- [Cloudflare Outage 2025 - Lessons from unwrap()](https://www.reddit.com/r/rust/comments/1p0susm/cloudflare_outage_on_november_18_2025_caused_by/?tl=zh-hans)

---

## 🎯 检查清单

在提交代码前，请确认：

- [ ] 生产代码中没有 `unwrap()`（除非有明确注释说明为什么不会失败）
- [ ] 所有 `expect()` 都包含有用的上下文信息
- [ ] 数据库操作失败都有适当的错误处理
- [ ] 关键业务逻辑（金额、余额等）不会使用默认值掩盖错误
- [ ] 配置加载失败会在启动时明确报错
- [ ] 数组/Vec 访问使用安全方法
- [ ] 函数返回重要结果时标记了 `#[must_use]`
- [ ] 通过 `cargo clippy` 检查没有警告
- [ ] 通过 `cargo test` 确保所有测试通过
- [ ] **如果使用了 test-utils 特性,测试时使用 `--features test-utils`**
- [ ] **源码中的测试辅助代码使用 `#[cfg(feature = "test-utils")]` 门控**
- [ ] **生产构建验证: `cargo build --release` 不包含测试代码**

---

## 🔄 工作流程

```bash
# 1. 运行 Clippy 进行自动化检查
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used

# 2. 使用本命令进行手动检查
# 搜索所有 .rs 文件中的错误容忍模式

# 3. 修复高严重度问题
# 优先处理可能导致生产事故的问题

# 4. 运行测试确保没有破坏功能
# 如果项目使用 test-utils 特性,需要加上 --features test-utils
cargo test --features test-utils  # 或 --all-features

# 5. 验证生产构建不包含测试代码
cargo build --release

# 6. 提交前再次检查
cargo clippy && cargo test --features test-utils
```

---

## 💡 额外提示

### 错误上下文模式
```rust
// ❌ 错误上下文不足
let value = function().context("failed")?;

// ✅ 包含调试信息
let value = function()
    .with_context(|| format!(
        "failed to process user {} with config {:?}",
        user_id, config
    ))?;
```

### 错误转换模式
```rust
// 使用 ? 自动转换错误类型
// 使用 map_err 提供额外上下文
let result = risky_operation()
    .map_err(|e| Error::OperationFailed {
        operation: "risky_operation",
        source: e,
    })?;
```

### 链式错误处理
```rust
// 使用 inspect_err 记录但不改变错误流
result
    .inspect_err(|e| log::warn!("Operation failed: {:?}", e))
    .ok();

// 使用 or_else 提供回退
value.or_else(|_| fetch_default_value())
```
