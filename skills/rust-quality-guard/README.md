# Rust Quality Guard Skill

一个全面的 Rust 代码质量守护助手 skill，使用 cargo 原生工具确保代码质量。

## 功能特性

✅ **编写代码时指导** - 边写代码边遵循 FAIL FAST 原则和最佳实践
✅ **自动修复代码问题** - 使用 `cargo fix` 和 `cargo clippy --fix` 自动修复
✅ **代码格式化** - 使用 `cargo fmt` 自动格式化代码
✅ **严格 Lint 检查** - 使用 `cargo clippy` 检测不良实践
✅ **测试执行和分析** - 使用 `cargo test` / `cargo nextest` 运行测试
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

1. **编写 Rust 代码时** - 遵循 FAIL FAST 原则和最佳实践
2. **检查代码质量** - 使用 cargo clippy 检测不良实践
3. **执行 Rust 测试** - 运行测试并分析失败原因
4. **代码审查** - 审查代码质量和最佳实践
5. **准备提交代码前** - 执行全面的代码质量检查

### 手动调用

在 Claude Code 中，你可以明确要求使用此 skill：

```
"请使用 rust-quality-guard 检查我的代码质量"
"使用 rust-quality-guard 运行测试并分析失败原因"
"请用 rust-quality-guard 进行全面的代码质量检查"
"编写代码时使用 rust-quality-guard 确保遵循最佳实践"
```

## 核心 Cargo 命令

### 1. 自动修复代码问题

使用 cargo 原生工具自动修复编译器警告和 Clippy 建议：

```bash
# 修复编译器警告（安全修复）
cargo fix

# 修复编译失败的代码（只修复明确的问题）
cargo fix --broken-code

# 修复 Clippy 产生的警告（自动应用建议）
cargo clippy --fix

# 允许在有未提交更改的代码上修复
cargo clippy --fix --allow-dirty

# 自动格式化代码
cargo fmt

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

# 启用 features
cargo test --features test-utils
cargo test --all-features

# 运行被忽略的测试
cargo test -- --ignored
```

### 3. Clippy 严格检查

```bash
# 基础检查
cargo clippy

# 严格模式（禁止 unwrap/expect）
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used

# 将警告视为错误（CI 中推荐）
cargo clippy -- -D warnings

# 启用 pedantic lints
cargo clippy -- -W clippy::pedantic
```

### 4. 代码格式化

```bash
# 检查格式（CI 中使用）
cargo fmt --check

# 自动格式化
cargo fmt

# 格式化所有 workspace 成员
cargo fmt --all
```

## 完整质量检查流程

在提交代码前，按照以下步骤执行完整的检查：

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

## Clippy 配置

### 在 clippy.toml 中配置

在项目根目录创建 `clippy.toml`：

```toml
# 允许在测试中使用 unwrap/expect
allow-expect-in-tests = true
allow-unwrap-in-tests = true

# 禁止的方法
disallowed-methods = [
    { path = "std::result::Result::unwrap", reason = "Use ? operator instead" },
    { path = "std::option::Option::unwrap", reason = "Use ? operator or ok_or instead" },
]
```

### 在 Cargo.toml 中配置（推荐）

```toml
[lints.clippy]
# Pedantic lints（更严格，但可能有误报）
pedantic = "warn"

# 禁止在生产代码中使用 unwrap/expect
unwrap_used = "warn"
expect_used = "warn"
```

## Rustfmt 配置

在项目根目录创建 `rustfmt.toml`：

```toml
# 使用 2024 版本格式化风格
style_edition = "2024"

# 最大代码行宽度
max_width = 100

# 其他常用配置
use_small_heuristics = "Default"
reorder_imports = true
```

## 参考文档

Skill 包含两个详细的参考文档：

- `references/error_handling_patterns.md` - 错误处理最佳实践
- `references/testing_best_practices.md` - 测试最佳实践

这些文档包含详细的示例和模式，可以在开发过程中参考。

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

# 自动修复可修复的问题
echo "🔧 Auto-fixing issues..."
cargo fix --broken-code --allow-dirty
cargo clippy --fix --allow-dirty
cargo fmt

# 检查格式
echo "📝 Checking formatting..."
cargo fmt --check

# Clippy 检查
echo "🔍 Running Clippy..."
cargo clippy -- -D warnings

# 运行测试
echo "🧪 Running tests..."
cargo test --all-features

echo "✅ All checks passed!"
```

## 命令速查

```bash
# ===== 代码格式化 =====
cargo fmt --check    # 检查格式
cargo fmt            # 自动格式化

# ===== 自动修复 =====
cargo fix                           # 修复编译器警告
cargo fix --broken-code             # 修复编译失败的代码
cargo clippy --fix                  # 应用 Clippy 建议
cargo clippy --fix --allow-dirty    # 允许在未提交时修复

# ===== Clippy 检查 =====
cargo clippy                                                        # 基础检查
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used       # 严格模式
cargo clippy -- -D warnings                                        # 将警告视为错误

# ===== 测试 =====
cargo test                                    # 运行所有测试
cargo test --features test-utils              # 启用 features
cargo test --all-features                     # 启用所有 features
cargo test -- --show-output                   # 显示测试输出

# ===== 完整检查流程 =====
cargo fmt --check && \
cargo clippy --features test-utils -- -W clippy::unwrap_used -W clippy::expect_used && \
cargo test --features test-utils
```

## Skill 结构

```
rust-quality-guard/
├── SKILL.md                              # Skill 主文档
├── README.md                              # 本文件
└── references/
    ├── error_handling_patterns.md        # 错误处理最佳实践
    └── testing_best_practices.md         # 测试最佳实践
```

## 参考资源

### 官方文档
- [The Rust Book - Error Handling](https://doc.rust-lang.org/book/ch09-00-error-handling.html)
- [To panic! or Not to panic!](https://doc.rust-lang.org/book/ch09-03-to-panic-or-not-to-panic.html)
- [Cargo Book - cargo fix](https://doc.rust-lang.org/cargo/commands/cargo-fix.html)
- [Clippy Documentation - Lint Configuration](https://doc.rust-lang.org/stable/clippy/lint_configuration.html)
- [cargo test - The Cargo Book](https://doc.rust-lang.org/cargo/commands/cargo-test.html)

### 最佳实践文章
- [Mastering Cargo Clippy: Your Code's Best Friend (2026)](https://www.oreateai.com/blog/mastering-cargo-clippy-your-codes-best-friend/9d77854e4d05a402b27907e1d20ac54b)
- [Linting in Rust with Clippy](https://blog.logrocket.com/rust-linting-clippy/)
- [Rust 开发最佳实践（中文）](https://www.cnblogs.com/gyc567/p/19151256)
- [Cloudflare Outage 2025 - Lessons from unwrap()](https://www.reddit.com/r/rust/comments/1p0susm/cloudflare_outage_on_november_18_2025_caused_by/?tl=zh-hans)

### 相关工具
- [cargo-nextest](https://nexte.st) - 更快的测试运行器
- [cargo-llvm-cov](https://github.com/taiki-e/cargo-llvm-cov) - 测试覆盖率工具

## 许可证

MIT

## 贡献

欢迎提交问题和拉取请求！

## 作者

Created with ❤️ for Rust community
