# 使用YAML控制Flow执行顺序

YAML最常见的用途之一就是定义和控制工作流（Flow）的执行顺序。本文通过实际示例展示如何配置不同的执行模式。

## 1. 基础：顺序执行

最简单也最常见：一步一步按顺序执行。

```yaml
# flow-config.yaml
name: 简单CI流程
description: 顺序执行检出 -> 安装 -> 构建 -> 测试

# 全局环境变量
env:
  NODE_VERSION: 18
  CI: true

# 步骤列表 - 按顺序执行
steps:
  - name: 检出代码
    action: git-checkout
    params:
      url: ${{GIT_URL}}
      branch: main

  - name: 安装依赖
    action: npm-install
    params:
      production: false
      cache: true

  - name: 代码检查
    action: eslint
    params:
      src_dir: src/

  - name: 构建项目
    action: npm-build
    params:
      output_dir: dist/

  - name: 运行测试
    action: npm-test
    params:
      coverage: true
```

**执行顺序：** `检出代码 → 安装依赖 → 代码检查 → 构建项目 → 运行测试`

如果任何一步失败，后续步骤默认不执行。

## 2. 并行执行

多个独立步骤可以同时运行，节省时间。

```yaml
name: 并行检查
description: 同时运行多个代码检查

steps:
  - name: 检出代码
    action: git-checkout
  - name: 安装依赖
    action: npm-install

# 并行执行块
parallel:
  - name: ESLint检查
    action: eslint
  - name: 类型检查
    action: typescript-type-check
  - name: 依赖审计
    action: npm-audit

  # 并行中的步骤同时开始执行

# 所有并行步骤都成功后，才会继续下一步
post:
  - name: 构建
    action: build
```

**执行顺序：** `检出 → 安装 → [ESLint, 类型检查, 依赖审计 同时运行] → 构建`

## 3. 条件执行

根据条件决定是否执行某一步。

```yaml
steps:
  - name: 检出代码
    action: git-checkout

  - name: 安装依赖
    action: npm-install

  - name: 运行lint
    action: eslint
    # 只有修改了src目录下的文件才执行
    when:
      changed: "src/**/*.js"

  - name: 运行测试
    action: test
    # 只有在main分支才运行完整测试
    when:
      branch: main

  - name: 部署到生产
    action: deploy
    # 多个条件同时满足才执行
    when:
      branch: main
      tag: "v*"
      status: success # 前面步骤都成功
```

## 4. 依赖控制执行顺序

通过`depends_on`显式声明依赖，可以灵活控制执行顺序，不一定要按文件顺序。

```yaml
steps:
  - name: A
    action: action-a

  - name: B
    action: action-b
    depends_on: [A]  # B依赖A，A完成才跑B

  - name: C
    action: action-c
    depends_on: [A]  # C也依赖A，可以和B并行

  - name: D
    action: action-d
    depends_on: [B, C]  # D等B和C都完成才跑
```

**执行图：**
```
    A
   / \
  B   C
   \ /
    D
```

DAG（有向无环图）执行，非常灵活。

## 5. Matrix多版本测试

在不同环境/版本上运行同一个任务。

```yaml
name: 多版本测试矩阵

env:
  TEST_DATABASE: postgres

matrix:
  node_version: [16, 18, 20]
  os: [ubuntu-latest, macos-latest]

steps:
  - name: 测试
    action: run-tests
    params:
      node_version: ${{matrix.node_version}}
      os: ${{matrix.os}}
```

这会展开为 `3 × 2 = 6` 个独立任务并行执行。

## 6. 分层的Flow配置

更复杂的组织方式，可以定义stage，每个stage包含多个步骤。

```yaml
name: 完整发布流程

# 定义阶段，按顺序执行
stages:
  - name: 准备
    steps:
      - checkout
      - install

  - name: 检查
    parallel:
      - lint
      - type-check
      - test

  - name: 构建
    steps:
      - build
      - package

  - name: 部署
    parallel:
      - deploy-staging
      - run-e2e

  - name: 通知
    steps:
      - notify-team
```

**执行顺序：** `准备 → [检查并行] → 构建 → [部署+测试并行] → 通知`

## 7. 使用锚点减少重复配置

前面学到的锚点技巧在这里非常实用：

```yaml
# 定义模板
base_step: &base_step
  enabled: true
  retry: 2
  timeout: 300
  notify_on_failure: true

deploy_step: &deploy_step
  <<: *base_step
  provider: kubernetes
  namespace: default

# 使用模板
steps:
  - name: 检出代码
    <<: *base_step
    action: git-checkout
    timeout: 120

  - name: 构建镜像
    <<: *base_step
    action: docker-build

  - name: 部署到测试环境
    <<: *deploy_step
    cluster: staging

  - name: 部署到生产环境
    <<: *deploy_step
    cluster: production
    when:
      branch: main
```

## 8. 完整实际例子：GitHub Actions风格

```yaml
name: Node.js CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [16.x, 18.x, 20.x]

    steps:
    - name: 检出代码
      uses: actions/checkout@v4

    - name: 设置Node
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'

    - name: 安装依赖
      run: npm ci

    - name: 构建
      run: npm run build --if-present

    - name: 测试
      run: npm test
```

## 9. 完整实际例子：GitLab CI风格

```yaml
image: node:18

cache:
  paths:
    - node_modules/

stages:
  - lint
  - test
  - build
  - deploy

lint:
  stage: lint
  script:
    - npm run lint

test:
  stage: test
  script:
    - npm test

build:
  stage: build
  script:
    - npm run build
  artifacts:
    paths:
      - dist/

deploy_production:
  stage: deploy
  script:
    - deploy-to-production
  only:
    - main
```

## 10. 总结：不同执行模式对比

| 模式 | 使用场景 | 配置方式 |
|------|----------|----------|
| 顺序执行 | 步骤有依赖，必须按顺序 | 按顺序写steps列表 |
| 并行执行 | 多个步骤独立，可以同时跑 | 使用parallel块 |
| DAG依赖 | 复杂执行图，灵活控制 | 使用depends_on |
| 阶段分组 | 大型工作流分阶段 | 定义stages |
| Matrix矩阵 | 多环境多版本测试 | 使用matrix展开 |

## 选择建议

- **简单流程**：直接顺序执行，最简单最易理解
- **快速CI**：可并行的步骤（如不同检查）放并行，节省时间
- **复杂依赖**：用depends_on定义DAG，清晰灵活
- **多人大型项目**：分stages阶段，便于理解和维护
