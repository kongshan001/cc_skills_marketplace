# 属性测试（Property-Based Testing）参考

> 本文件是 `python-unittest-generator` 技能的参考文件。
> 当测试数据解析、格式转换、边界值探索等场景时使用。

## 什么是属性测试

传统测试（示例测试）：给定特定输入，检查特定输出。

```python
# 示例测试：只验证一个特定情况
def test_parse_int():
    assert int("42") == 42
```

属性测试：声明**不变量**（属性），框架自动生成数百个随机输入来验证。

```python
# 属性测试：验证所有有效整数字符串
@given(st.from_regex(r'-?\d+'))
def test_parse_int(s):
    result = int(s)
    assert str(result) == s.lstrip('0') or result == 0  # 往返一致
```

## 工具：Hypothesis

Hypothesis 是 Python 社区推荐的属性测试库，有学术支持（OOPSLA 2025 论文）。

```bash
pip install hypothesis
```

## 与 unittest 集成

```python
import unittest
from hypothesis import given, settings, assume
from hypothesis import strategies as st


class TestParser(unittest.TestCase):
    """使用 Hypothesis 的 unittest 测试。"""

    @given(st.text(min_size=1, max_size=100))
    def test_parse_always_returns_dict(self, text):
        """无论输入什么文本，解析结果始终是 dict。"""
        result = Parser.parse(text)
        self.assertIsInstance(result, dict)

    @given(st.integers(min_value=0, max_value=1000))
    def test_step_number_always_positive(self, n):
        """步骤号始终 >= 0。"""
        record = ActionRecord(step=n)
        self.assertGreaterEqual(record.step, 0)
```

## 与 pytest 集成

```python
import pytest
from hypothesis import given, settings
from hypothesis import strategies as st


@given(st.text(min_size=1))
@settings(max_examples=200)
def test_parse_never_crashes(text):
    """解析器不应因任何输入而崩溃。"""
    try:
        Parser.parse(text)
    except (ValueError, TypeError):
        pass  # 已知的异常类型是可以接受的
    # 不应有其他异常（如 IndexError, AttributeError 等）
```

## 常用策略（Strategies）

### 基础类型

```python
st.integers(min_value=0, max_value=100)      # 整数
st.floats(allow_nan=False, allow_infinity=False)  # 浮点数（排除特殊值）
st.text(min_size=1, max_size=100)            # 字符串
st.booleans()                                 # 布尔值
st.none()                                     # None
st.just(42)                                   # 固定值
```

### 组合类型

```python
st.lists(st.integers(), min_size=1, max_size=10)  # 整数列表
st.dictionaries(st.text(), st.integers())          # 字典
st.tuples(st.text(), st.integers())                # 元组
st.one_of(st.integers(), st.text())                # 联合类型
```

### 中文文本

```python
# 中文字符策略
chinese_chars = st.characters(
    min_codepoint=0x4e00,
    max_codepoint=0x9fff,
    categories=('Lu', 'Ll', 'Lo', 'Nd')  # Unicode 分类
)

# 中文文本策略
chinese_text = st.text(
    alphabet=chinese_chars,
    min_size=1,
    max_size=50
)

# 混合中英文文本
mixed_text = st.text(
    alphabet=st.characters(
        min_codepoint=0x0020,
        max_codepoint=0x9fff
    ),
    min_size=1,
    max_size=100
)
```

### 自定义策略

```python
# 从枚举中生成
from enum import Enum

class Action(Enum):
    CLICK = "click"
    TYPE = "type"
    WAIT = "wait"

action_strategy = st.sampled_from([a.value for a in Action])

# 从正则表达式生成
action_text = st.from_regex(r'(点击|输入|等待)\w{1,10}按钮', fullmatch=True)

# 复合对象
action_record_strategy = st.builds(
    ActionRecord,
    step=st.integers(min_value=1, max_value=100),
    action=action_strategy,
    target=st.text(min_size=1, max_size=20),
    description=st.text(min_size=0, max_size=50)
)
```

## 何时使用属性测试

| 场景 | 推荐策略 |
|------|----------|
| 数据解析（字符串 → 结构体） | 属性测试 + 示例测试 |
| 序列化/反序列化往返 | 属性测试（验证 `parse(serialize(x)) == x`） |
| 排序/搜索算法 | 属性测试（验证不变量） |
| 格式转换（JSON/YAML/XML） | 属性测试（验证往返一致性） |
| 边界值探索 | 属性测试（自动发现边界） |
| 简单 CRUD 操作 | 示例测试即可 |
| UI 交互测试 | 示例测试即可 |

## 常见属性模式

### 往返一致性（Round-trip）

```python
@given(action_strategy)
def test_serialize_deserialize_roundtrip(self, action):
    """序列化再反序列化应得到原始对象。"""
    serialized = action.to_dict()
    deserialized = ActionRecord.from_dict(serialized)
    self.assertEqual(deserialized, action)
```

### 不变量检查（Invariant）

```python
@given(st.lists(st.integers(), min_size=2))
def test_sort_preserves_elements(self, lst):
    """排序后元素不变。"""
    sorted_lst = sorted(lst)
    self.assertEqual(sorted(sorted_lst), sorted_lst)  # 幂等
    self.assertEqual(Counter(sorted_lst), Counter(lst))  # 元素相同
```

### 鲁棒性（Never Crash）

```python
@given(st.text())
def test_parser_never_crashes(self, text):
    """解析器对任何输入都不应崩溃。"""
    try:
        Parser.parse(text)
    except (ValueError, TypeError):
        pass  # 已知异常 OK
```

## settings 配置

```python
from hypothesis import settings, Phase

# 增加示例数量（默认 100）
@given(...)
@settings(max_examples=500)
def test_thorough(self, ...):
    ...

# 禁用某些阶段（加速 CI）
@settings(phases=[Phase.generate, Phase.shrink])
def test_fast(self, ...):
    ...

# 设置超时
@settings(deadline=5000)  # 5 秒
def test_with_deadline(self, ...):
    ...
```

## 失败时的行为

Hypothesis 会自动**缩小**（shrink）失败用例到最小输入：

```
Falsifying example:
    test_parse_action(text='点击\u0000按钮')
# Hypothesis 从 "点击x\0\0\0...很长的随机字符串按钮" 缩小到最小失败输入
```

这个最小失败用例帮助快速定位问题根因。
