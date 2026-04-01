# 真实依赖测试参考

> 本文件是 `python-unittest-generator` 技能的参考文件。
> 当需要测试与真实外部服务（数据库、Redis、HTTP API）交互时使用。

## 核心理念

本技能的"真实优先"原则在 Mock 策略中已体现。对于外部服务依赖，
本文件提供比 mock 更可靠的替代方案：**使用真实的服务实例**。

优先级：真实服务 > 本地替代 > mock

## 方案一：testcontainers-python

使用 Docker 容器运行真实服务，测试后自动销毁。

```bash
pip install testcontainers
```

### 数据库测试

```python
import unittest
from testcontainers.postgres import PostgresContainer


class TestWithRealDatabase(unittest.TestCase):
    """使用真实 PostgreSQL 容器进行测试。"""

    @classmethod
    def setUpClass(cls):
        cls.postgres = PostgresContainer("postgres:16-alpine")
        cls.postgres.start()
        cls.db_url = cls.postgres.get_connection_url()

    @classmethod
    def tearDownClass(cls):
        cls.postgres.stop()

    def test_insert_and_query(self):
        """真实的数据库读写测试。"""
        import psycopg2
        conn = psycopg2.connect(self.db_url)
        # 执行真实的 SQL 操作...
        conn.close()
```

### Redis 测试

```python
from testcontainers.redis import RedisContainer


class TestWithRealRedis(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.redis_container = RedisContainer("redis:7-alpine")
        cls.redis_container.start()
        cls.redis_url = f"redis://{cls.redis_container.get_container_host_ip()}:{cls.redis_container.get_exposed_port(6379)}"

    @classmethod
    def tearDownClass(cls):
        cls.redis_container.stop()

    def test_cache_roundtrip(self):
        """真实的 Redis 缓存测试。"""
        import redis
        r = redis.from_url(self.redis_url)
        r.set("test_key", "test_value")
        self.assertEqual(r.get("test_key"), b"test_value")
```

### pytest fixture 模式

```python
import pytest
from testcontainers.postgres import PostgresContainer


@pytest.fixture(scope="session")
def postgres_url():
    with PostgresContainer("postgres:16-alpine") as postgres:
        yield postgres.get_connection_url()


def test_database_query(postgres_url):
    """使用 pytest fixture 的真实数据库测试。"""
    # 测试逻辑...
    pass
```

## 方案二：本地 HTTP 服务

用 Python 标准库搭建本地 HTTP 服务，替代真实 API。

```python
import unittest
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
import requests
import json


class MockAPIHandler(BaseHTTPRequestHandler):
    """本地模拟 API 服务器。"""

    def do_POST(self):
        if self.path == "/api/chat":
            content_length = int(self.headers['Content-Length'])
            body = json.loads(self.rfile.read(content_length))
            response = {"choices": [{"message": {"content": "test response"}}]}
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())

    def log_message(self, format, *args):
        pass  # 静默日志


class TestWithLocalAPI(unittest.TestCase):
    """使用本地 HTTP 服务测试 API 客户端。"""

    @classmethod
    def setUpClass(cls):
        cls.server = HTTPServer(('localhost', 0), MockAPIHandler)
        cls.port = cls.server.server_address[1]
        cls.thread = threading.Thread(target=cls.server.serve_forever)
        cls.thread.daemon = True
        cls.thread.start()
        cls.base_url = f"http://localhost:{cls.port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()

    def test_chat_with_real_http(self):
        """通过真实 HTTP 请求测试客户端。"""
        client = GLMClient(api_key="test", base_url=self.base_url)
        result = client.chat([{"role": "user", "content": "hi"}])
        self.assertEqual(result, "test response")
```

## 方案三：内存 SQLite

用 SQLite 内存数据库替代远程数据库，无需 Docker。

```python
import unittest
import sqlite3


class TestWithInMemoryDB(unittest.TestCase):
    """使用内存 SQLite 替代远程数据库。"""

    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.execute("""
            CREATE TABLE users (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL
            )
        """)

    def tearDown(self):
        self.conn.close()

    def test_insert_user(self):
        """真实的 SQL 操作测试。"""
        self.conn.execute("INSERT INTO users (name, email) VALUES (?, ?)",
                         ("测试用户", "test@example.com"))
        cursor = self.conn.execute("SELECT * FROM users WHERE name = ?", ("测试用户",))
        row = cursor.fetchone()
        self.assertIsNotNone(row)
        self.assertEqual(row[1], "测试用户")

    def test_unique_constraint(self):
        """测试唯一约束。"""
        self.conn.execute("INSERT INTO users (name, email) VALUES (?, ?)",
                         ("用户A", "same@example.com"))
        with self.assertRaises(sqlite3.IntegrityError):
            self.conn.execute("INSERT INTO users (name, email) VALUES (?, ?)",
                             ("用户B", "same@example.com"))
```

## 方案选择指南

| 场景 | 推荐方案 | 原因 |
|------|----------|------|
| PostgreSQL/MySQL 特有 SQL | testcontainers | 验证方言差异 |
| 简单 CRUD | 内存 SQLite | 零依赖，快速 |
| Redis 缓存 | testcontainers | 验证 TTL、数据类型 |
| HTTP API 客户端 | 本地 HTTP 服务 | 验证序列化/反序列化 |
| 第三方 SDK（无本地替代） | mock | 无其他选择 |
| 消息队列（RabbitMQ/Kafka） | testcontainers | 验证消息传递 |

## 注意事项

1. **Docker 依赖**：testcontainers 需要 Docker 运行。CI 中需确保 Docker 可用。
2. **测试速度**：真实服务测试比 mock 慢，放在 `integration/` 目录中。
3. **资源清理**：确保 `tearDown`/`tearDownClass` 正确清理资源。
4. **端口冲突**：使用端口 0 让系统自动分配可用端口。
5. **超时设置**：容器启动可能需要时间，设置合理的等待超时。
