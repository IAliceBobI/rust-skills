# Rust 测试最佳实践

本文档提供 Rust 测试的最佳实践和常见模式。

## 测试组织

### 单元测试

与代码放在同一文件中：

```rust
// src/calculator.rs

pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn test_add_negative() {
        assert_eq!(add(-2, -3), -5);
    }
}
```

### 集成测试

放在 `tests/` 目录：

```
project/
├── src/
│   └── lib.rs
└── tests/
    └── integration_test.rs
```

```rust
// tests/integration_test.rs
use my_project;

#[test]
fn test_full_workflow() {
    let result = my_project::run_workflow();
    assert!(result.is_ok());
}
```

### 大型测试文件分离

当测试超过 50% 文件时，分离到 `_tests.rs`：

```rust
// src/parser.rs
pub fn parse(input: &str) -> Result<Ast> {
    // ...
}

#[cfg(test)]
#[path = "parser_tests.rs"]
mod tests;
```

```rust
// src/parser_tests.rs
use super::*;

#[test]
fn test_parse_simple() {
    // ...
}
```

## 测试命名

### 清晰的命名

```rust
// ❌ 不清晰
#[test]
fn test1() { }

#[test]
fn test_works() { }

// ✅ 清晰
#[test]
fn test_parse_empty_input_returns_error() {
    let result = parse("");
    assert!(matches!(result, Err(ParseError::EmptyInput)));
}

#[test]
fn test_add_negative_numbers() {
    assert_eq!(add(-2, -3), -5);
}
```

### 测试命名模式

```rust
// 测试正常情况
#[test]
fn test_<function>_<scenario>_returns_<expected>

// 测试错误情况
#[test]
fn test_<function>_with_<invalid_input>_returns_error

// 测试边界条件
#[test]
fn test_<function>_at_boundary_condition
```

## 测试断言

### 使用正确的断言

```rust
#[test]
fn test_assertions() {
    // 相等性断言
    assert_eq!(result, expected);
    assert_ne!(result, unexpected);

    // 布尔断言
    assert!(condition);
    assert!(!should_not_happen);

    // 带消息的断言
    assert_eq!(
        result,
        expected,
        "Expected {} but got {}",
        expected,
        result
    );

    // 匹配断言
    assert!(matches!(result, Ok(Some(value)) if value > 0));
}
```

### 测试 Result 类型

```rust
#[test]
fn test_result() {
    let result = operation();

    // 验证成功
    assert!(result.is_ok());

    // 验证错误
    assert!(result.is_err());

    // 获取值
    let value = result.unwrap();
    assert_eq!(value, expected);

    // 验证特定错误类型
    match result {
        Err(MyError::InvalidInput { field }) => {
            assert_eq!(field, "email");
        }
        _ => panic!("Expected InvalidInput error"),
    }
}
```

## 测试夹具和设置

### 使用 setup 函数

```rust
#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_config() -> Config {
        Config {
            timeout: Duration::from_secs(1),
            retries: 3,
        }
    }

    #[test]
    fn test_with_config() {
        let config = create_test_config();
        let result = run_with_config(config);
        assert!(result.is_ok());
    }
}
```

### 使用临时目录

```rust
#[test]
fn test_with_temp_dir() -> Result<()> {
    let temp_dir = tempfile::tempdir()?;
    let file_path = temp_dir.path().join("test.txt");

    // 使用 temp_dir 进行测试
    std::fs::write(&file_path, b"test content")?;

    // temp_dir 会自动清理
    Ok(())
}
```

## 参数化测试

### 使用测试宏

```rust
macro_rules! test_parse {
    ($($name:ident: $input:expr => $expected:expr),*) => {
        $(
            #[test]
            fn $name() {
                let result = parse($input);
                assert_eq!(result, $expected);
            }
        )*
    };
}

test_parse! {
    test_parse_number: "42" => Ok(Ast::Number(42)),
    test_parse_string: r#""hello""# => Ok(Ast::String("hello".into())),
    test_parse_empty: "" => Err(ParseError::EmptyInput)
}
```

### 使用数据驱动测试

```rust
#[test]
fn test_multiple_cases() {
    let cases = vec![
        ("2+2", "4"),
        ("3*3", "9"),
        ("10/2", "5"),
    ];

    for (input, expected) in cases {
        let result = evaluate(input);
        assert_eq!(result, expected, "Failed for input: {}", input);
    }
}
```

## 异步测试

### 使用 tokio::test

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_async_function() {
        let result = async_function().await;
        assert!(result.is_ok());
    }
}
```

### 测试超时

```rust
use tokio::time::{timeout, Duration};

#[tokio::test]
async fn test_with_timeout() {
    let result = timeout(
        Duration::from_secs(5),
        long_running_operation()
    ).await;

    assert!(result.is_ok());
    assert!(result.unwrap().is_ok());
}
```

## Mock 和测试替身

### 使用 trait 进行 mock

```rust
#[cfg_attr(test, mockall::automock)]
trait Database {
    async fn get_user(&self, id: u64) -> Result<User>;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_with_mock_db() {
        let mut mock_db = MockDatabase::new();
        mock_db
            .expect_get_user()
            .returning(|id| Ok(User { id, name: "Test".into() }));

        let service = UserService::new(mock_db);
        let user = service.get_user(1).await;
        assert!(user.is_ok());
    }
}
```

### 使用测试替身

```rust
// 生产代码
struct UserService<D: Database> {
    db: D,
}

// 测试代码
struct InMemoryDatabase {
    users: HashMap<u64, User>,
}

impl Database for InMemoryDatabase {
    async fn get_user(&self, id: u64) -> Result<User> {
        self.users.get(&id)
            .cloned()
            .ok_or_else(|| Error::NotFound(id))
    }
}

#[test]
fn test_with_in_memory_db() {
    let mut db = InMemoryDatabase::new();
    db.add_user(User { id: 1, name: "Test".into() });

    let service = UserService::new(db);
    let user = service.get_user(1).await;
    assert!(user.is_ok());
}
```

## 性能测试

### 使用 criterion（推荐）

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn fibonacci(n: u64) -> u64 {
    match n {
        0 => 1,
        1 => 1,
        _ => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

fn criterion_benchmark(c: &mut Criterion) {
    c.bench_function("fib 20", |b| {
        b.iter(|| fibonacci(black_box(20)))
    });
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
```

### 简单基准测试

```rust
#[test]
#[ignore] // 使用 --ignored 运行
fn benchmark() {
    let start = std::time::Instant::now();

    for _ in 0..1000 {
        expensive_operation();
    }

    let duration = start.elapsed();
    println!("Duration: {:?}", duration);
    assert!(duration.as_millis() < 100);
}
```

## 集成测试模式

### 测试 HTTP 服务

```rust
#[tokio::test]
async fn test_http_endpoint() {
    let app = create_app().await;

    let response = app
        .oneshot(Request::builder()
            .uri("/test")
            .body(Body::empty())
            .unwrap())
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);
}
```

### 测试数据库交互

```rust
#[tokio::test]
async fn test_database_transaction() -> Result<()> {
    let pool = create_test_pool().await?;

    let mut tx = pool.begin().await?;

    // 测试事务
    tx.execute("INSERT INTO users (name) VALUES ('test')").await?;

    // 回滚测试事务
    tx.rollback().await?;

    // 验证数据未持久化
    let count: i64 = pool
        .fetch_one("SELECT COUNT(*) FROM users WHERE name = 'test'")
        .await?;
    assert_eq!(count, 0);

    Ok(())
}
```

## 测试覆盖率

### 使用 tarpaulin

```bash
cargo install tarpaulin

# 生成覆盖率报告
cargo tarpaulin --out Html

# 覆盖特定测试
cargo tarpaulin --tests --out Html
```

### 使用 cargo-llvm-cov

```bash
cargo install cargo-llvm-cov

# 生成覆盖率报告
cargo llvm-cov --html

# 覆盖特定模块
cargo llvm-cov --html --package my-package
```

## 测试配置

### 跳过慢速测试

```rust
#[test]
#[ignore]
fn slow_test() {
    // 这个测试默认不运行
    // 使用 --ignored 运行
}

// 运行被忽略的测试
// cargo test -- --ignored
```

### 条件编译测试

```rust
#[cfg(test)]
mod tests {
    #[test]
    #[cfg(feature = "integration")]
    fn integration_test() {
        // 只在启用 integration feature 时运行
    }

    #[test]
    #[cfg(not(feature = "integration"))]
    fn unit_test() {
        // 只在未启用 integration feature 时运行
    }
}
```

## 测试最佳实践清单

- [ ] 每个公共函数都有测试
- [ ] 测试命名清晰描述被测试的场景
- [ ] 使用 `#[should_panic]` 测试 panic 场景
- [ ] 使用 mock 减少测试依赖
- [ ] 保持测试简单和独立
- [ ] 使用临时文件和目录，测试后清理
- [ ] 测试边界条件和错误情况
- [ ] 维护高测试覆盖率（目标 > 80%）
- [ ] 运行 `cargo test --all-features` 确保所有 features 可测试
- [ ] 如果项目使用 `test-utils` 特性，运行 `cargo test --features test-utils`
- [ ] 使用 `cargo clippy` 和 `cargo fmt` 保持代码质量
- [ ] 考虑使用 `cargo nextest` 获得更快的测试执行速度

## 现代化测试工具

### cargo nextest（推荐）

[nextest](https://nexte.st) 是一个更快的测试运行器，与 cargo test 兼容：

```bash
# 安装
cargo install cargo-nextest

# 运行测试（比 cargo test 快）
cargo nextest run

# 运行特定测试
cargo nextest run test_name

# 启用 features
cargo nextest run --features test-utils
cargo nextest run --all-features

# 查看测试输出
cargo nextest run --success-output

# 运行被忽略的测试
cargo nextest run --ignore-rust-version
```

**优势**:
- ✅ 更快的测试执行（并行化更好）
- ✅ 更好的输出格式
- ✅ 与 cargo test 兼容（无需修改测试代码）
- ✅ 支持 CI/CD 集成

### 使用 cargo llvm-cov 查看覆盖率

```bash
# 安装
cargo install cargo-llvm-cov

# 生成 HTML 覆盖率报告
cargo llvm-cov --html

# 启用 features
cargo llvm-cov --html --features test-utils

# 查看终端输出
cargo llvm-cov --html --open
```
