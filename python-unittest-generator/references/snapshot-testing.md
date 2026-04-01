# 快照测试参考

> 本文件是 `python-unittest-generator` 技能的参考文件。
> 当测试复杂输出结构（API 响应、配置对象、报告）时使用。

## 什么是快照测试

快照测试捕获测试输出的"快照"，后续运行自动比对。任何输出变化都会被检测到。

- **首次运行**：自动生成快照文件，作为基准
- **后续运行**：与基准快照比对，差异则失败
- **有意变更**：更新快照基准（`--snapshot-update`）

## 适用场景

| 适合快照测试 | 不适合快照测试 |
|-------------|---------------|
| API 响应结构 | 简单标量值（用 `assertEqual`） |
| 大型配置对象 | 时间敏感的输出 |
| HTML/XML 输出 | 包含随机 UUID 的输出 |
| 报告生成 | 仅验证部分字段的场景 |
| 序列化格式（JSON Schema） | 浮点数精度相关的结果 |

## 工具：Syrupy

Python 生态推荐的快照测试库，与 pytest 深度集成。

```bash
pip install syrupy
```

### 基本用法

```python
# tests/unit/test_report.py
import pytest


def test_generate_report(snapshot, report_generator):
    """报告输出应与快照一致。"""
    report = report_generator.generate(test_case="登录测试")
    assert report == snapshot


def test_api_response_structure(snapshot, api_client):
    """API 响应结构应与快照一致。"""
    response = api_client.get("/api/status")
    assert response.json() == snapshot
```

### 快照文件

Syrupy 自动生成快照文件（`__snapshots__/test_report.ambr`）：

```
# name: test_generate_report
dict({
  'actions': list([
    dict({
      'action': 'click',
      'description': '点击登录按钮',
      'step': 1,
      'target': 'btn_login',
    }),
  ]),
  'status': 'completed',
  'test_case': '登录测试',
})
---
```

### 更新快照

当有意修改输出时：

```bash
# 更新所有快照
pytest --snapshot-update

# 更新特定测试的快照
pytest tests/unit/test_report.py::test_generate_report --snapshot-update

# 查看差异（不更新）
pytest --snapshot-details
```

### 动态值处理

对于包含时间戳、UUID 等动态值的输出：

```python
from datetime import datetime


def test_report_with_timestamp(snapshot, report_generator):
    """处理动态时间戳。"""
    report = report_generator.generate(test_case="测试")
    # 替换动态值后再比对
    report["timestamp"] = "<TIMESTAMP>"
    assert report == snapshot


# 或使用 syrupy 的 serializer 自定义
class MySerializer(syrupy.AbstractSerializer):
    def serialize(self, data):
        if isinstance(data, dict) and "timestamp" in data:
            data = {**data, "timestamp": "<TIMESTAMP>"}
        return super().serialize(data)
```

## 与 unittest 集成

Syrupy 主要面向 pytest。unittest 用户可手动实现简单的快照模式：

```python
import unittest
import json
import os


class SnapshotTestCase(unittest.TestCase):
    """简单的快照测试基类。"""

    snapshot_dir = os.path.join(os.path.dirname(__file__), '__snapshots__')

    def assertMatchSnapshot(self, data, snapshot_name):
        """比对输出与快照。"""
        snapshot_path = os.path.join(self.snapshot_dir, f"{snapshot_name}.json")

        if not os.path.exists(snapshot_path):
            # 首次运行：生成快照
            os.makedirs(self.snapshot_dir, exist_ok=True)
            with open(snapshot_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            self.skipTest(f"快照已生成：{snapshot_path}")

        with open(snapshot_path, 'r', encoding='utf-8') as f:
            expected = json.load(f)

        self.assertEqual(data, expected,
                        f"输出与快照不一致。如为有意变更，删除 {snapshot_path} 后重新运行。")


class TestReport(SnapshotTestCase):

    def test_generate_report(self):
        report = {
            "test_case": "登录测试",
            "actions": [
                {"step": 1, "action": "click", "target": "btn_login"}
            ]
        }
        self.assertMatchSnapshot(report, "login_report")
```

## 最佳实践

1. **快照文件应纳入版本控制**——团队共享基准，变更可追溯。
2. **快照粒度适中**——太大会导致频繁更新，太小失去价值。
3. **排除动态值**——时间戳、随机 ID、浮点精度应在比对前处理。
4. **CI 中禁止自动更新**——只在本地 `--snapshot-update`，防止 CI 引入意外变更。
5. **定期审查快照**——快照可能积累过期内容，定期清理。
