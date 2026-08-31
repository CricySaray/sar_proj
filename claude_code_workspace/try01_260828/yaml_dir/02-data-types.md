# YAML 数据类型

YAML支持丰富的数据类型，可以满足Flow配置的各种需求。

## 1. 标量类型（Scalar）

### 字符串（String）

```yaml
# 不需要引号
name: 张三
greeting: Hello World

# 需要引号的情况：
# 1. 字符串以特殊字符开头
special: "!hello"

# 2. 字符串包含冒号加空格
message: "warning: this is a message"

# 3. 字符串就是一个布尔值或数字，但你想当字符串用
enabled: "true"     # 字符串 "true"，不是布尔值
port: "8080"       # 字符串 "8080"，不是数字
```

### 数字（Number）

```yaml
# 整数
integer: 42
negative: -17
zero: 0

# 浮点数
float: 3.14159
pi: 3.14
negative_float: -0.5

# 科学计数法
scientific: 1.2e3
```

### 布尔值（Boolean）

```yaml
# 真值
enabled: true
is_active: True    # 不区分大小写，但推荐小写
on: true
yes: true

# 假值
disabled: false
is_empty: False
off: false
no: false
```

### 空值（Null）

```yaml
# 多种写法
value: null
value: ~          # ~ 等价于 null
value:            # 留空也是 null
```

## 2. 集合类型

### 映射（Mapping / 字典）

键值对的集合，键必须唯一。

```yaml
# 简单映射
person:
  name: 张三
  age: 25
  is_student: false

# 键可以包含空格，也可以使用问号
"full name": 张三
```

映射转换为Python就是`dict`：
```python
{'person': {'name': '张三', 'age': 25, 'is_student': False}}
```

### 序列（Sequence / 列表）

有序的元素列表，就是数组。

```yaml
# 简单列表
numbers:
  - 1
  - 2
  - 3
  - 4

# 混合类型列表
mixed:
  - 100
  - "hello"
  - true
  - null
  - key: value
```

序列转换为Python就是`list`。

## 3. 常用特殊类型

### 时间日期

YAML可以自动识别ISO格式的日期时间：

```yaml
date: 2024-01-15
datetime: 2024-01-15T10:30:00Z
timestamp: 1705269000
```

**注意**：解析器是否自动转换为时间对象取决于具体实现，大部分配置解析器会当作字符串处理。

### 多文档

一个YAML文件可以包含多个独立的文档：

```yaml
---
name: 第一个文档
value: 123
---
name: 第二个文档
value: 456
...
```

这在配置多个独立任务时很有用。

## 4. 在Flow配置中常用的数据结构

### （1）简单配置

```yaml
# 全局配置
flow_name: "每日构建"
parallel: false
max_retries: 3
timeout: 3600
notify_on_failure: true
```

### （2）步骤定义

```yaml
# 顺序执行的步骤列表
steps:
  - name: 检出代码
    action: git_checkout
    params:
      url: https://github.com/example/repo.git
      branch: main
    retry: 2

  - name: 安装依赖
    action: install_deps
    params:
      package_manager: npm
    when: changes: package.json

  - name: 运行测试
    action: run_tests
    params:
      coverage: true
    depends_on: [检出代码, 安装依赖]
```

### （3）环境变量配置

```yaml
env:
  NODE_ENV: production
  API_URL: https://api.example.com
  DEBUG: false
```

### （4）参数化配置

```yaml
defaults:
  timeout: 300
  retry: 1

production:
  steps:
    - name: deploy
      target: production
      timeout: 600

staging:
  steps:
    - name: deploy
      target: staging
      timeout: 300
```

## 5. 类型转换规则

YAML会自动识别类型，记住这些规则：

| 输入 | 识别为 |
|------|--------|
| `true` / `false` | 布尔值 |
| `null` / `~` | 空值 |
| `42` / `-17` | 整数 |
| `3.14` / `-0.5` | 浮点数 |
| `2024-01-15` | 日期（某些解析器） |
| `hello world` | 字符串 |
| `"123"` | 字符串（不会转成数字） |
| `'true'` | 字符串（不会转成布尔值） |

如果你想强制某个值是字符串，就用引号包裹它。

## 6. 类型常见陷阱

### 陷阱1：版本号被误识别为浮点数

```yaml
# ❌ 这样写，有些解析器会把 1.10 变成 1.1
version: 1.10

# ✅ 正确写法，用引号
version: "1.10"
```

### 陷阱2：键名包含特殊字符

```yaml
# ❌ 错误，冒号后面会被误解析
key-name-with-dash: value
# 实际上 dash 被当作了下一个键

# ✅ 正确写法，横杠开头本身没问题，只要冒号位置正确
key-name-with-dash: value  # 这样是对的

# 如果键包含冒号，需要引号
"env:production": true
```

### 陷阱3：空列表 vs 空值

```yaml
empty_list: []     # 空列表
empty_value: null  # 空值
empty_string: ""   # 空字符串
empty_undefined:   # null
```
