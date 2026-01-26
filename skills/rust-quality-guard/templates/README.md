# Rust 配置文件模板

这个目录包含了 Rust 项目的最佳实践配置文件模板，基于 **2026 年最新标准**。

## 📁 模板文件

| 文件 | 用途 | 优先级 |
|------|------|--------|
| `rust-toolchain.toml` | 指定 Rust 版本和组件 | ⭐⭐⭐ |
| `Cargo.toml.template` | Cargo 项目配置模板 | ⭐⭐⭐ |
| `rustfmt.toml` | 代码格式化配置 | ⭐⭐⭐ |
| `clippy.toml` | Clippy linter 配置 | ⭐⭐ |
| `nextest.toml` | nextest 测试运行器配置 | ⭐ |

## 🚀 快速开始

### 1. 新建 Rust 项目时

```bash
# 创建新项目
cargo new my-project
cd my-project

# 复制配置文件模板
cp rust-toolchain.toml my-project/
cp rustfmt.toml my-project/
cp clippy.toml my-project/
cp Cargo.toml.template my-project/Cargo.toml

# 编辑 Cargo.toml，修改项目名称和依赖
vim my-project/Cargo.toml
```

### 2. 为现有项目添加配置

```bash
# 复制到项目根目录
cp rust-toolchain.toml /path/to/project/
cp rustfmt.toml /path/to/project/
cp clippy.toml /path/to/project/

# 将 Cargo.toml.template 的内容合并到现有的 Cargo.toml
# 注意：不要直接覆盖，需要手动合并
```

## 📋 配置文件详解

### rust-toolchain.toml

**用途**：确保团队成员和 CI/CD 使用相同的 Rust 版本

**关键配置**：
```toml
[toolchain]
channel = "1.83.0"           # 指定 Rust 版本
components = ["rustfmt", "clippy", "rust-src"]
```

**最佳实践**：
- ✅ 提交到版本控制
- ✅ 使用具体版本号（如 1.83.0）而不是 "stable"
- ✅ 包含 rust-src 用于 rust-analyzer

**参考资源**：
- [Overrides - The rustup book](https://rust-lang.github.io/rustup/overrides.html)
- [The rust-toolchain.toml file | Ian's Digital Garden](https://ianwwagner.com/the-rust-toolchain-toml-file.html)

---

### rustfmt.toml

**用途**：确保团队使用一致的代码风格

**关键配置**：
```toml
style_edition = "2024"       # 使用 Rust 2024 格式化风格
max_width = 100              # 最大行宽
imports_granularity = "StdExternalCrate"  # 导入分组
```

**最佳实践**：
- ✅ 总是使用配置文件（即使是空的）
- ✅ 使用 style_edition = "2024"
- ✅ 在 CI/CD 中运行 `cargo fmt --all --check`

**参考资源**：
- [Rust Edition Guide - Rustfmt Style Edition](https://doc.rust-lang.org/edition-guide/rust-2024/rustfmt-style-edition.html)
- [rustfmt Configurations](https://github.com/rust-lang/rustfmt/blob/main/Configurations.md)
- [rustfmt 2026 Configuration Guide](https://showsnote.com/public/0B/rustfmt-2026-configuration-guide)

---

### clippy.toml

**用途**：配置 Clippy 的检查规则和禁止的方法

**关键配置**：
```toml
allow-expect-in-tests = true
allow-unwrap-in-tests = true

[[disallowed-methods]]
path = "std::result::Result::unwrap"
reason = "使用 ? 运算符替代 unwrap"
```

**最佳实践**：
- ✅ 在 Cargo.toml 中使用 `[lints.clippy]` 配置 lint 级别
- ✅ 在 clippy.toml 中配置 disallowed-methods/types
- ✅ 与 CI/CD 集成：`cargo clippy -- -D warnings`

**参考资源**：
- [Clippy Documentation - Lint Configuration](https://doc.rust-lang.org/stable/clippy/lint_configuration.html)
- [Disallow code usage with custom clippy.toml](https://www.schneems.com/2025/11/19/find-accidental-code-usage-with-a-custom-clippy-toml/)
- [rust-clippy配置文件详解](https://blog.csdn.net/gitblog_00312/article/details/151243550)

---

### Cargo.toml.template

**用途**：Cargo 项目配置模板，包含 2026 年最佳实践

**关键特性**：
```toml
[package]
edition = "2024"              # 使用 2024 edition
rust-version = "1.83.0"       # 最低支持的 Rust 版本

[lints.rust]
missing_docs = "warn"
rust_2018_idioms = "warn"

[lints.clippy]
pedantic = "warn"
unwrap_used = "warn"
expect_used = "warn"
```

**最佳实践**：
- ✅ 使用 `[lints]` 配置替代 `.cargo/config.toml` 中的 rustflags
- ✅ Workspace 项目使用 `[workspace.lints]` 统一配置
- ✅ 使用 `[workspace.dependencies]` 统一依赖版本

**参考资源**：
- [This Development-cycle in Cargo: 1.93](https://blog.rust-lang.org/inside-rust/2026/01/07/this-development-cycle-in-cargo-1.93/)
- [RFC 3389: Manifest Lint](https://rust-lang.github.io/rfcs/3389-manifest-lint.html)
- [Workspaces - The Cargo Book](https://doc.rust-lang.org/cargo/reference/workspaces.html)

---

### nextest.toml

**用途**：配置 cargo-nextest 测试运行器

**关键配置**：
```toml
[[profile.default]]
slow-timeout = "60s"
retry-count = 0

[[profile.ci]]
slow-timeout = "30s"
retry-count = 2
```

**最佳实践**：
- ✅ 在 CI/CD 中使用 nextest 获得更快的测试反馈
- ✅ 为不同的环境配置不同的 profile
- ✅ 使用 test-partitioning 并行运行测试

**参考资源**：
- [Configuring nextest](https://nexte.st/docs/configuration/)
- [Configuration reference](https://nexte.st/docs/configuration/reference/)

## 🔧 使用指南

### 基本工作流

```bash
# 1. 格式化代码
cargo fmt

# 2. 自动修复问题
cargo fix
cargo clippy --fix --allow-dirty

# 3. 运行 linter
cargo clippy -- -W clippy::unwrap_used -W clippy::expect_used

# 4. 运行测试
cargo test

# 或者使用 nextest（更快）
cargo nextest run
```

### CI/CD 集成

```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # 格式检查
      - name: Check formatting
        run: cargo fmt --all --check

      # Clippy 检查
      - name: Run Clippy
        run: cargo clippy --all-targets --all-features -- -D warnings

      # 运行测试
      - name: Run tests
        run: cargo test --all-features

      # 或者使用 nextest（更快）
      # - name: Run tests with nextest
      #   run: cargo nextest run --all-features
```

## 📊 配置优先级

### Lints 配置优先级

1. **命令行参数**（最高优先级）
   ```bash
   cargo clippy -- -W clippy::unwrap_used
   ```

2. **Cargo.toml 中的 `[lints]`**
   ```toml
   [lints.clippy]
   unwrap_used = "warn"
   ```

3. **clippy.toml 配置文件**
   - 用于 disallowed-methods/types/identifiers

4. **默认配置**（最低优先级）

### Workspace 配置

在 workspace 根目录的 `Cargo.toml` 中：

```toml
[workspace.lints.clippy]
pedantic = "warn"
unwrap_used = "warn"
```

在成员 crate 的 `Cargo.toml` 中：

```toml
[lints]
workspace = true  # 继承 workspace 配置

# 或者覆盖特定 lint
[lints.clippy]
unwrap_used = "allow"  # 允许 unwrap
```

## 🎯 不同场景的配置

### Library 项目

```toml
[package]
edition = "2024"

[lints.rust]
unsafe_code = "forbid"  # 禁止 unsafe
missing_docs = "warn"

[dependencies]
thiserror = "1.0"  # 使用 thiserror 定义错误
```

### Binary 项目

```toml
[dependencies]
anyhow = "1.0"  # 使用 anyhow 简化错误处理
tokio = { version = "1.40", features = ["full"] }

[profile.release]
strip = true  # 减小二进制大小
lto = true    # 链接时优化
```

### 嵌入式项目

```toml
[dependencies]
# 使用 no_std 兼容的依赖

[profile.dev]
# 开发时也优化（加快编译）
opt-level = "s"

[profile.release]
opt-level = "s"  # 优化大小
strip = true
```

## 📚 进阶配置

### 自定义 Lint 规则

在 `clippy.toml` 中：

```toml
# 禁止使用特定方法
[[disallowed-methods]]
path = "std::process::Command::new"
reason = "使用自定义的 command wrapper"

# 禁止使用特定类型
[[disallowed-types]]
path = "std::collections::HashMap"
reason = "使用 FxHashMap 获得更好的性能"

# 禁止使用特定标识符
[[disallowed-identifiers]]
path = "foo"
reason = "使用更具描述性的名称"
```

### Feature 配置

```toml
[features]
default = ["std"]

test-utils = []  # 测试辅助特性

# 条件编译
std = []
alloc = []

# 特性组合
full = ["std", "test-utils"]
```

### 条件编译

在代码中：

```rust
// 仅在启用 test-utils 特性时编译
#[cfg(feature = "test-utils")]
pub mod testing {
    pub fn create_test_client() -> Client {
        // ...
    }
}

// 生产代码不包含测试辅助代码
#[cfg(not(feature = "test-utils"))]
fn internal_helpers() {
    // ...
}
```

## 🔗 相关资源

### 官方文档
- [The Cargo Book](https://doc.rust-lang.org/cargo/index.html)
- [Rust Edition Guide](https://doc.rust-lang.org/edition-guide/)
- [Clippy Documentation](https://doc.rust-lang.org/clippy/index.html)

### 最佳实践文章
- [Rust 开发最佳实践](https://www.cnblogs.com/gyc567/p/19151256)（中文）
- [Mastering Cargo Clippy: Your Code's Best Friend (2026)](https://www.oreateai.com/blog/mastering-cargo-clippy-your-codes-best-friend/9d77854e4d05a402b27907e1d20ac54b)
- [Mastering Rust Workspaces](https://medium.com/@nishantspatil0408/mastering-rust-workspaces-from-development-to-production-a57ca9545309)

### 工具
- [cargo-nextest](https://nexte.st) - 更快的测试运行器
- [cargo-llvm-cov](https://github.com/taiki-e/cargo-llvm-cov) - 测试覆盖率工具

## 📝 更新日志

- **2026-01-26**: 创建模板，基于 Rust 1.83 和 Cargo 1.93 最佳实践
- 使用 Rust 2024 edition
- 使用 `[lints]` 配置（Cargo 1.93+）
- 添加 nextest 配置支持

## 🤝 贡献

欢迎提交问题和拉取请求！

## 📄 许可证

MIT
