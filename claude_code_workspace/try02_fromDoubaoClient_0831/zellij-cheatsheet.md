# Zellij Cheatsheet

> 终端复用器（Terminal Multiplexer）快速查阅手册。
> 键位基于 **default 预设**；若使用 **unlock-first 预设**，所有组合键前需先按 `Ctrl+g` 解锁，再按后续按键。

---

## 目录

1. [会话管理（Session）](#1-会话管理session)
2. [标签页管理（Tab）](#2-标签页管理tab)
3. [窗格管理（Pane）](#3-窗格管理pane)
4. [滚动模式（Scroll Mode）](#4-滚动模式scroll-mode)
5. [复制与搜索](#5-复制与搜索)
6. [配置文件常用项](#6-配置文件常用项)
7. [命令行速查](#7-命令行速查)
8. [常见问题与踩坑](#8-常见问题与踩坑)
9. [键位预设对照](#9-键位预设对照)

---

## 1. 会话管理（Session）

### 1.1 会话状态说明

| 状态 | 服务进程 | `zellij ls` 显示 | 无参 `zellij attach` | 恢复方式 |
|---|---|---|---|---|
| **ACTIVE** | 运行中 | `(ACTIVE)` | 可直接 attach | `zellij attach` |
| **DETACHED** | 运行中（后台） | `(DETACHED)` | 可直接 attach | `zellij attach` |
| **EXITED** | 已终止 | `(EXITED - attach to resurrect)` | 报错 `no active zellij sessions found` | `zellij attach <session-name>` 复活快照 |

> **EXITED 本质**：zellij 进程已死，但开启了 `session_serialization`，磁盘上保存了布局/窗格/历史命令快照。带名字 attach 会读取快照重建会话。

### 1.2 会话操作命令

| 操作 | 命令 | 说明 |
|---|---|---|
| 新建会话 | `zellij` | 自动生成随机名字 |
| 新建命名会话 | `zellij attach -c <name>` 或 `zellij --session <name>` | 创建并进入指定名字的会话 |
| 列出所有会话 | `zellij ls` | 包含 ACTIVE / DETACHED / EXITED |
| 附加到会话 | `zellij attach <name>` | 若会话 EXITED 则自动 resurrect |
| 附加并自动执行保存的命令 | `zellij attach --force-run-commands <name>` | 跳过 `Press ENTER to run...` 提示 |
| 分离当前会话（后台保留） | `Ctrl+o` 然后 `d` | 进程继续运行 |
| 完全退出（关闭会话） | `Ctrl+q` | 终止当前会话所有进程 |
| 杀死指定会话 | `zellij kill-session <name>` | 删除运行中或 EXITED 快照 |
| 杀死所有会话 | `zellij kill-all-sessions` | 清理全部 |
| 查看 EXITED 快照文件 | `ls ~/.zellij/sessions/` | 持久化保存位置 |

### 1.3 会话内快捷键（default 预设）

| 按键 | 动作 |
|---|---|
| `Ctrl+o` | 进入会话操作模式（Session Mode） |
| `d` | Detach（分离到后台） |
| `w` | 打开会话选择器（切换/新建会话） |
| `s` | 列出当前所有会话 |

---

## 2. 标签页管理（Tab）

### 2.1 Tab 操作快捷键

| 按键 | 动作 |
|---|---|
| `Ctrl+t` | 进入 Tab 模式（Tab Mode） |
| `n` | 新建 Tab |
| `d` | 关闭当前 Tab |
| `→` / `l` | 切换到下一个 Tab |
| `←` / `h` | 切换到上一个 Tab |
| `1`~`9` | 跳转到第 N 个 Tab |
| `r` | 重命名当前 Tab |
| `[` | 移动当前 Tab 到左边 |
| `]` | 移动当前 Tab 到右边 |
| `x` | 同步输入到所有 Tab（Sync Tabs） |
| `s` | 同步输入到所有 Pane（Sync Panes） |

> 进入 Tab 模式后底部状态栏显示 `TAB`，操作完成后自动退出或按 `Esc` 退出。

---

## 3. 窗格管理（Pane）

### 3.1 Pane 操作快捷键

| 按键 | 动作 |
|---|---|
| `Ctrl+p` | 进入 Pane 模式（Pane Mode） |
| `n` | 新建 Pane（水平方向，右侧） |
| `d` | 向下新建 Pane（垂直方向） |
| `x` | 关闭当前 Pane |
| `→` / `l` | 焦点移到右侧 Pane |
| `←` / `h` | 焦点移到左侧 Pane |
| `↑` / `k` | 焦点移到上方 Pane |
| `↓` / `j` | 焦点移到下方 Pane |
| `+` | 增大当前 Pane |
| `-` | 减小当前 Pane |
| `=` | 平均分配所有 Pane 大小 |
| `f` | 当前 Pane 全屏/取消全屏（Float） |
| `z` | 切换 Pane 嵌入/浮动状态 |
| `r` | 顺时针旋转 Pane 布局 |
| `c` | 关闭当前 Pane 中的命令（发送 Ctrl+c） |
| `e` | 用 `$EDITOR` 编辑当前 Pane 滚动缓冲区 |
| `s` | 切换 Pane 同步输入（Sync Panes） |

### 3.2 Pane 模式速记

```
Ctrl+p  → 进入 Pane 模式
n/d     → 新建（右/下）
h/j/k/l → 移动焦点
+/-/=   → 调整大小
f       → 全屏浮动
x       → 关闭
Esc     → 退出 Pane 模式
```

---

## 4. 滚动模式（Scroll Mode）

> 查看历史输出必须先进入滚动模式，普通模式下 PageUp/PageDown 无效。

### 4.1 进入与退出

| 操作 | 按键 |
|---|---|
| 进入滚动模式 | `Ctrl+s` |
| 退出滚动模式 | `Esc` 或 `Ctrl+c` |

### 4.2 滚动操作

| 按键 | 动作 |
|---|---|
| `k` / `↑` | 向上滚动 1 行 |
| `j` / `↓` | 向下滚动 1 行 |
| `Ctrl+b` / `PageUp` / `h` | 向上翻整页 |
| `Ctrl+f` / `PageDown` / `l` | 向下翻整页 |
| `u` | 向上翻半页 |
| `d` | 向下翻半页 |
| `[` | 跳到上一个命令提示符位置 |
| `]` | 跳到下一个命令提示符位置 |
| `g` | 跳到缓冲区顶部 |
| `G` | 跳到缓冲区底部 |
| `e` | 用 `$EDITOR` 打开全部回滚历史 |

### 4.3 滚动模式速记

```
Ctrl+s  → 进入滚动模式
k/j     → 上下单行
Ctrl+b / Ctrl+f → 整页翻
u / d   → 半页翻
[ / ]   → 按命令提示符跳转
Esc     → 返回正常终端
```

---

## 5. 复制与搜索

### 5.1 搜索（在滚动模式中）

| 按键 | 动作 |
|---|---|
| `f` | 进入搜索模式，输入关键词 |
| `n` | 下一个匹配 |
| `p` | 上一个匹配 |
| `Esc` | 退出搜索 |

### 5.2 复制（在滚动模式中）

| 按键 | 动作 |
|---|---|
| `v` | 进入选择模式（开始选文本） |
| 方向键 / `h/j/k/l` | 移动选择起点/终点 |
| `v` | 切换字符选择 / 行选择 |
| `Enter` | 复制选中内容到系统剪贴板 |
| `y` | 复制选中内容（yank） |

> 复制内容默认写入系统剪贴板，可直接在其他应用粘贴。

---

## 6. 配置文件常用项

配置文件路径：`~/.config/zellij/config.kdl`

### 6.1 核心配置

| 配置项 | 示例值 | 说明 |
|---|---|---|
| `session_serialization` | `true` / `false` | 是否持久化 EXITED 会话快照 |
| `scroll_buffer_size` | `10000` | 滚动缓冲区最大行数（默认 10000） |
| `default_mode` | `"normal"` | 默认启动模式 |
| `default_shell` | `"/bin/bash"` | 指定默认 shell |
| `default_cwd` | `"/home/user"` | 默认工作目录 |
| `mirror_session` | `true` / `false` | 新窗口是否镜像当前会话 |
| `disable_session_metadata` | `true` / `false` | 是否在状态栏隐藏会话元信息 |

### 6.2 键位预设

| 预设 | 进入模式方式 | 适用场景 |
|---|---|---|
| `default` | `Ctrl+s/t/p/o` 直接进入对应模式 | 本地使用，快捷键短 |
| `unlock-first` | 先 `Ctrl+g` 解锁，再按 `s/t/p/o` | SSH/远程，避免与应用快捷键冲突 |

切换预设：在 `config.kdl` 中设置
```kdl
keybinds clear-defaults=true {
    // 自定义键位
}
```

### 6.3 自定义滚动模式键位示例

```kdl
keybinds {
    scroll {
        bind "PageUp"   { PageScrollUp; }
        bind "PageDown" { PageScrollDown; }
        bind "Ctrl+u"   { HalfPageScrollUp; }
        bind "Ctrl+d"   { HalfPageScrollDown; }
    }
}
```

---

## 7. 命令行速查

### 7.1 启动与会话

| 命令 | 说明 |
|---|---|
| `zellij` | 启动新会话 |
| `zellij --session <name>` | 启动命名会话 |
| `zellij attach <name>` | 附加到已有会话（EXITED 则 resurrect） |
| `zellij attach -c <name>` | 创建并进入命名会话（不存在则新建） |
| `zellij attach --force-run-commands <name>` | 复活并自动执行保存的命令 |
| `zellij ls` | 列出所有会话 |
| `zellij kill-session <name>` | 杀死指定会话 |
| `zellij kill-all-sessions` | 杀死所有会话 |
| `zellij --version` | 查看版本 |
| `zellij setup --check` | 检查环境配置 |
| `zellij setup --dump-config` | 导出默认配置模板 |

### 7.2 布局（Layout）

| 命令 | 说明 |
|---|---|
| `zellij --layout <name>` | 启动时加载指定布局 |
| `zellij action new-tab --layout <name>` | 用布局新建 Tab |
| `zellij setup --dump-layout default` | 导出默认布局模板 |

布局文件存放路径：`~/.config/zellij/layouts/`

---

## 8. 常见问题与踩坑

### 8.1 EXITED 相关

| 问题 | 原因 | 解决方案 |
|---|---|---|
| `zellij attach` 报 `no active zellij sessions found` | 无参 attach 只找 ACTIVE/DETACHED 进程，EXITED 进程已死 | 必须带会话名：`zellij attach <name>` |
| EXITED 会话复活后命令不自动执行 | resurrect 默认提示 `Press ENTER to run...` | 加 `--force-run-commands` 参数 |
| `session_serialization false` 仍显示 EXITED | zellij 0.43.0 已知 bug（issue #4358） | 升级到 0.43.1 及以上版本 |
| 想彻底清理 EXITED 快照 | 快照保存在磁盘 | `zellij kill-session <name>` 或删除 `~/.zellij/sessions/` 下文件 |

### 8.2 滚动与复制

| 问题 | 原因 | 解决方案 |
|---|---|---|
| PageUp/PageDown 没反应 | 普通模式不读取回滚缓冲区 | 先按 `Ctrl+s` 进入滚动模式 |
| 进入滚动模式后敲字符不进 shell | 仍在 SCROLL 模式 | 按 `Esc` 或 `Ctrl+c` 退出 |
| 历史输出不够长 | 默认缓冲区 10000 行 | 修改 `scroll_buffer_size` 调大 |
| 复制内容无法粘贴到外部 | 未正确复制到系统剪贴板 | 滚动模式中 `v` 选中文本后按 `Enter` |

### 8.3 其他

| 问题 | 原因 | 解决方案 |
|---|---|---|
| SSH 断开后会话丢失 | 未使用 detach，直接关终端 | 用 `Ctrl+o` 然后 `d` 分离，或保持会话序列化 |
| 快捷键与 Vim/Tmux 冲突 | default 预设占用了常用键 | 改用 `unlock-first` 预设或自定义键位 |
| 状态栏不显示 | 配置了 `disable_session_metadata` | 设为 `false` 或删除该配置 |
| 窗格焦点切换不灵敏 | Pane 模式未激活 | 先按 `Ctrl+p` 进入 Pane 模式再操作 |

---

## 9. 键位预设对照

### 9.1 default vs unlock-first

| 操作 | default 预设 | unlock-first 预设 |
|---|---|---|
| 进入滚动模式 | `Ctrl+s` | `Ctrl+g` → `s` |
| 进入 Tab 模式 | `Ctrl+t` | `Ctrl+g` → `t` |
| 进入 Pane 模式 | `Ctrl+p` | `Ctrl+g` → `p` |
| 进入 Session 模式 | `Ctrl+o` | `Ctrl+g` → `o` |
| 分离会话 | `Ctrl+o` → `d` | `Ctrl+g` → `o` → `d` |
| 完全退出 | `Ctrl+q` | `Ctrl+q` |

> **unlock-first 预设**：所有模式切换前必须先按 `Ctrl+g`（状态栏显示 `UNLOCKED`），再按对应字母。适合 SSH 远程环境，避免与本地终端/Vim 快捷键冲突。

### 9.2 模式切换总览（default 预设）

| 模式 | 进入按键 | 状态栏提示 | 用途 |
|---|---|---|---|
| Normal | 默认 | `NORMAL` | 正常输入 shell 命令 |
| Locked | `Ctrl+g` | `LOCKED` | 锁定所有 zellij 快捷键，直通应用 |
| Pane | `Ctrl+p` | `PANE` | 窗格分割、移动、调整大小 |
| Tab | `Ctrl+t` | `TAB` | 标签页新建、切换、重命名 |
| Scroll | `Ctrl+s` | `SCROLL` | 回看历史输出、搜索、复制 |
| Session | `Ctrl+o` | `SESSION` | 会话分离、切换、列表 |
| Resize | `Ctrl+n` | `RESIZE` | 精确调整窗格大小 |
| Move | `Ctrl+h` | `MOVE` | 移动窗格位置 |
| Search | 滚动模式中 `f` | `SEARCH` | 搜索历史输出 |

---

## 附录：最常用 10 条命令速查

| 排名 | 命令/按键 | 用途 |
|---|---|---|
| 1 | `zellij attach -c <name>` | 创建并进入命名会话 |
| 2 | `Ctrl+o` → `d` | 分离会话到后台 |
| 3 | `zellij ls` | 查看所有会话状态 |
| 4 | `zellij attach <name>` | 回到会话（含 EXITED 复活） |
| 5 | `Ctrl+s` | 进入滚动模式看历史 |
| 6 | `Ctrl+p` → `n` / `d` | 分割窗格 |
| 7 | `Ctrl+t` → `n` | 新建标签页 |
| 8 | `Ctrl+q` | 完全退出当前会话 |
| 9 | 滚动模式 `f` | 搜索历史输出 |
| 10 | `zellij kill-all-sessions` | 清理所有会话 |

---

*文档生成时间：2026-09-01 | 基于 zellij 0.43.x 版本整理*
