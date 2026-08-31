# YAML 高级特性

这些高级特性在复杂的Flow配置中非常有用，可以帮你避免重复，让配置更整洁。

## 1. 锚点与引用（Anchor & Alias）

锚点（`&`）定义一个模板，引用（`*`）可以复用它。这是YAML最有用的高级特性之一。

### 基本用法

```yaml
# 定义锚点
default_step: &default_step
  retry: 2
  timeout: 300
  enabled: true

steps:
  - name: 步骤1
    <<: *default_step  # 引入所有默认值
    action: setup

  - name: 步骤2
    <<: *default_step  # 引入所有默认值
    action: build
    timeout: 600       # 覆盖默认的timeout

  - name: 步骤3
    <<: *default_step
    action: test
    retry: 5           # 覆盖默认的retry
```

这个配置等价于：

```yaml
steps:
  - name: 步骤1
    retry: 2
    timeout: 300
    enabled: true
    action: setup

  - name: 步骤2
    retry: 2
    timeout: 600
    enabled: true
    action: build

  - name: 步骤3
    retry: 5
    timeout: 300
    enabled: true
    action: test
```

### `<<` 合并键

`<<` 表示将锚点的所有键合并到当前映射中。如果当前映射已经有同名键，当前键的值会覆盖锚点的值。

### 多个锚点合并

```yaml
defaults: &defaults
  retry: 2
  timeout: 300

logging: &logging
  log_level: info
  output: console

steps:
  - name: 构建
    <<: [*defaults, *logging]  # 合并多个锚点
    action: build
    log_level: debug  # 覆盖
```

### 复用列表

```yaml
common_deps: &common_deps
  - checkout
  - install_deps

test_steps:
  - <<: *common_deps
  - run_tests

deploy_steps:
  - <<: *common_deps
  - build
  - deploy
```

## 2. 标签（Tags）

标签用来显式指定数据类型。

### 常用标签

```yaml
# 强制转为字符串
!!str 12345       # 字符串 "12345"

# 强制转为整数
!!int "123"      # 整数 123

# 强制转为浮点数
!!float "3.14"   # 浮点数 3.14

# 二进制数据（Base64编码）
!!binary |
  R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7
```

### 自定义标签

有些Flow框架支持自定义标签：

```yaml
!include common.yaml  # 包含另一个文件
!env GITHUB_TOKEN     # 从环境变量读取
```

具体是否支持取决于你使用的解析器。

## 3. 多行字符串高级用法

### `|` vs `>` 区别

| 符号 | 作用 | 使用场景 |
|------|------|----------|
| `|` | 保留换行符 | 代码块、多行日志、脚本 |
| `>` | 折叠换行（所有换行转空格） | 长文本段落 |

### 保留/移除末尾换行

```yaml
# |+ 保留末尾的空行
content: |+
  line 1
  line 2
  # 这里是空行

# |- 移除末尾的空行
content: |-
  line 1
  line 2
  # 末尾空行被移除
```

### 缩进处理

```yaml
# 内容本身有缩进，指定保留多少空格
content: |2
    def hello():
        print("world")
# 结果：保留两个缩进空格
# "def hello():\n    print(\"world\")\n"
```

## 4. 复杂键名

YAML允许复杂的键名：

```yaml
# 问号表示复杂键
? "key with spaces"
: value

# 对象作为键（很少用）
? [1, 2]
: 这是一个元组键
```

实际配置中很少用到，知道就行。

## 5. 指令

文件开头可以放YAML指令：

```yaml
%YAML 1.2
---
name: example
```

通常不需要写，解析器默认使用最新版本。

## 6. 在Flow配置中使用高级特性的实际例子

### 示例1：步骤模板化

```yaml
# 定义共享配置模板
step_template: &step_template
  enabled: true
  retry: 2
  notify_on_failure: true

# 不同环境配置
env_common: &env_common
  cache_enabled: true
  timeout: 600

production:
  <<: *env_common
  environment: production
  notify_on_success: true
  slack_channel: "#deploy-alerts"

staging:
  <<: *env_common
  environment: staging
  notify_on_success: false

# 使用模板的步骤
steps:
  - name: checkout
    <<: *step_template
    action: git_checkout
    timeout: 120

  - name: install_deps
    <<: *step_template
    action: npm_install
    cache: true

  - name: build
    <<: *step_template
    action: npm_build
    timeout: 600

  - name: test
    <<: *step_template
    action: npm_test
    retry: 3  # 覆盖默认重试次数
```

### 示例2：条件执行配置

```yaml
# 不同分支的触发条件
trigger_rules: &trigger_rules
  branches:
    include:
      - main
      - develop
    exclude:
      - "*.md"

workflow:
  name: CI Pipeline
  triggers:
    <<: *trigger_rules
  steps:
    - lint
    - test
    - build
```

## 7. 高级特性总结表

| 特性 | 符号 | 用途 |
|------|------|------|
| 锚点 | `&name` | 定义可复用的配置块 |
| 引用 | `*name` | 引用锚点定义的配置块 |
| 合并 | `<<` | 将锚点的键合并到当前映射 |
| 保留换行 | `|` | 多行字符串保留换行 |
| 折叠换行 | `>` | 多行字符串折叠成一行 |
| 强制类型 | `!!type` | 显式指定数据类型 |

## 8. 什么时候使用高级特性

✅ **推荐使用锚点合并当：**
- 多个步骤有很多相同的配置项
- 不同环境有共享配置
- 避免复制粘贴相同内容

❌ **不推荐过度使用当：**
- 只有一两个步骤用模板
- 配置已经很清晰，不需要抽象
- 团队不熟悉这些语法，会增加理解成本
