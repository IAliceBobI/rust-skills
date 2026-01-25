# Rust Quality Guard Skill

一个全面的 Rust 代码质量守护助手 skill。

## 功能特性

✅ **错误容忍检查** - 检测 `unwrap()`、`ok()`、`unwrap_or_default()` 等可能掩盖错误的模式
✅ **测试执行和分析** - 运行测试并分析失败原因，提供修复建议
✅ **代码质量审查** - 全面检查代码质量，包括最佳实践
✅ **完整工作流程** - 提交前的一站式质量检查

## 安装

### 方法 1: 从 .skill 文件安装

```bash
# 将 rust-quality-guard.skill 复制到 Claude Code skills 目录
cp rust-quality-guard.skill ~/.claude/skills/

# 或者使用 claude plugin install (如果支持)
claude plugin install rust-quality-guard.skill
```

### 方法 2: 直接复制目录

```bash
# 复制整个 skill 目录到 Claude Code skills 目录
cp -r rust-quality-guard ~/.claude/skills/
```

## 使用方法

### 在 Claude Code 中自动激活

Skill 会在以下场景自动激活：

1. 检查 Rust 代码中的错误容忍问题
2. 执行 Rust 测试并分析失败原因
3. 审查 Rust 代码质量和最佳实践
4. 准备提交代码前的全面检查

### 手动调用

在 Claude Code 中，你可以明确要求使用此 skill：

```
"请使用 rust-quality-guard 检查我的代码错误容忍问题"
"使用 rust-quality-guard 运行测试并分析失败原因"
"请用 rust-quality-guard 进行全面的代码质量检查"
```

## 核心脚本

### 1. check_error_tolerance.py

检查 Rust 代码中的错误容忍和掩盖错误问题。

```bash
# 检查当前目录
python3 scripts/check_error_tolerance.py

# 检查指定目录
python3 scripts/check_error_tolerance.py src/
```

**检查项目**:
- 🔴 高严重度: `unwrap()`, `unwrap_or_default()`, `unwrap_or()`, `let _ =`, `assert!`
- 🟡 中严重度: `expect()`, `panic!`, `ok()`, `parse().unwrap()`, 直接数组索引
- 🟢 低严重度: `todo!()`, `unimplemented!()`

### 2. run_rust_tests.py

执行 Rust 测试并分析失败原因。

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

## 完整质量检查流程

在提交代码前，按照以下步骤执行完整的检查：

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

## 核心原则

### FAIL FAST - 永不吞没错误

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
```

**记住**: 添加日志**不是**处理错误。错误必须传播！

## 参考文档

Skill 包含两个详细的参考文档：

- `references/error_handling_patterns.md` - 错误处理最佳实践
- `references/testing_best_practices.md` - 测试最佳实践

这些文档包含详细的示例和模式，可以在开发过程中参考。

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

## CI/CD 集成

在 CI/CD 流程中添加质量检查：

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

## Git Hooks

创建 `.git/hooks/pre-commit` 自动化检查：

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

## Skill 结构

```
rust-quality-guard/
├── SKILL.md                              # Skill 主文档
├── scripts/
│   ├── check_error_tolerance.py          # 错误容忍检查脚本
│   └── run_rust_tests.py                 # 测试执行和分析脚本
└── references/
    ├── error_handling_patterns.md        # 错误处理最佳实践
    └── testing_best_practices.md         # 测试最佳实践
```

## 参考资源

- [The Rust Book - Error Handling](https://doc.rust-lang.org/book/ch09-00-error-handling.html)
- [To panic! or Not to panic!](https://doc.rust-lang.org/book/ch09-03-to-panic-or-not-to-panic.html)
- [Rust Error Handling Best Practices](https://blog.csdn.net/StepLens/article/details/153835257)
- [Cloudflare Outage 2025 - Lessons from unwrap()](https://www.reddit.com/r/rust/comments/1p0susm/cloudflare_outage_on_november_18_2025_caused_by/?tl=zh-hans)

## 许可证

MIT

## 贡献

欢迎提交问题和拉取请求！

## 作者

Created with ❤️ for Rust community
