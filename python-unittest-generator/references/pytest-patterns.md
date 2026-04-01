# Pytest 测试模式参考

> 本文件是 `python-unittest-generator` 技能的参考文件。
> 当选择 pytest 作为测试框架时，使用本文件中的模板和模式。

## 目录

- [基础测试模板](#基础测试模板)
- [Fixture 模式](#fixture-模式)
- [参数化测试](#参数化测试)
- [异常测试](#异常测试)
- [Mock 模式](#mock-模式)
- [目录结构](#目录结构)
- [覆盖率配置](#覆盖率配置)
- [并发执行](#并发执行)

---

## 基础测试模板

```python
"""<模块路径> 的测试 —— pytest 测试套件。"""
import pytest
from unittest.mock import patch, MagicMock
import json
import os
import tempfile

from <模块导入路径> import <类名>, <函数名>


class Test<类名>:
    """<类名> 的全面测试。"""

    # --- 构造函数测试 ---

    def test_init_default(self):
        """测试默认初始化。"""
        obj = <类名>()
        assert obj.field == expected_default

    def test_init_custom_params(self):
        """测试自定义参数初始化。"""
        obj = <类名>(param=value)
        assert obj.param == value

    def test_init_invalid_params(self):
        """测试无效参数被拒绝。"""
        with pytest.raises(ValueError):
            <类名>(param=invalid_value)

    # --- 核心方法测试 ---
    # 每个公共方法需要：正常路径、边界情况、错误路径


# 独立函数测试（不需要类）
def test_<函数名>_normal():
    """测试正常输入。"""
    result = <函数名>(normal_input)
    assert result == expected


def test_<函数名>_edge_case():
    """测试边界输入。"""
    result = <函数名>(edge_input)
    assert result == expected
```

### pytest vs unittest 语法对照

| 功能 | pytest | unittest |
|------|--------|----------|
| 断言相等 | `assert x == y` | `self.assertEqual(x, y)` |
| 断言真值 | `assert x` | `self.assertTrue(x)` |
| 断言异常 | `with pytest.raises(ValueError):` | `with self.assertRaises(ValueError):` |
| 断言包含 | `assert item in collection` | `self.assertIn(item, collection)` |
| 断言 None | `assert x is None` | `self.assertIsNone(x)` |
| 测试前准备 | `@pytest.fixture` | `setUp()` |
| 参数化 | `@pytest.mark.parametrize` | `self.subTest()` |
| 跳过测试 | `@pytest.mark.skip(reason)` | `@unittest.skip(reason)` |

---

## Fixture 模式

### 基础 Fixture

```python
@pytest.fixture
def sample_object():
    """创建测试用实例。"""
    return <类名>(param="test_value")


def test_with_fixture(sample_object):
    """Fixture 自动注入。"""
    assert sample_object.field == "test_value"
```

### 带 Setup/Teardown 的 Fixture

```python
@pytest.fixture
def temp_output_dir():
    """创建临时输出目录，测试后自动清理。"""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield tmpdir


def test_save_to_file(temp_output_dir):
    """使用临时目录测试文件保存。"""
    filepath = os.path.join(temp_output_dir, "output.json")
    # 真实的文件写入测试
    ...
```

### 共享 Fixture（conftest.py）

在测试根目录创建 `conftest.py`，所有测试文件共享其中的 fixture：

```python
# tests/conftest.py
import pytest
from unittest.mock import MagicMock


@pytest.fixture
def mock_api_client():
    """共享的 mock API 客户端。"""
    client = MagicMock()
    client.chat.return_value = '{"result": "ok"}'
    return client
```

### Fixture Scope

```python
# 每个测试函数创建一次（默认）
@pytest.fixture
def fresh_instance():
    return MyClass()

# 每个测试模块创建一次
@pytest.fixture(scope="module")
def shared_resource():
    resource = ExpensiveResource()
    yield resource
    resource.cleanup()

# 整个测试会话只创建一次
@pytest.fixture(scope="session")
def global_config():
    return Config(test_mode=True)
```

---

## 参数化测试

### 基础参数化

```python
@pytest.mark.parametrize("input,expected", [
    ("点击登录", "click"),
    ("输入密码", "type"),
    ("等待3秒", "wait"),
    ("验证文本", "assert_text"),
])
def test_parse_action(input_str, expected):
    """参数化测试：解析不同操作指令。"""
    result = Parser.parse(input_str)
    assert result["action"] == expected
```

### 多参数 + 自定义 ID

```python
@pytest.mark.parametrize("x,y,expected", [
    (0, 0, 0),
    (1, 1, 2),
    (-1, 1, 0),
    (100, -50, 50),
], ids=["zeros", "positive", "mixed", "large"])
def test_calculate(x, y, expected):
    result = calculate(x, y)
    assert result == expected
```

### 参数化 + Fixture 组合

```python
@pytest.mark.parametrize("strategy", ["linear", "exponential"])
def test_retry_with_different_strategies(mock_api_client, strategy):
    """参数化测试与 fixture 组合使用。"""
    result = retry_operation(mock_api_client, strategy=strategy)
    assert result is not None
```

---

## 异常测试

```python
def test_divide_by_zero():
    """测试除零异常。"""
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)


def test_invalid_input():
    """测试无效输入异常。"""
    with pytest.raises(ValueError, match="无效"):
        validate("")


def test_exception_with_info():
    """测试异常包含详细信息。"""
    with pytest.raises(CustomError) as exc_info:
        raise CustomError("error message", code=400)
    assert exc_info.value.code == 400
    assert "error" in str(exc_info.value)
```

---

## Mock 模式

### Mock 函数

```python
from unittest.mock import patch, Mock


@patch('src.module.external_api')
def test_with_mock(mock_api):
    """使用装饰器 mock。"""
    mock_api.return_value = {"status": "ok"}
    result = my_function()
    assert result["status"] == "ok"
    mock_api.assert_called_once()


def test_with_context_manager_mock():
    """使用上下文管理器 mock。"""
    with patch('src.module.external_api') as mock_api:
        mock_api.return_value = {"status": "ok"}
        result = my_function()
        assert result is not None
```

### Mock 对象属性

```python
def test_mock_property():
    """mock 对象的属性。"""
    mock_obj = Mock()
    mock_obj.status = "active"
    mock_obj.config = {"key": "value"}

    result = process(mock_obj)
    assert result is not None
```

### Mock 链式调用

```python
def test_mock_chained_calls():
    """mock 链式方法调用。"""
    mock_session = Mock()
    mock_session.get.return_value.json.return_value = {"data": []}

    result = fetch_data(mock_session)
    assert result == []
```

### autospec 确保接口一致

```python
@patch('src.module.ExternalService', autospec=True)
def test_with_autospec(mock_service_class):
    """autospec 确保 mock 遵循真实接口。"""
    mock_service = mock_service_class.return_value
    mock_service.process.return_value = "result"

    # 如果调用不存在的方法，会立即报错
    result = my_code(mock_service)
    assert result == "result"
```

---

## 目录结构

```
tests/                           # pytest 标准目录
├── conftest.py                  # 共享 fixture
├── unit/                        # 单元测试
│   ├── __init__.py
│   ├── test_<模块>.py
│   └── ...
├── integration/                 # 集成测试（可选）
│   ├── __init__.py
│   └── test_<集成场景>.py
└── reports/                     # 覆盖率报告
```

### pyproject.toml 配置

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "-v",
    "--tb=short",
    "--strict-markers",
]
markers = [
    "slow: 标记慢速测试",
    "integration: 标记集成测试",
]
```

---

## 覆盖率配置

### 命令行运行

```bash
# 运行测试 + 覆盖率
pytest --cov=src --cov-branch --cov-report=term-missing --cov-report=html

# 只运行单元测试
pytest tests/unit/ --cov=src

# 并行执行 + 覆盖率
pytest -n auto --cov=src --cov-branch
```

### pyproject.toml 覆盖率配置

```toml
[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*", "*/test_*.py", "*/__pycache__/*"]
branch = true

[tool.coverage.report]
show_missing = true
fail_under = 90

[tool.coverage.html]
directory = "tests/reports/html"
```

### 编程方式运行

```python
#!/usr/bin/env python
"""运行 pytest 测试并度量覆盖率。"""
import subprocess
import sys

result = subprocess.run([
    sys.executable, "-m", "pytest",
    "tests/",
    "--cov=src",
    "--cov-branch",
    "--cov-report=term-missing",
    "--cov-report=html:tests/reports/html",
    "--cov-fail-under=90",
    "-v",
])

sys.exit(result.returncode)
```

---

## 并发执行

使用 `pytest-xdist` 并行运行测试，大幅缩短执行时间：

```bash
# 安装
pip install pytest-xdist

# 自动并行（按 CPU 核心数）
pytest -n auto

# 指定进程数
pytest -n 4

# 并行 + 覆盖率
pytest -n auto --cov=src --cov-branch
```

> 注意：并发执行要求测试之间完全独立，无共享状态。这与本技能的"每个测试必须自包含"原则一致。
