# CLAUDE.md 模板

按照 Claude Code 最佳实践生成各层级的 CLAUDE.md 文件。

## 设计原则

- **CLAUDE.md 是路由文件**，不是知识仓库
- **始终加载**：根目录和 `.claude/` 下的 CLAUDE.md
- **按需加载**：子目录的 CLAUDE.md，只在 Claude 访问该目录时加载
- 每个文件控制在 **150 行以内**

## 层级 1：项目根 CLAUDE.md（始终加载）

```markdown
# [项目名称]

一段话描述项目做什么、解决什么问题。

## 技术栈

- Python 3.x + [框架名]
- [关键依赖 1]
- [关键依赖 2]

## 目录结构

| 目录 | 说明 |
|------|------|
| `src/module_a/` | [模块 A 做什么] |
| `src/module_b/` | [模块 B 做什么] |
| `tests/` | 测试套件 |

## 常用命令

- `python src/main.py` — 启动应用
- `pytest tests/ -v` — 运行测试
- `pip install -e .` — 开发安装

## 架构设计

[一段话概述核心架构模式，例如：本项目采用分层架构，分为感知层、决策层、执行层。]

详细文档：
- 架构设计与组件图 @docs/architecture.md
- UML 类图 @docs/uml/class-diagram.md
- API 参考文档 @docs/api/reference.md

## 编码规范

- 类型标注：所有函数必须有类型标注
- 测试：使用 pytest
- [其他 2-3 条关键规范]
```

## 层级 2：源码子目录 CLAUDE.md（按需加载）

对每个包含 Python 文件的子目录生成。Claude 只在访问该目录时才加载这些文件。

### 包目录模板（如 `src/agents/`）

```markdown
# [目录名]/ — [一句话说明]

[1-2 句话描述该目录的职责和在系统中的定位。]

## 文件说明

| 文件 | 核心类/函数 | 说明 |
|------|------------|------|
| `module_a.py` | `ClassName` | [这个类做什么] |
| `module_b.py` | `func_name()` | [这个函数做什么] |

## 关键约定

- [该模块特有的设计模式或约定，1-3 条]
- [例如：所有服务类通过构造函数注入依赖]

## 依赖

- 依赖 `src/utils/config.py` 获取配置
- 被 `src/main.py` 直接引用
```

### tests 目录模板

```markdown
# tests/ — 测试套件

使用 pytest 进行单元测试。mock 通过 pytest-mock 插件提供。

## 运行方式

- `pytest tests/ -v` — 运行所有测试
- `pytest tests/test_xxx.py -v` — 运行单个测试文件
- `pytest --cov=src tests/` — 带覆盖率

## 约定

- 测试文件命名：`test_<模块名>.py`
- Fixtures 放在 `conftest.py` 中
- 使用 `mocker` fixture 进行 mock

## 覆盖范围

| 测试文件 | 覆盖模块 |
|---------|---------|
| `test_config.py` | `src/utils/config.py` |
| `test_xxx.py` | `src/xxx.py` |
```

## 层级 3：`docs/` 目录（通过 @import 按需加载）

docs/ 目录下的文件不自动加载，通过根 CLAUDE.md 的 `@docs/xxx.md` 引用。
当 Claude 需要了解架构细节时才会读取。

```
docs/
├── architecture.md        # 架构概览 + 组件图 + 数据流 + 设计决策
├── uml/
│   ├── class-diagram.md   # UML 类图
│   ├── sequence-diagrams.md  # 时序图
│   └── component-diagram.md  # 组件图
├── mindmap/
│   ├── business-logic.md  # 业务逻辑脑图
│   └── module-structure.md   # 模块结构脑图
└── api/
    └── reference.md       # 完整 API 参考
```

docs/ 下**不放** CLAUDE.md 和 `doc/` 子目录 — 这些文件通过 `@import` 按需加载，
不需要额外的目录级元数据。

## 生成顺序

1. **叶子目录** → 生成各 `src/subdir/CLAUDE.md`
2. **src/ 级** → 生成 `src/CLAUDE.md`（可引用子目录内容）
3. **docs/ 文件** → 生成架构文档、UML 图表、脑图、API 参考
4. **根目录最后** → 生成根 `CLAUDE.md`（用 `@import` 引用 docs/ 文件）

这样确保每一层级都能准确引用下一层的内容。
