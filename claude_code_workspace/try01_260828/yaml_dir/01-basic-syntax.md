# YAML 基础语法

## 1. 缩进规则

YAML使用**空格**来表示层级结构，**不能使用Tab**。

- 通常使用 **2个空格** 或 **2个空格** 缩进
- 相同层级必须保持相同的缩进
- 冒号(`:`)后面必须有一个空格

✅ 正确示例：
```yaml
parent:
  child1: value1
  child2: value2
```

❌ 错误示例：
```yaml
parent:  # 冒号后没有空格
  child1:value1
parent:
    child1: value1  # 使用了4个空格，和下一行不一致
  child2: value2
```

## 2. 注释

YAML使用`#`表示注释，从`#`到行尾都是注释。

```yaml
# 这是一整行注释
name: Example  # 这是行尾注释

# 多行注释需要每一行都加 #
# 第二行注释
# 第三行注释

key: value  # 注释不能放在值的前面，只能在后面
```

**注意**：YAML不支持多行块注释，每一行都需要加`#`。

## 3. 键值对结构

YAML的核心是键值对（映射）：

```yaml
# 基本格式
key: value

# 嵌套结构
person:
  name: 张三
  age: 25
  address:
    city: 北京
    street: 长安街
```

## 4. 列表（数组）

使用`-`（短横线）开头表示列表项，短横线后面必须有空格。

### 简单列表
```yaml
fruits:
  - 苹果
  - 香蕉
  - 橙子
```

转换为JSON就是：
```json
{
  "fruits": ["苹果", "香蕉", "橙子"]
}
```

### 嵌套列表
```yaml
matrix:
  - [1, 2, 3]
  - [4, 5, 6]
  - [7, 8, 9]
```

或者：
```yaml
matrix:
  -
    - 1
    - 2
    - 3
  -
    - 4
    - 5
    - 6
```

### 对象列表
最常用在Flow的步骤定义：

```yaml
steps:
  - name: 准备环境
    action: setup
    timeout: 300
  - name: 执行构建
    action: build
    timeout: 600
  - name: 运行测试
    action: test
    timeout: 300
```

## 5. 流风格 vs 块风格

### 块风格（推荐，更易读）
```yaml
name: 张三
age: 25
hobbies:
  - 阅读
  - 跑步
```

### 流风格（内联风格，类似JSON）
```yaml
name: 张三
age: 25
hobbies: [阅读, 跑步]
person: {name: 张三, age: 25}
```

混合使用也是可以的：
```yaml
steps:
  - name: build
    options: [clean, test]
  - name: deploy
    options: [production]
```

## 6. 字符串

YAML字符串有多种写法：

### 1. 普通写法（不需要引号）
```yaml
title: 这是一个普通字符串
path: /usr/local/bin
```

### 2. 双引号（支持转义字符）
```yaml
message: "Hello\nWorld"  # 会解析换行
path: "C:\\Users\\name"  # Windows路径需要转义
```

### 3. 单引号（不支持转义，原义输出）
```yaml
message: 'Hello\nWorld'  # 会原样输出 Hello\nWorld
path: 'C:\Users\name'    # 不需要转义
```

### 4. 多行字符串

使用`|`（竖线）保留换行，使用`>`折叠换行：

**`|` 保留换行** - 适合代码、多行日志：
```yaml
description: |
  这是第一行
  这是第二行
  这是第三行

# 结果：
# "这是第一行\n这是第二行\n这是第三行\n"
```

**`>` 折叠换行** - 适合长文本段落，会把换行转成空格：
```yaml
description: >
  这是一个很长的段落，
  我想分成几行来写，
  但是最终会合并成一段。

# 结果：
# "这是一个很长的段落， 我想分成几行来写， 但是最终会合并成一段。 "
```

**带缩进指示符**：
```yaml
# |2 表示缩进2个空格
content: |2
    def hello():
        print("Hello World")
```

## 7. 文档分隔符

多个文档可以放在一个文件中，用`---`分隔：

```yaml
---
# 第一个文档
name: Document 1
value: 123
---
# 第二个文档
name: Document 2
value: 456
...
```

`...`表示文档结束，通常可选。

## 8. 基本语法检查清单

在编写YAML后，检查一下：

- [ ] 所有冒号后面都有空格
- [ ] 使用空格缩进，没有使用Tab
- [ ] 相同层级缩进一致
- [ ] 列表项的`-`后面有空格
- [ ] 字符串中如果有特殊字符，正确使用了引号
