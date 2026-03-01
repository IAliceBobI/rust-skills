---
description: "使用 rust-quality-guard skill 执行全面的代码检查和测试 - 包含自动修复和完整检查流程"
---

# 全面检查和测试命令 (升级版)

> **快捷方式**: 使用 `rust-quality-guard` skill 提供的自动化脚本和检查流程
> **测试工具**: 使用 `cargo nextest` 替代 `cargo test` 以获得更快的执行速度和更强大的功能
> **新特性**: 包含自动修复功能,按照标准流程逐步检查和修复代码

## 检查流程概览

本次升级采用更加严格的检查和修复流程:

```bash
# 完整的检查和修复流程
1. cargo check --all-features         # 编译检查所有 features
2. 修复代码中的错误
3. cargo clippy --all-features         # Clippy 检查所有 features
4. 修复 clippy 警告
5. 全面测试 (cargo nextest/cargo test)
6. cargo fmt                           # 格式化所有代码
```

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

### 方式一: 完整的自动修复流程

```bash
# 如果项目使用 test-utils 特性,替换 --all-features 为 --features test-utils

# 步骤 1: Cargo Check 所有 features
cargo check --all-features

# 步骤 2: 自动修复编译器警告和错误
cargo fix --broken-code --allow-dirty --all-features

# 步骤 3: 验证 check 是否通过
cargo check --all-features

# 步骤 4: Cargo Clippy 所有 features
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used

# 步骤 5: 自动修复 clippy 警告
cargo clippy --fix --allow-dirty --allow-staged --all-features

# 步骤 6: 验证 clippy 是否通过
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used

# 步骤 7: 全面测试
cargo nextest run --all-features --retries 3
# 或者如果没有安装 nextest
cargo test --all-features

# 步骤 8: 格式化代码
cargo fmt

# 步骤 9: 最终验证
cargo fmt --check && \
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used && \
cargo nextest run --all-features --retries 3
```

**提示**:
- 自动修复后应该使用 `git diff` 检查修改
- 如果自动修复失败或有疑问,使用手动修复
- `--broken-code` 是实验性功能,可能不会修复所有错误

### 方式二: 一键执行 (推荐用于最终检查)

```bash
# 用于最终验证 (不自动修复,只检查)
cargo check --all-features && \
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used && \
cargo nextest run --all-features --retries 3 && \
cargo fmt --check
```

## 详细检查步骤

### 步骤 1: 环境检测

```bash
# 检测 test-utils 特性
if grep -r "test-utils" --include="Cargo.toml" . &> /dev/null; then
    echo "✅ 检测到 test-utils 特性"
    USE_TEST_UTILS="--features test-utils"
    USE_ALL_FEATURES=""
else
    echo "ℹ️  未检测到 test-utils 特性"
    USE_TEST_UTILS=""
    USE_ALL_FEATURES="--all-features"
fi

# 检测 cargo-nextest
if command -v cargo-nextest &> /dev/null; then
    echo "✅ 检测到 cargo-nextest"
    USE_NEXTEST=true
else
    echo "ℹ️  未检测到 cargo-nextest,将使用 cargo test"
    USE_NEXTEST=false
fi
```

### 步骤 2: Cargo Check 检查

```bash
# 检查所有 features 的编译错误
echo "🔍 步骤 1/6: 运行 cargo check..."
cargo check $USE_ALL_FEATURES $USE_TEST_UTILS

# 如果有错误,根据错误信息修改代码
# 常见错误类型:
# - 类型不匹配
# - 缺少依赖
# - 特性未启用
# - 生命周期问题
```

### 步骤 3: 修复 Cargo Check 错误

```bash
# 方式 1: 使用 cargo fix 自动修复编译器警告
echo "🔧 自动修复编译器警告..."
cargo fix --allow-dirty --all-features

# 方式 2: 自动修复编译器警告和部分错误 (更激进)
echo "🔧 自动修复编译器警告和错误..."
cargo fix --broken-code --allow-dirty --all-features

# 方式 3: 手动修复复杂错误
# 根据步骤 2 的错误信息,手动修改代码
# 示例修复:
# 1. 类型错误: 修正变量类型或添加类型转换
# 2. 缺少依赖: 在 Cargo.toml 中添加依赖
# 3. 特性问题: 确保使用了正确的 feature 标志
# 4. 导入错误: 添加正确的 use 语句
# 5. 死代码: 删除未使用的代码或添加 #[allow(dead_code)]

# 修复后重新运行 check
cargo check $USE_ALL_FEATURES $USE_TEST_UTILS
```

**cargo fix 说明**:
- `--allow-dirty`: 允许在未提交的更改情况下运行
- `--broken-code`: 尝试修复编译错误 (实验性功能)
- `--allow-dirty` + `--broken-code`: 最激进的修复模式

### 步骤 4: Cargo Clippy 检查

```bash
# 使用严格模式检查所有 features
echo "🔍 步骤 2/6: 运行 cargo clippy..."
cargo clippy $USE_ALL_FEATURES $USE_TEST_UTILS -- -W clippy::unwrap_used -W clippy::expect_used

# 如果有警告,根据警告信息修改代码
# 常见 clippy 警告:
# - unwrap_used: 使用 .unwrap() 可能导致 panic
# - expect_used: 使用 .expect() 可能导致 panic
# - 未使用的变量
# - 可以简化的表达式
# - 性能问题
```

### 步骤 5: 修复 Clippy 警告

```bash
# 方式 1: 使用 cargo clippy --fix 自动修复 (推荐)
echo "🔧 自动修复 clippy 警告..."
cargo clippy --fix --allow-dirty --allow-staged $USE_ALL_FEATURES $USE_TEST_UTILS

# 方式 2: 交互式修复 (需要手动确认每个修复)
echo "🔧 交互式修复 clippy 警告..."
cargo clippy --fix --allow-dirty $USE_ALL_FEATURES $USE_TEST_UTILS

# 方式 3: 手动修复复杂警告
# 根据步骤 4 的警告信息,手动修改代码
# 示例修复:

# ❌ 错误: 使用 unwrap
let value = some_option.unwrap();

# ✅ 正确: 使用 ? 或 ok_or
let value = some_option.ok_or_else(|| anyhow::anyhow!("Missing value"))?;

# ❌ 错误: 使用 expect
let value = some_result.expect("Failed to get value");

# ✅ 正确: 使用 ? 并添加上下文
let value = some_result.context("Failed to get value")?;

# 修复后重新运行 clippy
cargo clippy $USE_ALL_FEATURES $USE_TEST_UTILS -- -W clippy::unwrap_used -W clippy::expect_used
```

**cargo clippy --fix 说明**:
- `--fix`: 自动修复可以安全修复的警告
- `--allow-dirty`: 允许在有未提交更改时工作
- `--allow-staged`: 允许修改已暂存的文件
- ⚠️ 自动修复后应该使用 `git diff` 检查修改

### 步骤 6: 全面测试

```bash
# 使用 cargo nextest (推荐)
echo "🔍 步骤 3/6: 运行全面测试..."
if $USE_NEXTEST; then
    cargo nextest run $USE_ALL_FEATURES $USE_TEST_UTILS --retries 3
else
    cargo test $USE_ALL_FEATURES $USE_TEST_UTILS
fi

# 如果测试失败,根据失败信息修改代码
# 常见测试失败原因:
# - 断言失败
# - 逻辑错误
# - 边界条件处理不当
# - Mock 数据不正确
```

### 步骤 7: 格式化代码

```bash
# 最后一步: 格式化所有代码
echo "🔍 步骤 4/6: 格式化代码..."
cargo fmt

# 如果只想检查而不修改格式
cargo fmt --check
```

## 自动化脚本

### 完整的检查和修复脚本

创建 `scripts/full-check.sh`:

```bash
#!/usr/bin/env bash
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}ℹ️  $1${NC}"; }
echo_error() { echo -e "${RED}❌ $1${NC}"; }
echo_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
echo_step() { echo -e "${BLUE}➤ $1${NC}"; }

# 环境检测
echo_info "检测环境..."

if grep -r "test-utils" --include="Cargo.toml" . &> /dev/null; then
    echo_info "检测到 test-utils 特性"
    FEATURE_FLAGS="--features test-utils"
else
    echo_info "未检测到 test-utils 特性,使用 --all-features"
    FEATURE_FLAGS="--all-features"
fi

if command -v cargo-nextest &> /dev/null; then
    USE_NEXTEST=true
else
    USE_NEXTEST=false
    echo_warning "未检测到 cargo-nextest,将使用 cargo test"
fi

# 步骤 1: Cargo Check
echo_step "步骤 1/9: Cargo Check $FEATURE_FLAGS"
if ! cargo check $FEATURE_FLAGS; then
    echo_error "Cargo check 失败"
    echo_info "尝试自动修复..."
    cargo fix --broken-code --allow-dirty $FEATURE_FLAGS || {
        echo_error "自动修复失败,请手动修复错误后重试"
        exit 1
    }
    echo_info "重新检查..."
    cargo check $FEATURE_FLAGS
fi

# 步骤 2: Clippy (第一次检查)
echo_step "步骤 2/9: Cargo Clippy $FEATURE_FLAGS (严格模式)"
if ! cargo clippy $FEATURE_FLAGS -- -W clippy::unwrap_used -W clippy::expect_used; then
    echo_error "Clippy 检查失败"
    echo_info "尝试自动修复..."
    cargo clippy --fix --allow-dirty --allow-staged $FEATURE_FLAGS || {
        echo_error "自动修复失败,请手动修复警告后重试"
        exit 1
    }
    echo_info "重新检查..."
    cargo clippy $FEATURE_FLAGS -- -W clippy::unwrap_used -W clippy::expect_used
fi

# 步骤 3: 测试
echo_step "步骤 3/9: 运行测试"
if $USE_NEXTEST; then
    if ! cargo nextest run $FEATURE_FLAGS --retries 3; then
        echo_error "测试失败,请修复后重试"
        exit 1
    fi
else
    if ! cargo test $FEATURE_FLAGS; then
        echo_error "测试失败,请修复后重试"
        exit 1
    fi
fi

# 步骤 4: 格式化
echo_step "步骤 4/9: 格式化代码"
cargo fmt

# 最终验证
echo_step "步骤 5-9/9: 最终验证..."

echo_info "检查格式..."
if ! cargo fmt --check; then
    echo_error "格式检查失败"
    exit 1
fi

echo_info "重新运行 clippy..."
if ! cargo clippy $FEATURE_FLAGS -- -W clippy::unwrap_used -W clippy::expect_used; then
    echo_error "Clippy 检查失败"
    exit 1
fi

echo_info "重新运行测试..."
if $USE_NEXTEST; then
    if ! cargo nextest run $FEATURE_FLAGS --retries 3; then
        echo_error "测试失败"
        exit 1
    fi
else
    if ! cargo test $FEATURE_FLAGS; then
        echo_error "测试失败"
        exit 1
    fi
fi

echo_info "✅ 所有检查通过!"
```

使用方式:

```bash
chmod +x scripts/full-check.sh
./scripts/full-check.sh
```

### 快速修复脚本

创建 `scripts/quick-fix.sh`:

```bash
#!/usr/bin/env bash
set -e

echo "🔧 快速修复脚本..."

# 自动修复编译器警告和错误
echo "修复编译器警告和错误..."
cargo fix --broken-code --allow-dirty --all-features

# 自动修复 clippy 问题
echo "修复 clippy 警告..."
cargo clippy --all-features --fix --allow-dirty --allow-staged

# 格式化代码
echo "格式化代码..."
cargo fmt

echo "✅ 快速修复完成!"
echo "⚠️  请运行 'git diff' 检查修改"
echo "⚠️  请运行 './scripts/full-check.sh' 进行完整检查"
```

### 仅检查脚本 (不自动修复)

创建 `scripts/check-only.sh`:

```bash
#!/usr/bin/env bash
set -e

echo "🔍 运行完整检查 (不自动修复)..."

# 检测环境
if grep -r "test-utils" --include="Cargo.toml" . &> /dev/null; then
    FEATURE_FLAGS="--features test-utils"
else
    FEATURE_FLAGS="--all-features"
fi

# 只检查,不修复
cargo check $FEATURE_FLAGS
cargo clippy $FEATURE_FLAGS -- -W clippy::unwrap_used -W clippy::expect_used

if command -v cargo-nextest &> /dev/null; then
    cargo nextest run $FEATURE_FLAGS --retries 3
else
    cargo test $FEATURE_FLAGS
fi

cargo fmt --check

echo "✅ 所有检查通过!"
```

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
- `rust-skills:rust-quality-guard` skill
- `references/error_handling_patterns.md` - 错误处理模式
- `references/testing_best_practices.md` - 测试最佳实践

## 检查清单 (升级版)

提交代码前确认：

### 编译检查
- [ ] 通过 `cargo check --all-features` 编译检查
- [ ] 所有 features 组合都能正常编译
- [ ] 无编译错误或警告

### 代码质量
- [ ] 通过 `cargo clippy --all-features` 检查（启用严格模式）
- [ ] 修复所有 clippy 警告
- [ ] 无 `unwrap_used` 和 `expect_used` 警告（除非必要）
- [ ] 代码遵循 Rust 最佳实践

### 测试
- [ ] 所有测试通过（使用 `cargo nextest run --all-features`）
- [ ] **如果使用 test-utils 特性，测试时启用该特性**
- [ ] **测试辅助代码使用 `#[cfg(feature = "test-utils")]` 门控**
- [ ] **生产构建不包含测试代码: `cargo build --release`**
- [ ] **如果项目有 doctests，运行 `cargo test --doc --all-features`**

### 代码格式
- [ ] 通过 `cargo fmt` 格式化
- [ ] 代码格式统一
- [ ] 提交前运行 `cargo fmt --check` 验证

### 完整流程
- [ ] 按照顺序执行: check → 修复 → clippy → 修复 → 测试 → 格式化
- [ ] 每一步都通过后再进行下一步
- [ ] 最终验证所有检查都通过

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

## 命令速查 (升级版)

### 检查命令

```bash
# 1. Cargo Check
cargo check --all-features

# 2. Clippy 检查 (严格模式)
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used

# 3. 运行测试（使用 cargo nextest）
cargo nextest run --all-features --retries 3

# 4. 运行特定测试
cargo nextest run --all-features test_name1 test_name2

# 5. 格式化代码
cargo fmt

# 6. 检查格式
cargo fmt --check
```

### 自动修复命令

```bash
# 1. 自动修复编译器警告
cargo fix --allow-dirty --all-features

# 2. 自动修复编译器警告和错误 (实验性)
cargo fix --broken-code --allow-dirty --all-features

# 3. 自动修复 clippy 警告
cargo clippy --fix --allow-dirty --allow-staged --all-features

# 4. 自动格式化
cargo fmt
```

### 完整流程 (按顺序执行)

```bash
# 开发流程 (包含自动修复步骤)
cargo check --all-features                                    # 步骤 1: 检查
cargo fix --broken-code --allow-dirty --all-features          # 步骤 2: 自动修复
cargo check --all-features                                    # 步骤 3: 验证修复

cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used  # 步骤 4: clippy
cargo clippy --fix --allow-dirty --allow-staged --all-features                 # 步骤 5: 自动修复
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used  # 步骤 6: 验证修复

cargo nextest run --all-features --retries 3                 # 步骤 7: 测试
cargo fmt                                                      # 步骤 8: 格式化

# 最终验证 (不自动修复)
cargo fmt --check && \
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used && \
cargo nextest run --all-features --retries 3
```

### 快速修复

```bash
# 一键自动修复 (推荐用于开发阶段)
cargo fix --broken-code --allow-dirty --all-features && \
cargo clippy --fix --allow-dirty --allow-staged --all-features && \
cargo fmt

# 检查修复结果
cargo fmt --check && \
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used && \
cargo nextest run --all-features --retries 3
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

## 集成到 Git Hooks (升级版)

### 选项 1: 仅检查 (推荐用于严格流程)

创建 `.git/hooks/pre-commit`:

```bash
#!/usr/bin/env bash
set -e

echo "🔍 Running pre-commit checks..."

# 步骤 1: Cargo check
echo "  → Checking compilation..."
cargo check --all-features

# 步骤 2: Clippy
echo "  → Running clippy..."
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used

# 步骤 3: Tests
echo "  → Running tests..."
if command -v cargo-nextest &> /dev/null; then
    cargo nextest run --all-features --retries 3
else
    cargo test --all-features
fi

# 步骤 4: Format
echo "  → Checking format..."
cargo fmt --check

echo "✅ All checks passed!"
```

### 选项 2: 自动修复 + 检查 (推荐用于开发)

```bash
#!/usr/bin/env bash
set -e

echo "🔍 Running pre-commit checks with auto-fix..."

# 步骤 1: 自动修复编译器问题
echo "  → Auto-fixing compiler warnings..."
cargo fix --allow-dirty --all-features

echo "  → Checking compilation..."
cargo check --all-features

# 步骤 2: 自动修复 clippy 警告
echo "  → Auto-fixing clippy warnings..."
cargo clippy --fix --allow-dirty --allow-staged --all-features

echo "  → Running clippy check..."
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used

# 步骤 3: Tests
echo "  → Running tests..."
if command -v cargo-nextest &> /dev/null; then
    cargo nextest run --all-features --retries 3
else
    cargo test --all-features
fi

# 步骤 4: Format
echo "  → Formatting code..."
cargo fmt

echo "✅ All checks passed! Code formatted and ready to commit."
echo "ℹ️  Please review the changes with 'git diff' before committing."
```

### 选项 3: 完整自动修复 (最激进)

```bash
#!/usr/bin/env bash
set -e

echo "🔍 Running pre-commit checks with full auto-fix..."

# 步骤 1: 自动修复编译器问题和错误
echo "  → Auto-fixing compiler warnings and errors..."
cargo fix --broken-code --allow-dirty --all-features

echo "  → Checking compilation..."
cargo check --all-features

# 步骤 2: 自动修复 clippy 警告
echo "  → Auto-fixing clippy warnings..."
cargo clippy --fix --allow-dirty --allow-staged --all-features

echo "  → Running clippy check..."
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used

# 步骤 3: Tests
echo "  → Running tests..."
if command -v cargo-nextest &> /dev/null; then
    cargo nextest run --all-features --retries 3
else
    cargo test --all-features
fi

# 步骤 4: Format
echo "  → Formatting code..."
cargo fmt

echo "✅ All checks passed! Code formatted and ready to commit."
echo "⚠️  WARNING: Used --broken-code flag, please review changes carefully!"
echo "ℹ️  Check changes with: git diff"
```

### 安装 Git Hooks

```bash
# 复制脚本到 git hooks 目录
cp scripts/pre-commit .git/hooks/pre-commit

# 添加执行权限
chmod +x .git/hooks/pre-commit
```

## 注意事项

⚠️ **Doctests 不支持**: nextest 目前不支持 doctests，需要单独运行:
```bash
cargo test --doc --all-features
```

⚠️ **修复顺序很重要**: 必须按照 check → clippy → test → fmt 的顺序进行，因为:
1. check 发现基本的编译错误
2. clippy 发现代码质量问题 (需要代码能编译通过)
3. test 发现逻辑错误 (需要代码能编译运行)
4. fmt 只是格式化 (不影响功能)

⚠️ **自动修复的局限性**:

**cargo fix**:
- `--allow-dirty`: 允许在未提交的更改情况下运行
- `--broken-code`: 尝试修复编译错误 (实验性功能,可能不完美)
- 只能修复简单的警告,复杂错误需要手动修复
- 自动修复后应该 review 修改内容

**cargo clippy --fix**:
- 只能修复可以安全修复的警告
- 某些警告需要手动判断,不会被自动修复
- 自动修复后应该使用 `git diff` 检查修改
- 建议使用 `--allow-staged` 允许修改已暂存的文件

**最佳实践**:
```bash
# 1. 运行自动修复
cargo fix --broken-code --allow-dirty --all-features
cargo clippy --fix --allow-dirty --allow-staged --all-features

# 2. 检查修改
git diff

# 3. 如果满意,添加到暂存区
git add .

# 4. 如果不满意,手动调整或回退
git checkout -- <files>
```

⚠️ **Features 组合**:
- 使用 `--all-features` 检查所有 features 组合
- 如果项目有特定特性要求,使用 `--features feature1,feature2`
- 确保所有常用的 features 组合都被测试

⚠️ **自动修复的风险**:
- `--broken-code` 可能引入新的问题
- 自动修复可能改变代码语义 (虽然很少见)
- 建议在重要分支上手动 review 所有自动修复的更改
- 在 CI/CD 中使用检查模式 (不带 --fix)

## 常见问题

### Q: 为什么先 check 再 clippy?

A: check 只检查编译错误,clippy 检查代码质量和最佳实践。如果代码无法编译,clippy 也无法运行。

### Q: cargo fix 和 cargo clippy --fix 有什么区别?

A:
- `cargo fix`: 修复编译器警告 (如未使用的变量、死代码等)
- `cargo clippy --fix`: 修复 clippy 警告 (如代码风格、性能问题等)
- 通常需要两个都运行

### Q: --broken-code 标志安全吗?

A: `--broken-code` 是实验性功能,可能会:
- ✅ 修复很多常见的编译错误
- ⚠️ 偶尔产生不完美的修复
- ⚠️ 可能改变代码逻辑 (很少见)

建议:
- 在开发分支使用
- 自动修复后仔细 review
- 在重要提交前手动验证

### Q: 自动修复会破坏代码吗?

A: 通常不会,但建议在自动修复后 review 修改内容:
```bash
# 1. 运行自动修复
cargo fix --broken-code --allow-dirty --all-features
cargo clippy --fix --allow-dirty --allow-staged --all-features

# 2. 检查修改
git diff

# 3. 运行完整检查
./scripts/full-check.sh
```

### Q: 如果自动修复后代码无法编译怎么办?

A:
1. 检查 `git diff` 查看自动修复做了什么
2. 如果有问题,回退修改: `git checkout -- .`
3. 手动修复原始问题
4. 重新运行检查

### Q: 如何处理测试失败?

A:
1. 查看测试失败的详细信息
2. 使用 `cargo test -- --no-capture` 查看测试输出
3. 使用 `cargo nextest run --test-name` 运行特定测试
4. 添加日志或使用 debugger 调试

### Q: 如何加快检查速度?

A:
1. 使用 `cargo nextest` 替代 `cargo test`
2. 使用 `--workspace` 只检查 workspace 成员
3. 使用 `--package` 只检查特定包
4. 并行运行多个独立的检查

### Q: 应该在什么时候运行自动修复?

A:
- ✅ 开发阶段: 随时运行,快速修复问题
- ✅ 提交前: 运行完整检查流程
- ⚠️ 重要分支: 谨慎使用,仔细 review
- ❌ CI/CD: 不要使用自动修复,只用检查模式

## 工作流建议

### 开发新功能时

```bash
# 1. 编写代码
# ... 编辑代码 ...

# 2. 快速检查编译
cargo check

# 3. 自动修复简单问题
cargo fix --allow-dirty
cargo clippy --fix --allow-dirty --allow-staged

# 4. 运行相关测试
cargo test test_name

# 5. 完整检查和修复流程
cargo fix --broken-code --allow-dirty --all-features
cargo clippy --fix --allow-dirty --allow-staged --all-features
cargo fmt

# 6. 验证修复
./scripts/full-check.sh

# 7. 检查修改
git diff

# 8. 提交代码
git add .
git commit -m "feat: ..."
```

### 修复 bug 时

```bash
# 1. 运行失败的测试
cargo test failing_test

# 2. 修复代码
# ... 编辑代码 ...

# 3. 验证修复
cargo test failing_test

# 4. 自动修复相关问题
cargo fix --allow-dirty --all-features
cargo clippy --fix --allow-dirty --allow-staged --all-features

# 5. 完整检查
./scripts/full-check.sh

# 6. 提交修复
git add .
git commit -m "fix: ..."
```

### 日常开发循环

```bash
# 创建新分支
git checkout -b feature/new-feature

# 开发循环 (重复多次)
# 1. 编辑代码
# 2. 快速检查
cargo check
cargo clippy --fix --allow-dirty --allow-staged

# 3. 运行测试
cargo test

# 4. 提交小步进展
git add .
git commit -m "progress: ..."

# 完成后的完整检查
./scripts/full-check.sh

# 最终提交
git add .
git commit -m "feat: complete new feature"

# 推送到远程
git push origin feature/new-feature
```

### 提交前检查

```bash
# 方式 1: 使用脚本
./scripts/full-check.sh

# 方式 2: 手动执行
cargo fix --broken-code --allow-dirty --all-features
cargo clippy --fix --allow-dirty --allow-staged --all-features
cargo fmt

# 验证
cargo check --all-features && \
cargo clippy --all-features -- -W clippy::unwrap_used -W clippy::expect_used && \
cargo nextest run --all-features --retries 3

# 检查修改
git diff

# 提交
git add .
git commit -m "..."
```

## 参考链接

- 📖 [cargo-nextest 官方文档](https://nexte.st/)
- 💻 [cargo-nextest GitHub](https://github.com/nextest-rs/nextest)
- 📦 [cargo-nextest crates.io](https://crates.io/crates/cargo-nextest)
