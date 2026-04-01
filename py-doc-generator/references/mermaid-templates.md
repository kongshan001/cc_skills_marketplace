# Mermaid 图表模板

文档生成中使用的 Mermaid 语法快速参考。

## 类图

```mermaid
classDiagram
    class Animal {
        <<abstract>>
        +name: str
        +age: int
        +speak() str
    }

    class Dog {
        +breed: str
        +speak() str
        +fetch(item: str) bool
    }

    class Cat {
        +indoor: bool
        +speak() str
        +purr() None
    }

    class Owner {
        +name: str
        +pets: List~Animal~
        +adopt(animal: Animal) None
    }

    Animal <|-- Dog : 继承
    Animal <|-- Cat : 继承
    Owner "1" --> "0..*" Animal : 拥有
```

### 关系线类型

| 关系 | 语法 | 含义 |
|---|---|---|
| 继承 | `Parent <\|-- Child` | 是一种（is-a） |
| 组合 | `A *-- B` | 拥有，生命周期绑定 |
| 聚合 | `A o-- B` | 拥有，生命周期独立 |
| 关联 | `A --> B` | 使用/知道 |
| 依赖 | `A ..> B` | 依赖于 |
| 实现 | `A ..\|> Interface` | 实现接口 |

### 类型标注

```
class MyAbstract { <<abstract>> }
class MyInterface { <<interface>> }
class MyData { <<dataclass>> }
class MyEnum { <<enumeration>> }
```

### 命名空间（按模块分组）

```mermaid
classDiagram
    namespace models {
        class User { ... }
        class Order { ... }
    }
    namespace services {
        class UserService { ... }
        class OrderService { ... }
    }
    UserService --> User
    OrderService --> Order
```

## 时序图

```mermaid
sequenceDiagram
    actor User
    participant API as API 网关
    participant Auth as 认证服务
    participant DB as 数据库

    User->>API: POST /login
    activate API
    API->>Auth: authenticate(credentials)
    activate Auth
    Auth->>DB: find_user(email)
    DB-->>Auth: user_record
    alt 凭证有效
        Auth-->>API: token_pair
        API-->>User: 200 OK
    else 凭证无效
        Auth-->>API: AuthError
        API-->>User: 401 Unauthorized
    end
    deactivate Auth
    deactivate API
```

### 关键语法

- `->>` 实线箭头（调用），`-->>` 虚线箭头（返回）
- `activate` / `deactivate` 生命线条
- `alt` / `else` / `end` 条件分支
- `loop` / `end` 循环
- `par` / `and` / `end` 并行
- `Note over A,B: 文本` 注释

## 组件图

```mermaid
flowchart TB
    subgraph Presentation["表现层"]
        CLI[命令行工具]
        API[REST API]
    end
    subgraph Business["业务层"]
        AuthSvc[认证服务]
        OrderSvc[订单服务]
    end
    subgraph Data["数据层"]
        DB[(PostgreSQL)]
        Cache[(Redis)]
    end
    CLI --> AuthSvc
    API --> AuthSvc
    API --> OrderSvc
    OrderSvc --> DB
    AuthSvc --> Cache
```

### 节点形状

| 形状 | 语法 | 用途 |
|---|---|---|
| 矩形 | `[A]` | 组件 |
| 圆角 | `(A)` | 开始/结束 |
| 菱形 | `{A}` | 判断 |
| 数据库 | `[(A)]` | 数据库/存储 |

## 脑图

```mermaid
mindmap
  root((项目名称))
    用户管理
      注册/登录
      权限控制
    订单系统
      创建订单
      支付流程
      物流追踪
    数据分析
      报表生成
      Dashboard
```

### 脑图规则

- `root` 使用 `(( ))` 圆形
- 使用 2 空格缩进表示层级
- 标签尽量简短（20 字以内）
- 标签中不使用特殊字符

## 状态图

```mermaid
stateDiagram-v2
    [*] --> Draft: 创建
    Draft --> Submitted: 提交
    Submitted --> Approved: 通过
    Submitted --> Rejected: 拒绝
    Approved --> Completed: 完成
    Completed --> [*]
    Rejected --> [*]
```
