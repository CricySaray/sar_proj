# makerun.csh 实现 Summary

> 依据：`summary_for_makerun.csh.sum`
> 生成日期：2026-08-28

## 一、已实现功能

| 需求编号 | 功能 | 实现情况 |
|---|---|---|
| REQ-CON-001 | `start_step` 不允许缺少 `-f` 时出现，否则报错退出 | ✅ 已实现，且校验在创建任何文件之前 |
| REQ-CON-004 | `start_step` 必须严格属于 `{preplace, place, ccopt, route}`，否则报错退出 | ✅ 已实现（switch 校验，`bogus` 等非法值报错） |
| REQ-001 | 根据当前工作路径自动检测 block | ⚠️ 按使用者确认改为**脚本内占位变量**（`set block`），留空报错；原自动检测方案以注释形式保留 |
| REQ-002 | 创建标准目录结构 PR/PV/STA/FM/PI/signoff_check | ✅ 已实现，`mkdir -p` 幂等；额外创建 `PR/DB`（供模式 3 链接用） |
| REQ-003 | 复制/链接标准流程脚本与配置模板 | ⚠️ 来源为占位变量 `TEMPLATE_DIR`，未填则跳过并 WARNING；采用复制方式（注释说明可改链接） |
| REQ-004 | 注入 foundry / project / user libpath 设置 | ⚠️ 按使用者确认改为**环境变量**（`setenv FOUNDRY/PROJECT/USER_LIBPATH`），值为占位 |
| REQ-005 | 模式 1：创建全新空 run，目录名 `<block>_<MMDD>_<HHMM>_<suffix>` | ✅ 已实现；不建 DB 链接、不 touch marker、不从源复制 |
| REQ-006 | 模式 2：从源 run 复制 settings.tcl / User_lib_list.tcl / user_plug / SCB configs / STA configs 并改写全部路径 | ✅ 已实现；PR/DB 保持为空，不 touch marker |
| REQ-007 | 模式 3：复制配置 + 建 DB 符号链接 + touch 前置 marker | ✅ 已实现 |
| REQ-008 | 步骤→DB 映射表（4 行） | ✅ 已实现，与表逐行一致（成对链接 + 有序 marker） |
| RULE-1/2/3/4 | 成对链接 / 链上一步产出 / marker=前置步骤 / 无 step 则无链接无 marker | ✅ 全部满足 |

## 二、未实现 / 待使用者补全的功能

1. **占位变量未填写（运行前必填）**：
   - `block`（ASSUMPTION-A）— 留空直接报错退出。
   - `TEMPLATE_DIR`（ASSUMPTION-B）— 留空则跳过 REQ-003（仅 WARNING）。
   - `foundry_setting` / `project_setting` / `user_libpath_setting`（ASSUMPTION-C）— 留空则注入空环境变量（仅 WARNING）。
   - `MARKER_DIR`（ASSUMPTION-E）— 留空则模式 3 不 touch marker（仅 WARNING）。
2. **配置路径未确认**（相对源 run 根目录，脚本顶部 `src_*` 变量，当前为假设路径）：
   - `src_scb_configs`（默认 `SCB`）、`src_sta_configs`（默认 `STA`）— 源描述未说明 SCB/STA 配置在源 run 中的确切位置与清单。
3. **REQ-003 用复制而非链接**：若需求意图是 `ln -s`，需自行改第 5 节。
4. **路径改写的具体字段（ASSUMPTION-F）**：当前实现为"把源 run 绝对路径前缀替换为新 run 绝对路径前缀"，若实际需替换的字段不同，需改第 7.6 节。

## 三、summary 文件中未说清楚的需求（已处理方式）

| 项目 | 源描述状况 | 处理方式 |
|---|---|---|
| ASSUMPTION-A block 检测 | 未说明取 $PWD 哪一段 | **已询问使用者** → 占位变量 |
| ASSUMPTION-B 模板来源/清单 | 未给出清单与来源目录 | **已询问使用者** → 占位变量 `TEMPLATE_DIR` |
| ASSUMPTION-C 设置注入方式 | 未说明注入到哪、何种语法 | **已询问使用者** → 环境变量 |
| ASSUMPTION-D user_plug 文件/目录 | 未说明 | 不询问，两种都处理（-d 判断） |
| ASSUMPTION-E marker 路径/命名 | 未给路径 | **已询问使用者** → 占位变量 `MARKER_DIR`；文件名取步骤名（summary 建议值） |
| ASSUMPTION-F 路径改写规则 | 未说明哪些字段替换 | 采用 summary 建议值（源路径前缀→新路径前缀），做成可改代码段 |
| 5 项配置在源 run 中的位置 | 未说明 | 占位变量 `src_*`（脚本顶部） |

## 四、必要说明 / 使用须知

1. **验收示例核对**（summary 第 8 节）：6 个用例对应的行为均已实现；但示例 1/2/3/4 需先填好占位变量才能跑通。
2. **环境变量注入范围**：`setenv` 只对脚本进程及其子进程生效，不会改变调用方 shell 环境（如需对调用方生效需 `source` 脚本）。
3. **平台依赖**：`sed -i` 需要 GNU sed；`date +%m%d/%H%M`、`/dev/stderr` 为 Linux 环境惯例，建议在 Linux（RHEL/CentOS）上运行。
4. **时间戳**：`MMDD_HHMM` 取脚本运行时刻（`date`），符合 REQ-005。
5. **并发安全**：目录名精确到分钟，同一分钟内同名 suffix 运行会命中已存在目录 → 脚本会 WARNING 并继续（同名文件被覆盖）。
6. **启动方式**：`csh -f makerun.csh ...` 或直接执行（shebang 已固定 `#!/bin/csh -f`）。
