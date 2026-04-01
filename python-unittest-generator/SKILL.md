---
name: python-unittest-generator
description: >
  为现有 Python 代码库生成完整的 unittest 测试套件，支持自动化覆盖率度量。
  当用户想要创建单元测试、提升测试覆盖率、为现有 Python 代码生成测试用例、
  或搭建基于 unittest 的测试框架时，应使用本技能。
  当用户提到"unittest"、"单元测试"、"测试覆盖率"、"测试生成"、"测试框架"、
  "自动化测试"，或希望通过自动化测试验证代码质量时，也应触发本技能——
  即使用户没有明确提到"测试框架"。
---

# Python Unittest 测试生成器

为现有 Python 项目生成完整的 `unittest` 测试套件，目标覆盖率达到 90% 以上，
测试代码放在独立目录中，绝不触碰生产代码。

## 触发条件

- 用户希望为现有 Python 代码生成单元测试
- 用户希望度量或提升测试覆盖率
- 用户希望从零搭建测试框架
- 用户询问 Python 项目的测试策略

## 工作流程

### 阶段一：代码库分析

1. 递归扫描目标源码目录中的所有 `.py` 文件。
2. 对每个模块提取：
   - 所有公共类、方法及独立函数
   - 构造函数签名和关键参数
   - 返回类型和副作用
   - 外部依赖（第三方库的导入）
   - 模块级常量和数据类
3. 构建依赖关系图：哪些模块依赖哪些其他模块。
4. 区分"叶子模块"（无内部依赖）和"编排模块"（依赖多个模块）。
5. 检查现有测试文件，记录已覆盖的内容。

### 阶段二：测试目录结构

创建一个**独立隔离**的测试目录，镜像源码布局：

```
<测试根目录>/
├── __init__.py
├── test_helpers.py           # 共享工具函数（不是 pytest 的 conftest）
├── run_tests_with_coverage.py # 主入口：发现并运行所有测试
├── unit/                     # 单元测试，镜像 src 结构
│   ├── __init__.py
│   ├── test_<模块>.py        # 每个源码模块对应一个测试文件
│   └── ...
└── reports/                  # 覆盖率报告输出目录
```

关键规则：
- 测试目录必须是源码目录的**同级目录**，绝不能嵌套在源码内部。
- 每个 `__init__.py` 必须存在，以确保导入正常工作。
- 测试文件中通过调整 `sys.path` 使源码导入生效。

### 阶段三：生成测试文件

为每个源码模块生成对应的 `test_<模块>.py`，使用以下模板：

```python
"""<模块路径> 的测试 —— 自动生成的 unittest 测试套件。"""
import unittest
from unittest.mock import patch, MagicMock, PropertyMock, call
import json
import os
import sys
import tempfile
import time

# 确保源码可导入
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '<src相对路径>'))

from <模块导入路径> import <类名>, <函数名>


class Test<类名>(unittest.TestCase):
    """<类名> 的全面测试。"""

    def setUp(self):
        """每个测试前的准备工作。"""
        pass

    def tearDown(self):
        """每个测试后的清理工作。"""
        pass

    # --- 构造函数测试 ---

    def test_init_default(self):
        """测试默认初始化。"""
        pass

    def test_init_custom_params(self):
        """测试自定义参数初始化。"""
        pass

    def test_init_invalid_params(self):
        """测试无效参数被拒绝。"""
        pass

    # --- 核心方法测试 ---

    # 每个公共方法需要：
    #   - 正常路径（正常输入，期望输出）
    #   - 边界情况（空值、None、边界值）
    #   - 错误路径（无效输入，抛出异常）
    #   - 副作用验证（通过 mock 验证对协作者的调用）

    # --- 序列化/转换测试（如适用） ---


class Test<辅助函数>(unittest.TestCase):
    """独立函数的测试。"""
    pass


if __name__ == '__main__':
    unittest.main()
```

#### 测试生成规则

1. **每个公共方法至少 3 个测试**：正常路径、边界情况、错误情况。
2. **数据类（dataclass）**：测试字段默认值、自定义值、序列化（`to_dict`、`to_json`）。
3. **有分支的方法**：每个分支一个测试（使用 mock 控制分支条件）。
4. **抛出异常的方法**：用 `self.assertRaises` 测试每个异常路径。
5. **返回 Optional 的方法**：测试有值和 None 两种路径。
6. **类方法/静态方法**：尽可能不依赖完整类设置直接测试。
7. **外部依赖尽量少 mock**：仅 mock 不可控的网络请求（`requests`）、
   有副作用的硬件操作（`pydirectinput`、`win32gui`）、平台特定调用（`subprocess.Popen`）。
   对于 `json`、`re`、`PIL`、`numpy`、`base64`、`dataclasses` 等库，
   构造已知输入，使用真实实现验证真实输出。
8. **平台特定导入**（win32api 等）：仅在当前平台不可用时才 mock；测试回退路径。
9. **上下文管理器**：测试 `__enter__`/`__exit__` 行为。
10. **属性（property）**：测试 getter 行为；如需则 mock 底层数据。

### 阶段四：Mock 策略（最小化原则）

> **核心思想**：每个 mock 都是在说"我不信任这段代码的真实行为"。
> 只有当真实执行不可控、不可重复、或有副作用时，才使用 mock。
> 能用真实实现的，一律不用 mock。

#### Mock 决策流程

```
需要测试某个功能
    │
    ├─ 能否用真实输入 + 真实实现？
    │   └─ 是 → 直接用，零 mock
    │
    ├─ 是否涉及网络/外部 API？
    │   └─ 是 → 仅 mock HTTP 层（requests.Session）
    │
    ├─ 是否涉及平台特定硬件操作？
    │   └─ 是 → 仅 mock 硬件调用（pydirectinput、win32gui）
    │
    ├─ 是否涉及不可安装的重型依赖？
    │   └─ 是 → mock 该依赖，但测试被测代码的真实逻辑
    │
    └─ 其他情况 → 用真实实现，用 tempfile/temp变量 控制环境
```

#### 重型外部依赖（仅在必要时 mock）

以下依赖因涉及真实硬件/网络/平台，**必须 mock**：
- `requests` / `urllib`：网络请求不可控
- `pydirectinput`：鼠标键盘操作有副作用
- `win32gui` / `win32api`：平台特定，非 Windows 不可用
- `subprocess.Popen`：启动真实进程有副作用

以下依赖应**使用真实实现**，通过构造已知输入验证真实输出：
- `PIL.Image`：构造测试图像，执行真实的图像操作
- `numpy`：构造测试数组，执行真实的数值计算
- `json`：执行真实的序列化/反序列化
- `re`：执行真实的正则匹配
- `base64`：执行真实的编解码
- `time`：执行真实的时间计算（仅在需要 `time.sleep` 时 mock）
- `dataclasses`：创建真实的实例，测试真实的字段和属性
- `collections` / `pathlib` / `os.path`：使用真实实现

```python
# 好：使用真实 PIL 图像而非 mock
from PIL import Image
img = Image.new("RGB", (100, 100), color="red")  # 真实图像
encoded = client._encode_image(img)               # 真实编码

# 好：使用真实 numpy 数组而非 mock
import numpy as np
arr = np.array([[1, 2], [3, 4]])  # 真实数组
result = processor.normalize(arr) # 真实计算

# 必要时 mock：网络请求不可控
@patch('src.utils.glm_client.requests.Session')
def test_chat(self, mock_session):
    ...
```

#### 协作者对象（优先使用真实实例）

对于内部类的依赖，**优先创建真实实例**而非 mock：

```python
# 好：使用真实的 StateMemory
from src.agents.state_memory import StateMemory
memory = StateMemory(max_history=10)
memory.set_test_case("测试登录")
memory.add_action("click", "btn", "点击")
agent = DecisionAgent(glm_client=mock_client, test_case="测试", state_memory=memory)

# 而非：用 MagicMock 代替 StateMemory（丢失了真实行为验证）
# memory = MagicMock()
# memory.get_history_prompt.return_value = "..."  # 这是假数据

# 仅 mock 外部边界：GLMClient 涉及真实网络调用，可以 mock
mock_client = MagicMock()
mock_client.chat_with_image.return_value = '{"action": "click"}'
```

#### 文件系统（使用真实文件 + tempfile）

使用 `tempfile.TemporaryDirectory()` 或 `tempfile.NamedTemporaryFile()`
在临时目录中执行**真实的文件读写操作**，而不是 mock `open()`：

```python
# 好：真实的文件 I/O
def test_save_to_file(self):
    mem = StateMemory()
    mem.set_test_case("测试")
    with tempfile.TemporaryDirectory() as tmpdir:
        filepath = os.path.join(tmpdir, "output.json")
        mem.save_to_file(filepath)              # 真实写入
        self.assertTrue(os.path.exists(filepath))
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)                 # 真实读取 + 解析
        self.assertEqual(data["test_case"], "测试")

# 差：mock open()，丢失了真实序列化行为的验证
# @patch('builtins.open', mock_open(read_data='{"test_case": "测试"}'))
```

#### 子进程隔离

为避免不同测试文件间的 mock 泄漏（`sys.modules` 级别的 mock 注入
在串行运行时会产生残留），覆盖率运行脚本应**为每个测试模块启动独立子进程**，
然后合并覆盖率数据：

```python
# 每个模块独立子进程运行
for test_file in test_files:
    cmd = [sys.executable, "-m", "coverage", "run",
           "--data-file", f".coverage.unit_{module_name}",
           "--source", "src",
           "--branch",
           "-m", "unittest", f"unittest_tests.unit.{module_name}"]
    subprocess.run(cmd)

# 合并所有覆盖率数据
subprocess.run([sys.executable, "-m", "coverage", "combine"] + cov_files)
```

### 阶段五：覆盖率配置

创建覆盖率运行脚本：

```python
#!/usr/bin/env python
"""运行所有 unittest 测试并度量覆盖率。"""
import unittest
import coverage
import sys
import os

# 配置覆盖率
cov = coverage.Coverage(
    source=['<源码包>'],
    omit=['*/unittest_tests/*', '*/tests/*', '*/test_*.py', '*/__pycache__/*'],
    branch=True
)
cov.start()

# 发现并运行测试
loader = unittest.TestLoader()
suite = loader.discover('<测试根目录>', pattern='test_*.py')
runner = unittest.TextTestRunner(verbosity=2)
result = runner.run(suite)

cov.stop()
cov.save()

# 输出报告
print('\n' + '=' * 60)
print('覆盖率报告')
print('=' * 60)
cov.report(show_missing=True)

# 生成 HTML 报告
html_dir = os.path.join(os.path.dirname(__file__), 'reports', 'html')
cov.html_report(directory=html_dir)
print(f'\nHTML 报告：{html_dir}/index.html')

# 低于阈值则失败
total = cov.report()
if total < 90:
    print(f'\n失败：覆盖率 {total:.1f}% 低于 90% 阈值')
    sys.exit(1)

if result.failures or result.errors:
    sys.exit(1)
```

### 阶段六：执行与验证

1. 从测试目录运行 `python run_tests_with_coverage.py`。
2. 检查：
   - 所有测试通过（0 失败，0 错误）。
   - 总行覆盖率 >= 90%。
   - 没有被跳过的测试（除非有明确原因）。
3. 若覆盖率低于 90%，从报告中识别未覆盖的行，
   针对这些特定路径添加测试。
4. 反复迭代直到达到 90% 阈值。

## 核心原则：尽量减少 Mock，模拟真实运行环境

本技能最重要的原则：**只在万不得已时才使用 mock**。优先模拟真实运行环境，
让测试验证的是代码的真实行为，而非 mock 的行为。

### 真实优先原则（按优先级从高到低）

| 优先级 | 策略 | 适用场景 |
|--------|------|----------|
| 1 | 使用真实实现 | 文件 I/O（用 `tempfile`）、JSON 序列化、数据类操作、纯逻辑函数 |
| 2 | 使用轻量替代 | 用 `http.server` 搭建本地 HTTP 服务替代真实 API、用内存 SQLite 替代远程数据库 |
| 3 | 使用真实库（控制输入） | PIL 图像处理、numpy 数组运算、正则表达式——构造已知输入验证真实输出 |
| 4 | 仅 mock 外部边界 | 网络请求（requests）、第三方云 API、硬件操作（鼠标/键盘/屏幕截图） |
| 5 | 最后手段：mock 重型依赖 | 仅当依赖无法安装或运行环境不支持时（如 Linux 上 mock win32gui） |

### 具体指导

#### 应该使用真实实现的场景

```python
# 好：真实文件操作，用 tempfile 隔离
def test_save_to_file(self):
    mem = StateMemory()
    mem.set_test_case("测试")
    mem.add_action("click", "btn", "点击")
    with tempfile.TemporaryDirectory() as tmpdir:
        filepath = os.path.join(tmpdir, "output.json")
        mem.save_to_file(filepath)  # 真实的文件写入
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)     # 真实的文件读取和 JSON 解析
        self.assertEqual(data["test_case"], "测试")

# 好：真实的数据类操作
def test_action_record_to_dict(self):
    record = ActionRecord(step=1, action="click", target="btn", description="点击")
    d = record.to_dict()  # 真实的 dataclass 转换
    self.assertIsInstance(d, dict)
    self.assertEqual(d["step"], 1)

# 好：真实的图像编码
def test_encode_image(self):
    client = GLMClient(api_key="test_key")
    img = Image.new("RGB", (100, 100), color="red")  # 真实的 PIL 图像
    encoded = client._encode_image(img)               # 真实的 base64 编码
    decoded = base64.b64decode(encoded)
    self.assertTrue(len(decoded) > 0)

# 好：真实的正则匹配测试
def test_extract_steps_click(self):
    result = TestCaseParser.parse("点击登录按钮")  # 真实的正则解析
    self.assertEqual(result["steps"][0]["action"], "click")
```

#### 只有在必要时才 mock 的场景

```python
# 必要 mock：真实的网络请求不可控
@patch('src.utils.glm_client.requests.Session')
def test_chat_timeout(self, mock_session):
    # 真实环境中无法可靠模拟超时，必须 mock
    mock_session.return_value.post.side_effect = requests.exceptions.Timeout()
    ...

# 必要 mock：平台特定的系统调用
# 当前操作系统不是 Windows 时，win32gui 不存在，必须 mock
@patch('src.action.window_manager.win32gui')
def test_get_window_by_title(self, mock_win32):
    ...

# 必要 mock：会产生副作用的操作（鼠标点击、键盘输入）
@patch('src.action.input_executor.pydirectinput')
def test_click(self, mock_pdi):
    # 真实点击会干扰用户操作，必须 mock
    ...
```

#### 不应该 mock 的场景

```python
# 错误：mock 了不需要 mock 的东西
@patch('json.dumps')  # json 是标准库，不需要 mock
def test_to_json(self, mock_dumps):
    mock_dumps.return_value = '{"test": true}'
    ...

# 正确：直接调用真实的 json.dumps
def test_to_json(self):
    mem = StateMemory()
    mem.set_test_case("测试")
    result = mem.to_json()  # 真实的 JSON 序列化
    data = json.loads(result)
    self.assertEqual(data["test_case"], "测试")

# 错误：mock 了被测类的内部方法
@patch.object(MyClass, '_internal_method')
def test_public_method(self, mock_internal):
    ...

# 正确：测试真实的公共方法行为，让内部方法真实执行
def test_public_method(self):
    obj = MyClass()
    result = obj.public_method("input")  # _internal_method 真实执行
    self.assertEqual(result, expected)
```

### Mock 审计检查

在完成测试编写后，逐一检查每个 `patch`、`Mock`、`MagicMock` 的使用，
问自己三个问题：

1. **如果不 mock，测试会失败吗？** 如果不会失败，删掉 mock。
2. **mock 是否改变了被测代码的执行路径？** 如果是，这个 mock 是必要的。
3. **mock 的返回值是否真实可信？** 如果 mock 返回了生产中不可能出现的值，
   这个测试可能给出虚假的信心。

## 反模式（应避免）

- **不要直接测试私有方法**——通过公共方法间接测试。
- **不要跳过测试**——改为 mock 不可用的依赖。
- **不要把 `assertRaises` 当作笼统的捕获**——验证特定的异常类型。
- **不要 mock 被测类本身**——只 mock 它的依赖。
- **不要创建相互依赖的测试**——每个测试必须自包含。
- **不要硬编码文件路径**——使用 `os.path.join` 和 `tempfile`。
- **不要导入 pytest**——本技能仅使用 `unittest`。
- **不要 mock 标准库和纯逻辑**——`json`、`re`、`time`、`os.path`、数据类操作等应使用真实实现。
- **不要 mock 被测模块的内部方法**——测试公共接口，让内部逻辑真实执行。
- **不要为了提高覆盖率而过度 mock**——高覆盖率 + 大量 mock = 虚假的信心。

## 交付前检查清单

- [ ] 每个源码模块都有对应的测试文件
- [ ] 每个公共方法都有 >= 3 个测试（正常、边界、错误）
- [ ] Mock 使用已最小化（能真实执行的都用真实实现）
- [ ] 文件 I/O 测试使用 tempfile 而非 mock open()
- [ ] 没有被跳过的测试
- [ ] 覆盖率 >= 90%
- [ ] 测试从独立目录运行
- [ ] 已生成 HTML 覆盖率报告
- [ ] 单一 `run_tests_with_coverage.py` 脚本即可运行所有内容
