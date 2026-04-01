---
name: py-doc-generator
description: >
  分析 Python 3 源码并生成完整项目文档，包括 CLAUDE.md（放在源码目录下供 AI 按需加载）、
  架构概览、UML 图表（类图、时序图、组件图）、业务脑图和 API 参考文档。
  文档目录结构遵循 Claude Code 最佳实践：根 CLAUDE.md 作为路由文件指向详细文档，子目录
  CLAUDE.md 在 AI 访问时按需加载。当用户要求为 Python 代码生成文档、分析项目架构、
  绘制 UML/类图、生成 API 文档、创建脑图，或说"帮我理解这个项目"、"生成文档"、
  "画架构图"、"API 参考"、"代码分析报告"时，均应使用此技能。
  同时支持整个项目分析和指定模块/目录分析两种模式。
---

# Python 文档生成器

分析 Python 3 源码，生成遵循 Claude Code 最佳实践的项目文档体系。

核心理念：**把文档放到 AI 自然会读到的地方**，而不是一个独立的文档树。

## 激活条件

当需要为 Python 代码生成文档时激活此技能。支持两种模式：

1. **全项目模式** — 用户指向整个项目或要求生成完整文档
2. **模块模式** — 用户指定某个模块、目录或文件

意图不明确时主动询问。给出项目根目录则默认全项目模式。

## 输出目录结构

文档生成到目标项目的两个位置：

### 1. 源码目录下的 CLAUDE.md（AI 按需加载）

这是最关键的部分 — Claude Code 在访问某个目录时会**自动加载**该目录的 CLAUDE.md，
无需任何额外操作。每个 CLAUDE.md 保持 150 行以内。

```
project/
├── CLAUDE.md                          # 路由文件：项目概述 + 指向各处文档
├── src/
│   ├── CLAUDE.md                      # src 层总览（按需加载）
│   ├── agents/
│   │   ├── CLAUDE.md                  # agents 模块说明（按需加载）
│   │   └── *.py
│   ├── vision/
│   │   ├── CLAUDE.md                  # vision 模块说明（按需加载）
│   │   └── *.py
│   ├── action/
│   │   ├── CLAUDE.md                  # action 模块说明（按需加载）
│   │   └── *.py
│   └── utils/
│       ├── CLAUDE.md                  # utils 模块说明（按需加载）
│       └── *.py
├── tests/
│   └── CLAUDE.md                      # 测试约定（按需加载）
└── .claude/
    └── rules/
        └── coding-standards.md        # 编码规范（path-scoped）
```

### 2. docs/ 目录（可视化图表和详细文档）

docs/ 存放不适合内联的大块内容：架构文档、UML 图表、脑图、API 参考。
根 CLAUDE.md 通过 `@import` 引用这些文件。

```
docs/
├── architecture.md                    # 架构概览 + 组件图
├── uml/
│   ├── class-diagram.md               # UML 类图
│   ├── sequence-diagrams.md           # 时序图
│   └── component-diagram.md           # 组件图
├── mindmap/
│   ├── business-logic.md              # 业务逻辑脑图
│   └── module-structure.md            # 模块结构脑图
└── api/
    └── reference.md                   # 公共 API 参考文档
```

### 为什么这样设计

| 设计决策 | 原因 |
|----------|------|
| CLAUDE.md 放在源码目录下 | Claude Code 访问该目录时**自动加载**，无需 `@import` |
| 子目录 CLAUDE.md 保持 150 行以内 | 超过 200 行 Claude 对指令的遵从度下降 |
| 根 CLAUDE.md 作为路由文件 | 始终加载，应精简，用 `@import` 引用详细文档 |
| docs/ 只放图表和大块文档 | 这些内容太大不适合放在 CLAUDE.md 里，但通过 `@import` 按需加载 |
| 去掉 docs/ 下的 `doc/` 嵌套 | 减少不必要的层级，AI 阅读路径更短 |

## 工作流程

按以下阶段顺序执行。需要模板时读取 `references/` 下的对应参考文件。

### 阶段 1：代码扫描与分析

目标：建立整个代码库结构的认知模型。

**步骤：**

1. **发现项目布局**
   - 使用 `Glob` 查找所有 `*.py` 文件
   - 识别项目根目录标志：`pyproject.toml`、`setup.py`、`setup.cfg`、`requirements.txt`、`Pipfile`
   - 映射目录树 — 标记 `src/`、`tests/`、`scripts/`、`app/` 等

2. **识别入口点和公共 API 接口**
   - 查找 `__main__.py`、`cli.py`、`app.py`、`main.py`、WSGI/ASGI 应用
   - 读取 `__init__.py` 文件以识别 `__all__` 导出
   - 扫描装饰器：`@app.route`、`@router`、`@click.command`、`@dataclass`、`@frozen`、`@api_view`

3. **映射依赖关系**
   - 跨文件读取 import 语句，构建模块依赖图
   - 区分内部导入和外部导入
   - 如有循环依赖则标记

4. **按角色分类模块**
   - 为每个模块归类：`model`、`service`、`controller`、`utility`、`config`、`middleware` 等
   - 识别主导架构模式（MVC、分层、六边形等）

**输出：** 内部认知，暂不写入文件。

> 模块模式下仅扫描指定路径及其依赖。

### 阶段 2：根 CLAUDE.md（路由文件）

目标：生成项目根目录的 `CLAUDE.md`，作为整个文档体系的入口。

这是 Claude Code **始终加载**的文件，必须精简（<150 行）。内容结构：

```markdown
# [项目名称]

一段话描述项目做什么。

## 技术栈

- Python 3.x + [框架]
- [关键依赖]

## 目录结构

| 目录 | 说明 |
|------|------|
| `src/agents/` | AI 决策模块 |
| `src/vision/` | 视觉感知模块 |
| ... | ... |

## 常用命令

- `python src/main.py` — 启动应用
- `pytest tests/ -v` — 运行测试

## 架构设计

[一段话概述架构模式，然后指向详细文档]

详细的架构设计、UML 图表和 API 文档见 @docs/architecture.md

## 编码规范

- 类型标注：所有函数必须有类型标注
- 测试：pytest，fixtures 在 `tests/conftest.py`
- [其他关键规范]
```

读取 `references/claude-md-template.md` 获取各层级的 CLAUDE.md 模板。

### 阶段 3：子目录 CLAUDE.md（按需加载）

目标：为每个源码子目录生成精简的 CLAUDE.md。

Claude Code 只在访问某个目录时才加载该目录的 CLAUDE.md，所以这里可以放模块级的详细信息，
但仍需控制在 150 行以内。

对每个包含 `.py` 文件的目录（以及 `tests/`），生成 `CLAUDE.md`，包含：

1. **模块简介** — 1-2 句话说明该目录做什么
2. **文件说明表** — 列出该目录下每个文件及其核心类/函数
3. **关键约定** — 该模块特有的设计模式或注意事项（如果有）
4. **依赖关系** — 该模块依赖项目内的哪些其他模块

示例 `src/agents/CLAUDE.md`：
```markdown
# agents/ — AI 决策模块

实现 ReAct（推理+行动）模式的 AI 决策引擎，负责分析截图、推理下一步操作、管理动作历史。

## 文件说明

| 文件 | 核心类 | 说明 |
|------|--------|------|
| `decision_agent.py` | `DecisionAgent` | AI 决策核心，调用 GLM 进行多模态推理 |
| `state_memory.py` | `StateMemory`、`ActionRecord` | 动作历史记录与持久化 |
| `test_case_parser.py` | `TestCaseParser` | 自然语言测试用例解析（静态方法类） |

## 依赖

- 依赖 `utils/glm_client.py` 进行 API 调用
- 依赖 `vision/ocr_engine.py` 获取 OCR 上下文
```

**生成顺序：** 从叶子目录开始向上，父目录可以准确引用子目录内容。

### 阶段 4：架构文档 → `docs/architecture.md`

目标：生成一份详细文档，阐述系统设计。通过根 CLAUDE.md 的 `@import` 引用。

写入 `docs/architecture.md`，包含：

1. **项目概述** — 项目做什么、解决什么问题
2. **架构模式** — 识别并描述架构模式（如"本项目采用分层架构..."）
3. **模块总览表** — 列出所有顶层模块的角色和职责
4. **组件图** — Mermaid 组件图展示顶层模块及其关系
5. **数据流** — 数据在系统中的流转过程
6. **关键设计决策** — 有趣的模式、权衡或架构选择

读取 `references/mermaid-templates.md` 获取 Mermaid 语法参考。

### 阶段 5：UML 图表 → `docs/uml/`

目标：生成准确反映代码结构的 UML 图表。

读取 `references/mermaid-templates.md` 获取语法，读取 `references/analysis-checklist.md` 获取提取清单。

#### 5.1 类图 → `docs/uml/class-diagram.md`

- 提取每个类的：类名、父类、属性（含类型）、方法（含签名）、装饰器
- 识别关系：继承、组合、聚合、关联、依赖
- 使用 Mermaid namespace 按模块分组
- 类图超过 40 个类时按模块拆分
- 附带图例说明关系线类型

#### 5.2 时序图 → `docs/uml/sequence-diagrams.md`

识别 3-5 个关键业务流程，对每个：
- 使用描述性中文名称
- 通过代码追踪实际方法调用链
- 包含参与者、服务、数据库、外部系统
- 使用 `alt`/`else` 块表示条件逻辑

#### 5.3 组件图 → `docs/uml/component-diagram.md`

- 顶层包/模块作为组件
- 按层分组（表现层、业务层、数据层、基础设施层）
- 组件间的依赖箭头

### 阶段 6：脑图 → `docs/mindmap/`

#### 6.1 业务逻辑脑图 → `docs/mindmap/business-logic.md`

- 中心节点：项目名称
- 一级分支：主要功能域
- 叶子节点：实现每个功能的核心类/函数

#### 6.2 模块结构脑图 → `docs/mindmap/module-structure.md`

- 中心节点：项目根目录
- 分支：顶层包
- 叶子：各模块及其主要类/函数

### 阶段 7：API 参考文档 → `docs/api/reference.md`

目标：记录所有公共接口。

读取 `references/api-doc-template.md` 获取格式模板。

对每个公共类和函数：

1. **签名** — 完整的类型标注签名
2. **描述** — 来自 docstring 的一句话摘要
3. **参数** — 包含名称、类型、默认值、描述的表格
4. **返回值** — 返回类型和描述
5. **异常** — 可能抛出的异常
6. **示例** — 简短的使用示例

范围：所有不以 `_` 开头的内容。按模块分组，模块内按字母排序。
使用 Markdown 链接做交叉引用。

## 语言规范

- 默认文档语言：**简体中文**
- 代码签名、类名和技术术语保持英文
- 章节标题和描述使用中文
- 用户要求时可切换为英文

## 质量规则

1. **准确优先于完整** — 只记录能从代码中验证的内容。不确定时用 `> [!NOTE] 待确认` 标记。
2. **不虚构关系** — 只在代码中存在 import 或实际使用时才绘制依赖/关联线。
3. **保持图表可读** — 类图超过 40 个类时按模块拆分。
4. **类型标注为准** — 使用代码中的实际类型标注。
5. **docstring 优先** — 如果 docstring 存在则使用其描述。
6. **CLAUDE.md 不超过 150 行** — 超过则将细节移入 docs/ 或 `.claude/rules/`。

## 参考文件

| 文件 | 读取时机 | 内容 |
|------|---------|------|
| `references/mermaid-templates.md` | 阶段 4、5、6 | Mermaid 语法示例 |
| `references/analysis-checklist.md` | 阶段 1 | Python 文件提取检查清单 |
| `references/api-doc-template.md` | 阶段 7 | API 参考条目格式模板 |
| `references/claude-md-template.md` | 阶段 2、3 | 各层级 CLAUDE.md 模板和示例 |
