# 原始推荐方案 vs 当前 Skill 差异分析

> 分析时间：2026-04-01
> 背景：会话初期的调研阶段推荐了一套基于现有 Skills 组合的方案，实际实施后创建了自定义 Skill `python-unittest-generator`。本文档对比两者的差异。

---

## 一、差异总览

| 维度 | 原始推荐方案 | 当前实际 Skill | 差异性质 |
|------|-------------|---------------|----------|
| 测试框架 | pytest | unittest | 核心差异 |
| Skill 架构 | 拼接 3 个 Skill 组合使用 | 单一自定义 Skill | 架构差异 |
| Mock 策略 | 大量 mock（全 mock 外部依赖） | 最小化 mock（真实优先） | 理念差异 |
| 测试隔离 | 未考虑 | 子进程隔离 + 合并覆盖率 | 新增能力 |
| 目录结构 | `tests/` 标准目录 | `unittest_tests/` 独立目录 | 命名差异 |
| 覆盖率目标 | 80% | 90% | 更高要求 |
| 中文支持 | 无 | 全中文文档和注释 | 新增能力 |
| 运行方式 | `pytest --cov` | `coverage run -m unittest` + 子进程 | 工具链差异 |

---

## 二、原始推荐方案回顾

会话初期基于 4 个 Skills（`python-testing`、`tdd-workflow`、`test-driven-development`、`verification-loop`）的调研结果，推荐了 3 步组合方案：

```
Step 1: 激活 python-testing Skill
  → 生成 tests/ 目录结构
  → 生成 conftest.py 共享 fixtures
  → 每个模块对应的 test_*.py
  → pyproject.toml 中的 pytest + coverage 配置

Step 2: 用 tdd-workflow 的模式
  → 为每个函数/类生成测试用例
  → 覆盖：正常路径、边界条件、异常路径、Mock 外部依赖

Step 3: 用 verification-loop 执行自动验证
  → 生成验证报告
```

---

## 三、逐项详细对比

### 3.1 测试框架：pytest → unittest

**原始方案**：依赖 `python-testing` Skill，完全基于 pytest 生态：
- `conftest.py` 共享 fixtures
- `@pytest.fixture` 依赖注入
- `@pytest.mark.parametrize` 参数化
- `pytest.raises` 异常测试
- `pytest --cov` 覆盖率

**当前 Skill**：基于 Python 标准库 `unittest`：

| pytest 概念 | unittest 对应 |
|-------------|---------------|
| `@pytest.fixture` | `setUp()` / `tearDown()` |
| `conftest.py` | `test_helpers.py`（工具模块） |
| `@pytest.mark.parametrize` | `self.subTest()` 或多测试方法 |
| `pytest.raises(ValueError)` | `self.assertRaises(ValueError)` |
| `assert x == y` | `self.assertEqual(x, y)` |
| `pytest --cov` | `coverage run -m unittest` |
| `@pytest.mark.slow` | `@unittest.skipUnless(...)` |

**改动原因**：用户明确要求使用 Python 标准库的 `unittest`，不依赖第三方测试框架。

---

### 3.2 Skill 架构：3 个拼接 → 1 个自包含

**原始方案**：跨 Skill 上下文切换

```
激活 python-testing → 提取测试模式
  ↓
切换 tdd-workflow → 提取工作流
  ↓
切换 verification-loop → 提取验证方案
```

问题：
- 三个 Skill 的示例语言不一致（Python/TypeScript 混杂）
- 需要在不同 Skill 间翻译概念（如 Jest 的 `expect` → Python 的 `assert`）
- 无统一的步骤编号，容易遗漏

**当前 Skill**：单一文件 6 阶段自包含

```
阶段一：代码库分析
阶段二：测试目录结构
阶段三：生成测试文件
阶段四：Mock 策略（最小化原则）
阶段五：覆盖率配置
阶段六：执行与验证
```

---

### 3.3 Mock 策略：全 mock → 真实优先

**原始方案**引用 `python-testing` 的指导：

> "外部依赖必须 mock：`requests`、`cv2`、`easyocr`、`mss`、`win32gui`、
> `pydirectinput`、`subprocess.Popen`、文件 I/O、网络调用——全部 mock。"

**当前 Skill** 明确反转了这一理念：

> "只在万不得已时才使用 mock。优先模拟真实运行环境，
> 让测试验证的是代码的真实行为，而非 mock 的行为。"

具体差异：

| 依赖 | 原始方案 | 当前 Skill |
|------|----------|-----------|
| `json` | 可能 mock | 真实调用 |
| `re` | 可能 mock | 真实调用 |
| `base64` | 可能 mock | 真实调用 |
| `PIL.Image` | 可能 mock | `Image.new()` 创建真实图像 |
| `numpy` | 可能 mock | 构造真实数组 |
| 文件 I/O | 可能 mock `open()` | `tempfile` + 真实读写 |
| `requests` | mock | mock（网络不可控） |
| `pydirectinput` | mock | mock（有副作用） |
| `win32gui` | mock | mock（平台限制） |
| 数据类操作 | 可能 mock | 真实实例 + 真实字段访问 |

新增的 **Mock 审计三问**：
1. 如果不 mock，测试会失败吗？→ 不会则删掉
2. mock 是否改变了执行路径？→ 是则必要
3. mock 的返回值真实可信吗？→ 不真实则测试给出虚假信心

---

### 3.4 测试隔离：未考虑 → 子进程隔离

**原始方案**：未考虑多个测试文件一起运行时的 mock 泄漏问题。

**实际项目发现的问题**：
- `window_manager` 测试单独运行 41 tests 全部通过
- 但全量运行时偶发 1 个 failure
- 原因：`sys.modules` 级别的 mock 注入在串行运行时产生残留

**当前 Skill 的解决方案**：

```python
# 每个模块独立子进程运行，各自拥有独立的 sys.modules
for test_file in test_files:
    cmd = [sys.executable, "-m", "coverage", "run",
           "--data-file", f".coverage.unit_{module_name}",
           "--source", "src", "--branch",
           "-m", "unittest", f"unittest_tests.unit.{module_name}"]
    subprocess.run(cmd)

# 合并所有覆盖率数据
subprocess.run([sys.executable, "-m", "coverage", "combine"] + cov_files)
```

---

### 3.5 覆盖率目标：80% → 90%

| 指标 | 原始方案 | 当前 Skill | 实际达成 |
|------|----------|-----------|---------|
| 默认目标 | 80% | 90% | 98% |
| 关键路径 | 100% | 无额外要求 | 大部分 100% |
| 阈值检查 | 覆盖率报告人工看 | 脚本自动检查，低于 90% 报错 | 脚本输出通过/不通过 |

---

### 3.6 中文支持：无 → 全中文

**原始方案**：所有 Skill 均为英文示例，无中文测试场景。

**当前 Skill**：
- Skill 文档全中文
- 测试用例模板使用中文注释和 docstring
- 测试数据使用中文字符串（如 `"测试登录"`、`"点击按钮"`）
- 正则表达式覆盖中文关键词（`"验证"`、`"检查"`、`"确认"`、`"测试"`）

---

### 3.7 新增：交付检查清单

原始方案无质量门禁。当前 Skill 新增 9 项交付前检查：

- [ ] 每个源码模块都有对应的测试文件
- [ ] 每个公共方法都有 >= 3 个测试（正常、边界、错误）
- [ ] Mock 使用已最小化（能真实执行的都用真实实现）
- [ ] 文件 I/O 测试使用 tempfile 而非 mock open()
- [ ] 没有被跳过的测试
- [ ] 覆盖率 >= 90%
- [ ] 测试从独立目录运行
- [ ] 已生成 HTML 覆盖率报告
- [ ] 单一 `run_tests_with_coverage.py` 脚本即可运行所有内容

---

## 四、原始方案的不足与修正总结

| 不足 | 影响 | 修正方式 |
|------|------|----------|
| 仅支持 pytest | 无法满足 unittest 需求 | 全部重写为 unittest |
| 无中文指导 | 中文场景测试缺失 | 全中文文档 + 中文测试用例 |
| TypeScript 示例混杂 | Python 开发者需要翻译 | 纯 Python 示例 |
| 全量 mock 策略 | 测试验证 mock 而非真实行为 | 真实优先原则 + Mock 审计三问 |
| 无隔离方案 | 多文件运行时 mock 泄漏 | 子进程隔离 + 覆盖率合并 |
| 无质量门禁 | 交付标准模糊 | 9 项交付前检查清单 |
| 3 Skill 拼接复杂 | 上下文切换成本高 | 单一 Skill 6 阶段自包含 |

---

## 五、结论

当前自定义 Skill `python-unittest-generator` 相比原始推荐方案，在以下方面有显著改进：

1. **框架匹配**：从 pytest 切换到用户要求的 unittest
2. **测试可信度**：从全 mock 切换到真实优先，测试验证的是代码真实行为
3. **运行稳定性**：通过子进程隔离解决了 mock 泄漏问题
4. **质量标准**：从 80% 提升到 90%，并增加了交付检查清单
5. **可用性**：从 3 Skill 拼接简化为单一 Skill，全中文，纯 Python 示例

实际项目验证结果：551 个测试，98% 覆盖率，11/12 模块全部通过。
