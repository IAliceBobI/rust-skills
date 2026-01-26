---
description: "使用 rust-quality-guard skill 执行全面的代码检查和测试"
---

# 全面检查和测试命令

> **快捷方式**: 使用 `rust-quality-guard` skill 提供的自动化脚本和检查流程
> **测试工具**: 使用 `cargo nextest` 替代 `cargo test` 以获得更快的执行速度和更强大的功能

## 安装 cargo-nextest

```bash
# 使用 cargo install
cargo install cargo-nextest

# 或使用预编译二进制文件
# 访问: https://nexte.st/docs/installation/pre-built-binaries/
```

cargo-nextest 主要优势:
- ⚡ 更快的执行速度 - 并行运行测试
- 🎯 简洁的结果展示 - 清晰显示测试通过/失败状态
- 🔧 强大的功能 - 支持重试、超时、机器可读输出等
- 🔄 自动重试 - 失败的测试可以自动重试

## 快速使用

```bash
# 完整的检查流程（如果项目使用 test-utils 特性，加上 --features test-utils）
cargo fmt --check && \
cargo clippy --features test-utils -- -W clippy::unwrap_used -W clippy::expect_used && \
python3 scripts/check_error_tolerance.py && \
cargo nextest run --features test-utils --retries 3

# 或者使用 --all-features
cargo fmt --check && \
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used && \
python3 scripts/check_error_tolerance.py && \
cargo nextest run --all-features --retries 3
```

## 脚本位置

脚本位于 `rust-quality-guard` skill 中：
- `scripts/check_error_tolerance.py` - 错误容忍检查
- `scripts/run_rust_tests.py` - 测试执行和分析

如果当前项目中没有这些脚本：
```bash
# 从 skill 复制脚本
cp /Users/chenwei/.claude/plugins/cache/my-marketplace/myskills/4.1.12/skills/rust-quality-guard/scripts/*.py scripts/
```

## 检查步骤

### 步骤 1: 环境检测

```bash
# 检测 test-utils 特性
if grep -r "test-utils" --include="Cargo.toml" . &> /dev/null; then
    echo "✅ 检测到 test-utils 特性"
    USE_TEST_UTILS="--features test-utils"
else
    echo "ℹ️  未检测到 test-utils 特性"
    USE_TEST_UTILS=""
fi

# 检测 cargo-nextest
if command -v cargo-nextest &> /dev/null; then
    echo "✅ 检测到 cargo-nextest"
    USE_NEXTEST=true
else
    echo "ℹ️  未检测到 cargo-nextest"
    USE_NEXTEST=false
fi
```

### 步骤 2: 代码格式检查

```bash
cargo fmt --check
```

### 步骤 3: Clippy 检查（严格模式）

```bash
# 如果项目使用 test-utils 特性
cargo clippy $USE_TEST_UTILS -- -W clippy::unwrap_used -W clippy::expect_used

# 或者
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used
```

### 步骤 4: 错误容忍检查

```bash
# 使用 rust-quality-guard skill 提供的脚本
python3 scripts/check_error_tolerance.py
```

### 步骤 5: 运行测试

```bash
# 使用 rust-quality-guard skill 提供的脚本
python3 scripts/run_rust_tests.py $USE_TEST_UTILS

# 或直接使用 cargo nextest（推荐）
cargo nextest run $USE_TEST_UTILS --retries 3 --no-fail-fast
```

## 使用 run_rust_tests.py 脚本

`rust-quality-guard` skill 提供的测试脚本功能：

```bash
# 运行所有测试
python3 scripts/run_rust_tests.py

# 运行指定测试
python3 scripts/run_rust_tests.py test_login

# 启用 features
python3 scripts/run_rust_tests.py --features "test-utils"
python3 scripts/run_rust_tests.py --all-features
```

脚本会：
- 自动检测并使用 cargo-nextest（如果可用）
- 单独执行失败的测试以分析原因
- 区分测试隔离问题和逻辑错误
- 提供详细的修复建议

## FAIL FAST 原则

**最重要**的错误处理原则：错误必须传播，不能静默失败。

### ❌ 禁止模式

```rust
// 错误被记录但继续执行 - 这是错误的！
if let Err(e) = operation() {
    log::error!("Failed: {}", e);
}
// 继续执行...

// 静默回退
let value = risky_operation().unwrap_or(default_value);
```

### ✅ 正确模式

```rust
// 使用 ? 传播错误
operation()?;

// 添加错误上下文
operation().context("Failed to initialize service")?;
```

## test-utils 特性

如果项目使用了 `test-utils` 特性：

### 在 Cargo.toml 中声明

```toml
[features]
test-utils = []  # 不启用默认,测试时手动启用
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
# ✅ 正确（使用 cargo nextest）
cargo nextest run --features test-utils --retries 3
cargo check --features test-utils
cargo clippy --features test-utils

# ❌ 错误（如果代码依赖 test-utils）
cargo nextest run
```

### 为什么这样做？

- ✅ 减小二进制大小
- ✅ 防止测试辅助函数在生产代码中意外调用
- ✅ 清晰分离生产代码和测试代码

## 详细文档

更多最佳实践和示例，请参考：
- `myskills:rust-quality-guard` skill
- `references/error_handling_patterns.md` - 错误处理模式
- `references/testing_best_practices.md` - 测试最佳实践

## 检查清单

提交代码前确认：
- [ ] 通过 `cargo fmt --check` 格式检查
- [ ] 通过 `cargo clippy` 检查（启用严格模式）
- [ ] 通过 `check_error_tolerance.py` 检查无高严重度问题
- [ ] 所有测试通过（使用 `cargo nextest run`）
- [ ] **如果使用 test-utils 特性，测试时启用该特性**
- [ ] **测试辅助代码使用 `#[cfg(feature = "test-utils")]` 门控**
- [ ] **生产构建不包含测试代码: `cargo build --release`**
- [ ] **如果项目有 doctests，运行 `cargo test --doc`**

## Clippy 配置

创建 `clippy.toml`:

```toml
allow-expect-in-tests = true
allow-unwrap-in-tests = true

disallowed-methods = [
    { path = "std::result::Result::unwrap", reason = "Use ? operator instead" },
    { path = "std::option::Option::unwrap", reason = "Use ? operator or ok_or instead" },
]
```

## 命令速查

```bash
# 格式检查
cargo fmt --check

# Clippy 严格模式
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used

# 错误容忍检查
python3 scripts/check_error_tolerance.py

# 运行测试（使用 cargo nextest）
cargo nextest run --all-features --retries 3

# 运行特定测试
cargo nextest run --all-features test_name1 test_name2

# 完整流程（一行命令）
cargo fmt --check && cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used && python3 scripts/check_error_tolerance.py && cargo nextest run --all-features --retries 3
```

## cargo nextest 高级功能

```bash
# 控制失败行为
cargo nextest run --no-fail-fast              # 运行所有测试，不因失败停止
cargo nextest run --max-fail=5               # 最多允许 5 次失败
cargo nextest run --max-fail=1:immediate     # 第一次失败后立即终止

# 并行控制
cargo nextest run -j 8                       # 使用 8 个并行线程

# 只运行被忽略的测试
cargo nextest run --run-ignored=only

# 压力测试
cargo nextest run --stress-count=100         # 每个测试运行 100 次
cargo nextest run --stress-duration=24h      # 运行 24 小时
```

## cargo nextest 配置

创建 `.config/nextest.toml`:

```toml
[profile.default]
# 失败后继续运行
fail-fast = false

# 重试设置
retries = 3

# 测试线程数（可选，默认使用所有 CPU）
# test-threads = 8
```

## 集成到 Git Hooks

创建 `.git/hooks/pre-commit`:

```bash
#!/bin/bash
set -e

echo "🔍 Running pre-commit checks..."

cargo fmt --check
cargo clippy --all-features -- -D warnings
python3 scripts/check_error_tolerance.py
cargo nextest run --all-features --retries 3

echo "✅ All checks passed!"
```

## 注意事项

⚠️ **Doctests 不支持**: nextest 目前不支持 doctests，需要单独运行:
```bash
cargo test --doc
```

## 参考链接

- 📖 [cargo-nextest 官方文档](https://nexte.st/)
- 💻 [cargo-nextest GitHub](https://github.com/nextest-rs/nextest)
- 📦 [cargo-nextest crates.io](https://crates.io/crates/cargo-nextest)
