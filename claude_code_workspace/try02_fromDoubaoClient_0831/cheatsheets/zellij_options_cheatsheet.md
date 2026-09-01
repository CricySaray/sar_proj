# Zellij Options 配置速查表

> 来源：https://zellij.dev/documentation/options.html
> 所有配置项均写在 `~/.config/zellij/config.kdl` 的**顶层**（`ui {}` 块内的除外，已单独标注）。
> 共 54 个选项，按功能分为 11 类。

---

## 一、会话生命周期

| 配置项 | 可选值 / 类型 | 默认值 | 作用 | 改动影响 |
|---|---|---|---|---|
| `on_force_close` | `detach` / `quit` | `detach` | zellij 收到 SIGTERM/SIGINT/SIGQUIT/SIGHUP（如关闭终端窗口）时的行为 | 设为 `quit`：关闭终端时整个会话直接退出，不会后台保留；`detach`：会话 detach 到后台，可重新 attach |
| `session_name` | 字符串 | 随机生成 | 启动时创建的会话名称 | 设为固定名后每次启动都用同名会话；配合 `attach_to_session` 可实现单例 |
| `attach_to_session` | `true` / `false` | `false` | 若 `session_name` 指定的会话已存在，直接 attach 而非新建 | 设为 `true`：同名会话已存在时自动加入，避免重复创建；适合固定工作流 |
| `mirror_session` | `true` / `false` | `false` | 多人 attach 同一会话时，是否镜像（共享光标） | `true`：所有人看到同一光标位置，适合演示/协作；`false`：每人独立光标 |
| `default_mode` | `"normal"` / `"locked"` 等 | `normal` | zellij 启动时进入的模式 | 设为 `"locked"`：启动即锁定，需先解锁才能用快捷键，适合防误触 |

---

## 二、UI 外观与边框

| 配置项 | 可选值 / 类型 | 默认值 | 作用 | 改动影响 |
|---|---|---|---|---|
| `simplified_ui` | `true` / `false` | `false` | 向插件请求简化 UI（不使用箭头字体/特殊符号） | 设为 `true`：状态栏等插件不用 powerline 箭头符号，适合字体不支持特殊字符的终端 |
| `pane_frames` | `true` / `false` | `true` | 是否显示 pane 边框 | `false`：完全隐藏窗格边框，界面更干净但难以区分 pane 边界 |
| `rounded_corners` | `true` / `false` | — | pane 边框是否圆角 | 写在 `ui { pane_frames { rounded_corners true } }` 内；`false` 为直角边框 |
| `hide_session_name` | `true` / `false` | — | 隐藏 UI 上的会话名称 | 写在 `ui { pane_frames { hide_session_name true } }` 内；状态栏不再显示会话名 |
| `auto_layout` | `true` / `false` | `true` | zellij 是否按预设布局自动排列 pane | `false`：关闭自动布局，新建 pane 时不自动重排，需手动调整 |
| `styled_underlines` | `true` / `false` | `true` | 是否支持扩展的 styled underlines ANSI 协议 | `false`：忽略彩色/样式下划线转义，避免不支持的终端出现乱码 |
| `show_startup_tips` | `true` / `false` | `true` | 启动时是否显示使用提示 | `false`：关闭启动提示，可通过 `Ctrl+o` `a` 再按 `?` 查看 |
| `show_release_notes` | `true` / `false` | `true` | 新版本首次运行时是否显示 release notes | `false`：不弹更新说明 |
| `osc8_hyperlinks` | `true` / `false` | `false` | 是否启用可点击的 OSC8 超链接输出 | `true`：终端中支持 OSC8 的程序输出可点击链接；不支持的终端可能显示乱码 |
| `visual_bell` | `true` / `false` | `true` | pane 发出 bell 字符时是否显示视觉提示 | `false`：关闭边框闪烁和 tab 上的 `[!]` 标记，安静模式 |

---

## 三、主题与颜色

| 配置项 | 可选值 / 类型 | 默认值 | 作用 | 改动影响 |
|---|---|---|---|---|
| `theme` | 主题名字符串 | `default` | 选择 zellij 配色主题 | 必须是内置主题名或 `themes{}` 中定义/`theme_dir` 下的主题名；写错会 fallback 到 default |
| `theme_dark` | 主题名字符串 | — | 定义"暗色主题"，供 `ToggleTheme` / `SetDarkTheme` 使用；终端报告暗色模式时自动应用 | 设好后可一键切换明暗；终端支持 CSI 2031/DSR 997 时自动跟随系统 |
| `theme_light` | 主题名字符串 | — | 定义"亮色主题"，供 `ToggleTheme` / `SetLightTheme` 使用；终端报告亮色模式时自动应用 | 同上，配合 `theme_dark` 实现明暗切换 |
| `theme_dir` | 路径字符串 | 默认主题目录 | 指定 zellij 查找主题文件的文件夹 | 改到自定义路径后，`theme "xxx"` 会从该目录加载 `.kdl` 主题文件 |

---

## 四、鼠标交互

| 配置项 | 可选值 / 类型 | 默认值 | 作用 | 改动影响 |
|---|---|---|---|---|
| `mouse_mode` | `true` / `false` | `true` | 是否启用鼠标模式 | `false`：关闭鼠标交互，某些终端下可避免鼠标选中文本被拦截 |
| `advanced_mouse_actions` | `true` / `false` | `true` | 启用鼠标悬停效果、多选 pane 分组、鼠标拖拽调整 pane 大小 | `false`：不能拖拽边框 resize、Ctrl+滚轮 resize、pane 分组等高级鼠标操作 |
| `mouse_hover_effects` | `true` / `false` | `true` | 鼠标悬停时是否显示 pane 边框高亮和帮助文字 | `false`：悬停无视觉反馈，界面更静态 |
| `focus_follows_mouse` | `true` / `false` | `false` | 鼠标悬停是否自动聚焦该 pane | `true`：鼠标移到哪个 pane 就自动切焦点，无需点击；适合多屏高效操作 |
| `mouse_click_through` | `true` / `false` | `false` | 点击 pane 聚焦时是否同时把点击事件传给 pane 内程序 | `true`：第一次点击既聚焦又穿透到程序（如 vim 中点击定位光标）；`false`：第一次点击只聚焦 |
| `stacked_resize` | `true` / `false` | `true` | 非方向性 resize（默认 `Alt+/-`）时是否尝试与相邻 pane 堆叠联动 | `false`：resize 只影响当前 pane，不联动邻居 |

---

## 五、复制与剪贴板

| 配置项 | 可选值 / 类型 | 默认值 | 作用 | 改动影响 |
|---|---|---|---|---|
| `copy_command` | 命令字符串 | 未设置（用 OSC 52） | 复制文本时执行的外部命令，文本通过 stdin 传入 | 终端不支持 OSC 52 时必须设置；如 `xclip -selection clipboard`、`wl-copy`、`pbcopy` |
| `copy_clipboard` | `system` / `primary` | `system` | 复制目标：系统剪贴板还是 X11 primary selection | `primary`：选中即存入主选区（中键粘贴），不进系统剪贴板；设了 `copy_command` 时此项无效 |
| `copy_on_select` | `true` / `false` | `true` | 鼠标选中文本松开后是否自动复制 | `false`：选中不会自动复制，需手动快捷键复制 |

---

## 六、滚动缓冲与编辑器

| 配置项 | 可选值 / 类型 | 默认值 | 作用 | 改动影响 |
|---|---|---|---|---|
| `scroll_buffer_size` | 正整数 | `10000` | 每个 pane 的滚动回滚缓冲区行数，超出按 FIFO 丢弃 | 调大：保留更多历史输出，但占内存；调小：省内存但历史少 |
| `scrollback_editor` | 路径字符串 | `$EDITOR` 或 `$VISUAL` | 编辑 scrollback、CLI/layout `edit` 命令使用的编辑器 | 设为如 `/usr/bin/vim`，不依赖环境变量；影响 `Ctrl+o` + `e` 打开 scrollback |

---

## 七、布局与 Shell

| 配置项 | 可选值 / 类型 | 默认值 | 作用 | 改动影响 |
|---|---|---|---|---|
| `default_shell` | 路径/命令字符串 | `$SHELL` | 新建 pane 时使用的默认 shell | 设为 `fish` / `zsh` 等可覆盖系统默认 shell；不影响已打开 pane |
| `default_layout` | 布局名字符串 | `default` | 启动时加载的布局名（须在 layouts 目录中） | 设为自定义布局名，每次启动自动加载该布局 |
| `layout_dir` | 路径字符串 | 默认布局目录 | zellij 查找布局文件的文件夹 | 改到自定义路径后，`default_layout` 和 `--layout` 从该目录加载 |
| `default_cwd` | 路径字符串 | 未设置 | 新建 pane 的默认工作目录 | 设为固定路径后所有新 pane 都在该目录打开，而非继承当前目录 |

---

## 八、会话序列化与复活（Session Resurrection）

| 配置项 | 可选值 / 类型 | 默认值 | 作用 | 改动影响 |
|---|---|---|---|---|
| `session_serialization` | `true` / `false` | `true` | 是否将会话序列化到 cache 目录，使其可在重启/退出后复活 | `false`：关闭会话持久化，重启后无法恢复之前的会话和 pane |
| `pane_viewport_serialization` | `true` / `false` | `false` | 配合 `session_serialization`，是否序列化 pane 可视区域内容 | `true`：复活时恢复 pane 可见画面；增加磁盘和 CPU 开销 |
| `scrollback_lines_to_serialize` | `0` / 正整数 | — | `pane_viewport_serialization` 开启时，序列化多少行 scrollback；`0` 表示全部 | 设大或 `0`：复活后保留更多历史，但 cache 目录占用显著增加 |
| `serialization_interval` | 正整数（秒） | — | 会话序列化到磁盘的间隔秒数 | 调小：数据更实时但频繁写盘耗资源；调大：省资源但崩溃时丢失更多 |
| `disable_session_metadata` | `true` / `false` | `false` | 是否禁止写入会话元数据到磁盘 | `true`：session-manager、会话列表等功能可能异常；适合隐私/只读环境 |
| `post_command_discovery_hook` | 命令字符串 | 未设置 | zellij 发现 pane 中运行的命令用于序列化时，可通过此 hook 修正不准确的命令 | 命令通过 `$RESURRECT_COMMAND` 变量传入，STDOUT 输出替换原命令；如剥离 `sudo` 前缀 |

---

## 九、Web 服务器

| 配置项 | 可选值 / 类型 | 默认值 | 作用 | 改动影响 |
|---|---|---|---|---|
| `web_server` | `true` / `false` | `false` | 启动时是否开启 zellij web 服务器 | `true`：可通过浏览器访问 zellij；会监听端口，注意安全 |
| `web_server_ip` | IP 字符串 | `127.0.0.1` | web 服务器监听的 IP | 设为 `0.0.0.0` 可局域网访问，有安全风险 |
| `web_server_port` | 端口整数 | `8082` | web 服务器监听端口 | 冲突时改端口 |
| `web_server_cert` | 文件路径 | — | SSL 证书路径，需配合 `web_server_key` | 设了 cert+key 后 web 服务走 HTTPS |
| `web_server_key` | 文件路径 | — | SSL 私钥路径，需配合 `web_server_cert` | 同上 |
| `enforce_https_on_localhost` | `true` / `false` | — | localhost 是否强制 HTTPS | 非 localhost 地址始终强制 HTTPS |
| `base_url` | 路径字符串 | 根路径 `/` | web 服务器的 URL 前缀，写在 `web_client { base_url "/zellij" }` 内 | 反向代理子路径部署时必须设置，否则资源 404 |
| `web_client` | `true` / `false` | `false` | 浏览器内终端客户端的配置开关（颜色、字体等） | 详见 web-server 文档；开启后可在浏览器中操作 zellij |
| `web_sharing` | `"on"` / `"off"` / `"disabled"` | `"off"` | 新会话是否通过本地 web 服务器共享 | `"on"`：新会话默认共享；`"disabled"`：完全禁用共享功能 |

---

## 十、环境变量

| 配置项 | 可选值 / 类型 | 默认值 | 作用 | 改动影响 |
|---|---|---|---|---|
| `env` | key→value map | 空 | 为每个 zellij 启动的终端 pane 设置环境变量 | 写法 `env { RUST_BACKTRACE 1 FOO "bar" }`；所有新 pane 继承这些变量 |

---

## 十一、键盘协议

| 配置项 | 可选值 / 类型 | 默认值 | 作用 | 改动影响 |
|---|---|---|---|---|
| `support_kitty_keyboard_protocol` | `true` / `false` | 终端支持时默认 `true` | 是否启用 Kitty 键盘协议，提供更精细的按键上报 | `false`：关闭后某些组合键（如 Ctrl+Shift+字母）可能无法区分；兼容旧终端 |

---

## 快速参考：最小常用配置示例

```kdl
// ~/.config/zellij/config.kdl

// 主题
theme "tokyo-night"
theme_dark "tokyo-night"
theme_light "catppuccin-latte"

// 外观
pane_frames true
simplified_ui false
ui {
    pane_frames {
        rounded_corners false
        hide_session_name false
    }
}

// 鼠标
mouse_mode true
focus_follows_mouse true
copy_on_select true

// 滚动
scroll_buffer_size 20000
scrollback_editor "/usr/bin/vim"

// 会话
on_force_close "quit"
default_shell "fish"
default_cwd "/home/user/projects"

// 环境变量
env {
    EDITOR "vim"
}
```

---

## 备注

- 所有布尔值直接写 `true` / `false`，字符串值需加双引号。
- `ui {}` 块内的配置（`rounded_corners`、`hide_session_name`）不能写在顶层。
- `web_client {}` 块内的 `base_url` 同理。
- 修改配置后需**重启 zellij 会话**（或 `zellij options --xxx` 运行时调整部分项）才能生效。
