# YAML最佳实践

这些最佳实践可以让你的YAML配置更易读、易维护，减少错误。

## 1. 缩进和格式

### ✅ 推荐

- 使用 **2个空格** 缩进（Python社区常用）
- 冒号后总是加一个空格
- 同级保持一致的缩进
- 列表项的短横线后总是加空格
- 嵌套层级不要太深（尽量不超过3层）

```yaml
# 好的格式
steps:
  - name: 检出代码
    action: git_checkout
    params:
      branch: main
      url: https://github.com/example/repo
```

### ❌ 不推荐

```yaml
# 冒号后没有空格
steps:
  -name:检出代码  # 短横线后没空格
  action:git_checkout  # 冒号后没空格
    params:
        branch:main  # 缩进4空格，和前面不一致
```

## 2. 字符串使用

### ✅ 推荐

- 普通字符串不需要引号
- 字符串包含特殊字符（冒号空格、#、引号）时才用引号
- 版本号一定要用引号
- Windows路径用单引号避免转义问题

```yaml
name: 我的工作流                  # OK，不需要引号
version: "1.10"                  # 版本号用引号，避免被识别为1.1
path: 'C:\Users\name\file'       # 单引号，不需要转义
message: "这里有个冒号: 这里"     # 包含冒号，用引号
```

### ❌ 不推荐

```yaml
version: 1.10        # 危险！有些解析器会变成 1.1
path: "C:\\Users"   # 需要双转义，麻烦
"name": "value"      # 不需要给键加引号
```

## 3. 多行字符串选择

| 场景 | 推荐符号 | 原因 |
|------|----------|------|
| 脚本/代码块 | `|` | 需要保留换行，方便阅读 |
| 长文本描述 | `>` | 文件中可以换行写，最终合并为一段 |

```yaml
# 推荐：脚本用 |
script: |
  #!/bin/bash
  echo "Starting deployment
  ./deploy.sh
  echo "Deployment completed"

# 推荐：长描述用 >
description: >
  这是一个很长的描述，
  我想在编辑器里分成几行写，
  但是解析的时候会变成一整段，
  不影响最终显示，但是编辑体验更好。
```

## 4. 复用配置

合理使用锚点

### ✅ 推荐

- 多个步骤有相同配置时，使用锚点提取公共部分
- 命名清晰，如`&base_step`、`&deploy_template`

```yaml
# 定义公共模板
base_step: &base_step
  enabled: true
  retry: 2
  timeout: 300

steps:
  - name: 第一步
    <<: *base_step
    action: setup

  - name: 第二步
    <<: *base_step
    action: build
```

### ❌ 不推荐

- 过度使用锚点，简单配置也搞模板
- 多层嵌套锚点引用锚点，太难读

## 5. Flow配置组织建议

### 从上到下顺序：

```yaml
1. name/description  # 流程名称和描述
2. env/globals      # 全局环境变量
3. triggers/on      # 触发条件
4. defaults         # 默认配置
5. matrix           # 矩阵配置
6. steps/stages/jobs # 实际步骤
```

### 示例：

```yaml
name: 每日构建
description: 每天自动运行完整测试和构建

env:
  NODE_ENV: ci
  DEBUG: true

defaults:
  retry: 2
  timeout: 300

on:
  schedule: "0 0 * * *"
  branch: main

steps:
  - name: 检出代码
    ...
```

## 6. 注释技巧

- ✅ 说明**为什么**，不是重复**是什么**
- ✅ 复杂条件或特殊参数加注释
- ❌ 不要注释显而易见的内容

```yaml
# ✅ 好注释
# 因为生产环境部署需要更长超时时间
timeout: 600

# ❌ 没必要的注释
# 这一步检出代码
steps:
  - name: 检出代码

# 其实名字已经说清楚了，不需要重复注释
```

## 7. 错误预防

### 验证YAML语法

你可以用这些工具验证YAML语法：

- 在线验证：https://yamlchecker.com/
- Python：`python -c "import yaml; yaml.safe_load(open('file.yaml'))"`
- VSCode扩展：YAML（RedHat出品，推荐安装）

### 常见错误检查清单：

- [ ] 冒号后是否有空格？
- [ ] 所有列表项`-`后是否有空格？
- [ ] 缩进是否一致（都是空格，没有Tab）？
- [ ] 版本号是否加了引号？
- [ ] 锚点定义使用`&`，引用使用`*`？
- [ ] 合并语法是`<<: *anchor`是否正确？

## 8. 调试技巧

### 查看解析后的JSON，可以帮助调试：

```python
import yaml
import json

with open('your-config.yaml') as f:
    data = yaml.safe_load(f)
print(json.dumps(data, indent=2, ensure_ascii=False))
```

### 常见问题：

**问题1：为什么我的值不对？
- 检查缩进，很可能缩进错了
- 检查冒号后是否有空格

**问题2：锚点没有生效？
- 检查是不是 `<<: *anchor` 语法
- 锚点定义是`&name`，引用是`*name`

**问题3：特殊字符报错？
- 如果包含`:`加空格，一定要用引号包起来
- 如果包含`#`，也要用引号

## 9. 文件大小

- ✅ 单个文件不要超过1000行
- ✅ 太大就拆分多个文件，用`!include`引入（如果支持）
- ✅ Flow配置一般控制在几百行以内更易维护

## 10. 团队协作

- 统一缩进风格（团队都用2空格）
- 保留空行分隔不同逻辑块
- 使用一致的命名风格（kebab-case 或 snake_case）
- 不要在同一行放太多内容，保持清晰优先

```yaml
# 好：分多行更清晰
steps:
  - name: 部署到生产环境
    action: deploy
    environment: production
    retry: 3
    timeout: 600
    when:
      branch: main

# 不挤在一行更清晰
```

---

## 快速检查清单

写完YAML之后，快速过一遍：

- [ ] 📏 缩进都是空格，没有Tab
- [ ]  冒号后都有空格
- [ ] 列表`-`后都有空格
- [ ] 同级缩进一致
- [ ] 版本号用引号了吗？
- [ ] 特殊字符用引号了吗？
- [ ] 注释清晰，没有废话
- [ ] 顺序合理，从上到下是name → env → triggers → steps
- [ ] 公共配置用锚点复用，没有复制粘贴
- [ ] 多级字符串选择了正确的`|`或`>`
