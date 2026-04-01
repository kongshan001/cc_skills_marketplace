# API 参考文档模板

用于生成 `docs/api/reference.md` 的条目模板。

## 文件结构

```markdown
# API 参考文档

> 从源码自动生成。最后更新：YYYY-MM-DD

## 目录

- [module.path](#modulepath)
  - [ClassName](#classname)
    - [method_name](#classmethod_name)
  - [function_name](#function_name)

---

## module.path

> 模块简要描述

### ClassName

\`\`\`python
class ClassName(BaseClass):
    """来自 docstring 的一句话描述。"""
\`\`\`

#### ClassName.__init__

\`\`\`python
def __init__(self, param1: str, param2: int = 0) -> None
\`\`\`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `param1` | `str` | 必填 | param1 的说明 |
| `param2` | `int` | `0` | param2 的说明 |

#### method_name

\`\`\`python
def method_name(self, input: DataType) -> ResultType
\`\`\`

一句话描述方法的功能。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `input` | `DataType` | 必填 | 说明 |

**返回值：** `ResultType` — 返回值描述

**异常：**
- `ValueError` — 输入无效时抛出
- `RuntimeError` — 处理失败时抛出

**示例：**

\`\`\`python
obj = ClassName(param1="hello")
result = obj.method_name(input=data)
\`\`\`

---

### function_name

\`\`\`python
def function_name(x: int, y: int = 10) -> int
\`\`\`

一句话描述。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `x` | `int` | 必填 | 说明 |
| `y` | `int` | `10` | 说明 |

**返回值：** `int` — 说明
\`\`\`
```

## 格式规则

1. **签名** — 始终显示完整的类型标注签名，80 字符以内保持一行，超出则在逗号处换行
2. **参数表** — 始终包含四列（参数、类型、默认值、说明）；无默认值时填"必填"
3. **类型** — 所有类型引用使用行内代码格式
4. **描述** — 一句话，使用动作导向（"处理..."而非"这个函数用于处理..."）
5. **交叉引用** — 使用 Markdown 链接引用相关类型：[`OtherClass`](#otherclass)
6. **章节标题** — `###` 用于模块，`####` 用于类，`#####` 用于方法
7. **跳过琐碎方法** — 不记录 `__repr__`、`__str__`、`__eq__` 等，除非有值得记录的自定义逻辑

## 需要包含的内容

- 所有不以 `_` 开头的类
- 所有不以 `_` 开头的方法（`__init__` 始终包含）
- 所有不以 `_` 开头的独立函数
- 所有 dataclass 字段（作为参数记录）
- 所有枚举成员及其值
- 类型别名及其定义

## 需要跳过的内容

- 私有方法（`_method_name`）
- 除 `__init__` 外的魔术方法
- 仅包含 import 的模块（无定义）
- 测试 fixtures 和 conftest
