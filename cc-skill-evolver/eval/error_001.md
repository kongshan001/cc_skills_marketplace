# 错误案例示例

> 这是一个示例错误案例，展示 eval/ 目录下的文件格式。
> 实际使用时，应该针对目标 skill 编写具体的错误案例。

## 场景描述

用户在一个 Python 项目中请求："帮我分析这个项目的架构，生成文档"。

项目结构如下：
```
my_project/
├── src/
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes.py       # Flask 路由定义
│   │   └── auth.py         # JWT 认证逻辑
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py         # User ORM 模型
│   │   └── order.py        # Order ORM 模型
│   ├── services/
│   │   ├── __init__.py
│   │   ├── user_service.py # 用户业务逻辑
│   │   └── order_service.py # 订单业务逻辑
│   └── utils/
│       ├── logger.py
│       └── config.py
├── tests/
└── requirements.txt
```

## 实际行为

Skill 被触发后只生成了一个简单的 `docs/README.md`，内容为：

```markdown
# 项目文档

## 概述
这是一个 Python 项目，使用 Flask 框架。

## 安装
pip install -r requirements.txt
```

缺失内容：
- 没有架构分析（模块间依赖关系、数据流）
- 没有 UML 图表（类图、序列图、组件图）
- 没有 API 参考文档
- 没有在源码目录放置 CLAUDE.md 路由文件
- 没有分析 `routes.py → services → models` 的调用链

## 期望行为

Skill 应该：
1. 先完整扫描项目结构，递归遍历所有 .py 文件
2. 分析模块间的 import 关系，建立调用链图（routes → services → models）
3. 生成完整文档套件：
   - 根目录 `CLAUDE.md`：项目路由文件（<150 行）
   - `docs/architecture.md`：架构文档（系统设计、数据流、模块职责）
   - `docs/uml/`：类图、序列图、组件图（Mermaid 格式）
   - `docs/api/reference.md`：API 参考文档
   - 各子目录 `CLAUDE.md`：该目录的模块说明（<150 行）
4. 文档内容应该反映实际的模块结构和调用关系
