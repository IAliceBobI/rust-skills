---
name: rust-test
description: 使用 rust-quality-guard skill 执行指定的 Rust 测试
parameters:
  - name: name
    type: string
    required: true
    description: 要执行的测试函数名称
tags:
  - rust
  - testing
---

# Rust 测试执行

## 快速使用

```bash
# 如果项目使用 test-utils 特性
cargo nextest run --features test-utils {{name}}

有的项目没有 test-utils 特性，我们使用： cargo nextest run --all-features {{name}}

# 或使用 cargo test
cargo test --all-features -- {{name}} --exact --no-capture
```

## test-utils 特性

如果项目使用了 `test-utils` 特性：

### 在 Cargo.toml 中声明

```toml
[features]
test-utils = []
```

### 在源码中使用

```rust
#[cfg(feature = "test-utils")]
pub mod testing {
    pub fn create_test_client() -> Client {
        Client::new_for_testing()
    }
}
```

### 运行测试时启用

```bash
# ✅ 正确
cargo test --features test-utils
cargo nextest run --features test-utils

# ❌ 错误（如果代码依赖 test-utils）
cargo test
```

## 关于 cargo-nextest

**cargo-nextest** 是比 `cargo test` 更快的测试运行器：

- ✅ 性能提升 20-30%
- ✅ 智能重试 flaky tests
- ✅ 更好的输出显示
- ✅ 超时控制
- ✅ JUnit 报告支持

安装方法：
```bash
cargo install cargo-nextest
```

## 直接使用 cargo 命令

### 使用 cargo-nextest (推荐)

```bash
cargo nextest run \
    --package <package> \
    --features test-utils \
    --test-name <test_name> \
    --no-capture \
    --success-output=immediate
```

### 使用 cargo test (fallback)

```bash
cargo test \
    --package <package> \
    --test <file> \
    --features test-utils \
    -- {{name}} --exact --no-capture
```

## 详细文档

更多测试最佳实践和调试技巧，请参考：
- `rust-skills:rust-quality-guard` skill
- `references/testing_best_practices.md` - 测试最佳实践
- `references/error_handling_patterns.md` - 错误处理模式

## 注意事项

- 测试名称必须完全匹配
- 支持 `#[test]` 和 `#[tokio::test]` 等测试宏
- `--no-capture` / `--no-capture` 选项会显示 println! 输出
- 如果找不到测试，会提示检查名称

## 常见问题

### 测试隔离问题

症状：批量执行失败，单独执行通过

原因：共享资源污染、状态冲突

解决方案：
- 添加测试隔离
- 使用独立的测试账户
- 在测试前重置状态

### 逻辑错误问题

症状：批量和单独执行都失败

解决方案：
- 查看错误堆栈信息
- 分析失败原因
- 修复代码逻辑
