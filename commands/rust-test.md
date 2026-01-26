---
name: rust-test
description: 执行指定的 Rust 测试
parameters:
  - name: name
    type: string
    required: true
    description: 要执行的测试函数名称
tags:
  - rust
  - testing
---

执行名为 **{{name}}** 的 Rust 测试。

## 工作流程

1. **环境检测**：
   - 检测是否安装了 `cargo-nextest`
   - 检测项目是否使用了 `test-utils` 特性
   - 检测是否有 `.config/nextest.toml` 配置文件

2. **搜索测试位置**：在项目中查找测试函数 `{{name}}`

3. **确认信息**：显示找到的 package、file 和 test 名称，如果信息唯一就不要确认了。

4. **执行测试**：根据环境检测结果选择最佳工具运行测试

## 环境检测

### 1. 检测 cargo-nextest

```bash
if command -v cargo-nextest &> /dev/null; then
    echo "✅ 检测到 cargo-nextest，将使用 nextest 运行测试"
    USE_NEXTEST=true
else
    echo "ℹ️  未检测到 cargo-nextest，将使用 cargo test"
    USE_NEXTEST=false
fi
```

### 2. 检测 test-utils 特性

```bash
if grep -r "test-utils" --include="Cargo.toml" . &> /dev/null; then
    echo "✅ 检测到 test-utils 特性"
    USE_TEST_UTILS="--features test-utils"
else
    echo "ℹ️  未检测到 test-utils 特性"
    USE_TEST_UTILS=""
fi
```

### 3. 检测 nextest 配置

```bash
if [ -f ".config/nextest.toml" ]; then
    echo "✅ 检测到 nextest 配置文件"
    HAS_NEXTEST_CONFIG=true
else
    echo "ℹ️  未检测到 nextest 配置文件"
    HAS_NEXTEST_CONFIG=false
fi
```

## 执行的命令

### 使用 cargo-nextest (推荐)

如果检测到 `cargo-nextest`：

```bash
cargo nextest run \
    --package <package> \
    $USE_TEST_UTILS \
    --test-name <test_name> \
    --no-capture \
    --success-output=immediate
```

### 使用 cargo test (fallback)

如果没有检测到 `cargo-nextest`：

```bash
cargo test \
    --package <package> \
    --test <file> \
    $USE_TEST_UTILS \
    -- {{name}} --exact --nocapture
```

## 关于 nextest

**cargo-nextest** 是一个比 `cargo test` 更快的测试运行器：

- ✅ **性能提升**: 20-30% 的速度提升
- ✅ **智能重试**: 自动重试 flaky tests
- ✅ **更好的输出**: 清晰的测试状态显示
- ✅ **超时控制**: 自动终止超时的测试
- ✅ **JUnit 报告**: 支持 CI/CD 集成

**安装方法**:
```bash
cargo install cargo-nextest
```

## 关于 test-utils 特性

test-utils 是一个条件编译特性，用于在源码中提供测试辅助功能：

- 使用 `#[cfg(feature = "test-utils")]` 门控的代码只在测试时编译
- 生产构建不会包含这些测试辅助代码，减小二进制大小
- 防止测试辅助函数在生产代码中意外调用

## 注意事项

- 测试名称必须完全匹配
- 支持 `#[test]` 和 `#[tokio::test]` 等测试宏
- `--no-capture` / `--nocapture` 选项会显示 println! 输出
- 如果找到多个匹配的测试，会询问用户选择哪一个
- 如果没有找到，会提示用户检查名称
- nextest 使用 `--test-name` 而不是 `-- <test_name> --exact`
