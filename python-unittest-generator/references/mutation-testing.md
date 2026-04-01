# 变异测试参考

> 本文件是 `python-unittest-generator` 技能的参考文件。
> 当需要验证测试质量（不仅是覆盖率）时使用。

## 什么是变异测试

变异测试通过**对源码做微小修改**（变异），然后运行测试套件，检查测试是否能检测到这些变异。

- **变异被杀死**（Killed）：测试因变异而失败 → 测试有效
- **变异存活**（Survived）：测试仍然通过 → 测试可能无效
- **变异超时**（Timeout）：测试运行超时 → 可能陷入死循环

**存活率越低，测试质量越高。** 目标：存活率 < 5%。

## 为什么需要变异测试

高覆盖率 ≠ 高质量测试。以下测试覆盖率 100% 但完全无效：

```python
def add(a, b):
    return a + b

# 覆盖率 100%，但永远通过（没有断言）
def test_add():
    add(1, 2)  # 不检查返回值
```

变异测试能发现这类"虚假覆盖率"问题。

## 工具选择

### mutmut（推荐）

Python 生态最成熟的变异测试工具。

```bash
# 安装
pip install mutmut

# 运行变异测试（需要配置好的测试套件）
mutmut run --paths-to-mutate src/

# 查看结果
mutmut results

# 查看存活的变异详情
mutmut show <id>
```

配置 `pyproject.toml`：

```toml
[tool.mutmut]
paths_to_mutate = ["src/"]
runner = "pytest -x --tb=short"
tests_dir = "tests/"
```

### pytest-gremlins（更快）

针对 pytest 生态的变异测试工具，速度是 mutmut 的 13.8 倍。

```bash
pip install pytest-gremlins
pytest --gremlins-mutate=all
```

## 变异类型

mutmut 支持的常见变异操作：

| 原始代码 | 变异后 | 类型 |
|----------|--------|------|
| `a + b` | `a - b` | 算术运算符 |
| `a > b` | `a >= b`, `a < b` | 比较运算符 |
| `a and b` | `a or b` | 逻辑运算符 |
| `True` | `False` | 布尔常量 |
| `None` | `""` | 空值替换 |
| `return x` | `return None` | 返回值清空 |
| `break` | `continue` | 循环控制 |
| `if cond:` | `if True:`, `if False:` | 条件分支 |

## 使用流程

### 1. 前置条件

- 测试覆盖率已达 90%+
- 所有测试通过
- 测试执行时间 < 60 秒（变异测试会多次运行测试）

### 2. 运行变异测试

```bash
# 完整运行
mutmut run

# 仅对特定模块运行（推荐先用小范围验证）
mutmut run --paths-to-mutate src/utils/config.py

# 指定测试运行命令
mutmut run --runner "pytest tests/unit/test_config.py -x"
```

### 3. 分析结果

```bash
# 查看统计
mutmut summary

# 查看存活的变异（需要修复的）
mutmut show-surviving

# 查看特定变异的详情
mutmut show <id>
```

### 4. 修复存活变异

对于每个存活的变异：

1. 查看变异详情：`mutmut show <id>`
2. 理解为什么测试没有捕获它
3. 添加或修改测试来捕获该变异
4. 重新运行验证变异被杀死

### 5. 优化策略

变异测试运行较慢，优化建议：

- **缩小范围**：先对关键模块运行，而非整个项目
- **使用快速 runner**：`--runner "pytest -x --tb=line -q"`
- **过滤无关变异**：在 `.mutmut-cache` 中排除生成的变异
- **CI 集成**：仅在 CI 中运行完整变异测试，本地只跑增量

## 与 unittest 集成

```bash
# unittest 模式的 runner
mutmut run --runner "python -m unittest tests.unit.test_module -v"
```

## 与 pytest 集成

```bash
# pytest 模式（推荐）
mutmut run --runner "pytest tests/unit/test_module.py -x --tb=short -q"
```

## 结果解读

```
$ mutmut results
┌─────────────────┐
│ Mutation testing │
├─────────────────┤
│ ⠋ Running...    │
└─────────────────┘
221 mutations tested
  210 killed (95.0%)
    5 survived (2.3%)
    6 timeouts (2.7%)
```

- **Killed > 95%**：测试质量优秀
- **Killed 80-95%**：测试质量可接受，有改进空间
- **Killed < 80%**：测试质量不足，需要补充测试

## 常见存活变异及修复

### 存活：返回值未被检查

```python
# 变异：return x → return None
def process(data):
    result = transform(data)
    return result

# 修复：添加返回值断言
def test_process_returns_result(self):
    result = process("input")
    self.assertIsNotNone(result)
    self.assertEqual(result, expected)
```

### 存活：异常路径未测试

```python
# 变异：if not data: return None → if True: return None
def process(data):
    if not data:
        return None
    return transform(data)

# 修复：测试空输入
def test_process_empty_input(self):
    result = process("")
    self.assertIsNone(result)
```

### 存活：边界条件未覆盖

```python
# 变异：a > 0 → a >= 0
def validate(count):
    return count > 0

# 修复：测试边界值
def test_validate_zero(self):
    self.assertFalse(validate(0))  # 确保严格大于

def test_validate_one(self):
    self.assertTrue(validate(1))
```
