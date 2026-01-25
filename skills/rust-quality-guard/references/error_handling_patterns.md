# Rust 错误处理最佳实践

本文档提供了 Rust 错误处理的最佳实践和常见模式。

## 核心原则

### FAIL FAST - 永不吞没错误

**最重要**的错误处理原则：错误必须传播，不能静默失败。

### ❌ 禁止模式

```rust
// 1. 记录但继续执行
if let Err(e) = operation() {
    log::error!("Failed: {}", e);
}
// 继续执行 - 这是错误的！

// 2. unwrap_or 静默回退
let value = risky_operation().unwrap_or(default_value);

// 3. ok() 丢弃错误
let value = risky_operation().ok();

// 4. let _ = 忽略结果
let _ = risky_operation();
```

### ✅ 正确模式

```rust
// 1. 使用 ? 传播错误
operation()?;

// 2. 添加错误上下文
operation()
    .context("Failed to initialize service")?;

// 3. 记录并传播
operation()
    .map_err(|e| {
        tracing::error!("Operation failed: {e}");
        e
    })?;

// 4. 显式 match 处理
match operation() {
    Ok(value) => process(value),
    Err(e) => return Err(e.into()),
}
```

## 错误类型选择

### Library 代码（src/lib.rs，模块）

使用 `thiserror` 定义结构化错误类型：

```rust
use std::backtrace::Backtrace;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum MyError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error, Backtrace),

    #[error("Parse error: {0}")]
    Parse(String, Backtrace),

    #[error("Config not found: {path}")]
    ConfigNotFound {
        path: String,
        #[backtrace]
        backtrace: Backtrace,
    },
}

pub type Result<T> = std::result::Result<T, MyError>;
```

### Binary 代码（main.rs）

使用 `anyhow` 简化错误处理：

```rust
use anyhow::{Context, Result};

#[tokio::main]
async fn main() -> Result<()> {
    let config = load_config()
        .context("Failed to load configuration")?;

    run_service(config)
        .await
        .context("Service runtime error")?;

    Ok(())
}
```

### 测试代码

使用 `anyhow` 或简单的 `panic!`：

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_something() {
        let result = function_under_test()
            .expect("Test should succeed");

        assert_eq!(result, expected);
    }
}
```

## 常见错误处理模式

### 1. 类型转换错误

```rust
// ❌ 糟糕
let port: u16 = env::var("PORT")
    .unwrap()
    .parse()
    .unwrap();

// ✅ 更好
let port: u16 = env::var("PORT")
    .map_err(|e| Error::ConfigMissing("PORT".into()))?
    .parse()
    .map_err(|e| Error::ConfigInvalid {
        key: "PORT",
        value: env::var("PORT").unwrap_or_default(),
        source: e,
    })?;
```

### 2. 数据库操作错误

```rust
// ❌ 静默失败
let _ = db.execute("DELETE FROM temp").await.ok();

// ✅ 记录并传播
db.execute("DELETE FROM temp")
    .await
    .inspect_err(|e| {
        tracing::error!("Cleanup failed: {}", e);
    })?;
```

### 3. 可选配置

```rust
// ❌ 强制要求
let api_key = env::var("API_KEY")?;

// ✅ 可选配置
let api_key = env::var("API_KEY").ok();

// ✅ 带默认值（仅在适当场景）
let timeout = env::var("TIMEOUT")
    .ok()
    .and_then(|v| v.parse().ok())
    .unwrap_or(Duration::from_secs(30));
```

### 4. 上下文转换

```rust
use anyhow::Context;

// 添加多层上下文
let user = get_user(user_id)
    .context("Failed to fetch user from database")?
    .context(format!("While processing request for user {}", user_id))?;
```

## 错误传播模式

### 使用 ?

```rust
fn process() -> Result<()> {
    step1()?;
    step2()?;
    step3()?;
    Ok(())
}
```

### 使用 and_then

```rust
fn process() -> Result<Output> {
    step1()
        .and_then(step2)
        .and_then(step3)
}
```

### 使用 map_err

```rust
fn process() -> Result<()> {
    risky_operation()
        .map_err(|e| Error::CustomError {
            message: format!("Operation failed: {}", e),
            source: e,
        })?;
}
```

## 错误日志记录

### 结构化日志

```rust
use tracing::{error, warn, instrument};

#[instrument(skip(config))]
async fn run(config: Config) -> Result<()> {
    initialize(&config)
        .await
        .map_err(|e| {
            error!(
                error = &e as &dyn std::error::Error,
                "Failed to initialize with config: {:?}",
                config
            );
            e
        })?;

    Ok(())
}
```

### 条件日志

```rust
// 记录但不改变错误流
result
    .inspect_err(|e| {
        if e.kind() == io::ErrorKind::ConnectionRefused {
            tracing::warn!("Connection refused: {}", e);
        } else {
            tracing::error!("Unexpected error: {}", e);
        }
    })?
```

## 错误恢复模式

### 重试逻辑

```rust
use tokio::time::{sleep, Duration};
use backoff::{ExponentialBackoff, future::retry};

async fn with_retry<F, T, E>(f: F) -> Result<T, E>
where
    F: FnMut() -> Pin<Box<dyn Future<Output = Result<T, E>> + Send>>,
    E: std::fmt::Display,
{
    retry(ExponentialBackoff::default(), f).await
}
```

### 降级策略

```rust
// 仅在明确允许降级的场景
let price = match fetch_price_from_api().await {
    Ok(price) => price,
    Err(e) => {
        tracing::warn!("API failed, using cache: {}", e);
        fetch_price_from_cache()?
    }
};
```

## 测试中的错误处理

### 验证错误类型

```rust
#[test]
fn test_error_handling() {
    let result = operation();

    assert!(matches!(
        result,
        Err(MyError::InvalidInput { .. })
    ));

    if let Err(MyError::InvalidInput { field }) = result {
        assert_eq!(field, "email");
    }
}
```

### 测试错误上下文

```rust
#[test]
fn test_error_context() {
    let result = operation();

    let err = result.unwrap_err();
    assert!(err.to_string().contains("expected"));
    assert!(err.source().is_some());
}
```

## Clippy Lint

启用严格的错误检查：

```bash
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used
```

在 `clippy.toml`:

```toml
[warn-clippy]
unwrap_used = "deny"
expect_used = "deny"
panic = "deny"
```
