# Linux 现代化命令替代方案整理（补充篇）

继上一份《Linux 常用命令的高级替代方案整理》之后，本份文档作为**补充篇**，聚焦近年来涌现的、由开源社区（尤其 GitHub）维护的新一代命令行工具。它们大多以 Rust / Go / C 等语言编写，设计目标普遍是：**更美观的输出、更快的速度、更人性化的交互**，很多已成为开发者终端里的新标配。凡是上一份文档已收录的命令（如 `bat`、`fd`、`ripgrep`、`eza`、`htop`、`zoxide` 等），本份不再重复列出。

---

## 一、Linux 系统自带的高级替代/组合

这些命令或功能大多随主流发行版默认提供，无需额外安装，比基础命令覆盖更多现代场景。

| 基础命令 | 高级替代/组合 | 优势和额外功能 | 使用场景 |
|---------|---------------|----------------|----------|
| `iptables` | `nftables` | 现代内核默认防火墙框架，语法更统一简洁，性能更高，规则集原子替换 | 防火墙规则配置与管理 |
| `dmesg` | `journalctl -k` | 与 systemd 集成，支持按时间/优先级过滤、持久化存储 | 查看内核日志与启动日志 |
| `crontab` | `systemd timer` | 精度更高、可定义依赖关系、自带日志与一次性任务支持 | 定时任务、服务调度 |
| `kill` | `pkill` / `killall` | 按进程名/模式直接终止进程，无需先 `ps` 查 PID | 批量结束、按名字杀进程 |
| `free` | `free -h` | 人性化单位输出，内存/交换一目了然 | 快速查看内存占用 |
| `who` | `w` | 除登录用户外，还显示各用户正在执行的命令与负载 | 查看在线用户与活动 |
| `watch` | `watch -n 0.5` | 自定义刷新间隔，实时观察命令输出变化 | 高频实时监控输出 |

---

## 二、需要额外安装的第三方高级替代

这些工具大多托管在 GitHub，可通过包管理器（`apt` 等）、`cargo` 或直接下载二进制安装。标注「下载二进制」的表示官方源暂无或版本较旧，建议从 GitHub Release 页获取预编译文件。

| 基础命令 | 高级替代工具 | 优势和额外功能 | 安装方式（Debian/Ubuntu） |
|---------|--------------|----------------|---------------------------|
| `ls` | `lsd` | 图标与彩色输出、树状视图、Git 状态标识、完全兼容 `ls` 参数 | `cargo install lsd` 或下载 Release `.deb` |
| `du` | `dust` | 树形展示目录占用、带比例条、自动按大小排序、一眼看出大头 | `cargo install du-dust` 或下载二进制 |
| `ps` | `procs` | 彩色输出、树状进程、字段可选、支持正则与关键字过滤 | `cargo install procs` 或下载二进制 |
| `diff` | `difftastic` | 语法感知的结构化 diff，支持 30+ 编程语言，忽略纯格式差异 | `cargo install difftastic` 或下载二进制 |
| `sed` | `sd` | 直观的查找替换、字符串字面量模式、正则语法更简单、比 `sed` 快数倍 | `cargo install sd` 或部分源 `apt install sd` |
| `cut` / `awk` | `choose` | 人性化的列选择、支持负索引、正则分隔、速度快 | `cargo install choose` 或下载二进制 |
| `hexdump` / `xxd` | `hexyl` | 彩色十六进制查看、字节类型高亮、可读性极佳 | `apt install hexyl`（22.04+）或 `cargo install hexyl` |
| `ping` | `gping` | 图形化实时折线、多主机同屏对比、查看历史趋势 | 下载二进制或部分源 `apt install gping` |
| `time` | `hyperfine` | 多次运行取统计、预热、输出均值/方差、支持多命令对比 | `apt install hyperfine`（22.04+）或 `cargo install` |
| `history` | `mcfly` | 基于排名的智能历史搜索、支持 fzf 集成、跨会话复用 | `cargo install mcfly` 或下载二进制 |
| `top` / `htop` | `bottom` (`btm`) | 跨平台图形化监控、CPU/内存/磁盘/网络图表、鼠标支持 | `apt install bottom` 或下载二进制 |
| `top` | `glances` | Web/远程监控、容器与传感器支持、可输出 JSON | `apt install glances` |
| `man` | `cheat` | 社区维护的速查表、可自定义、交互式浏览 | 下载二进制或 `go install` |
| `rm` | `trash-cli` | 删除进回收站可恢复，提供 `trash-list`/`trash-restore` | `apt install trash-cli` |
| `make` | `just` | 更简单的命令运行器、自动传递参数、跨平台 | 下载二进制或较新源 `apt install just` |
| `tmux` / `screen` | `zellij` | 现代终端工作区、开箱即用的布局、插件体系、协作支持 | 下载二进制或 `cargo install zellij` |
| `python3 -m http.server` | `miniserve` | 极简静态文件服务器、目录浏览、上传支持、权限控制 | `cargo install miniserve` 或下载二进制 |
| `tail -f` | `lnav` | 日志文件浏览器、语法高亮、可用 SQL 查询日志 | `apt install lnav` |
| `locate` | `plocate` | 索引更快更小、基于 setgid 更安全 | `apt install plocate` |
| `env` / `source` | `direnv` | 进入目录自动加载对应环境变量，shell 深度集成 | `apt install direnv` |
| `jq` | `yq` | 用 jq 风格语法处理 YAML/TOML/XML/JSON | 下载二进制（mikefarah/yq） |
| `git` | `lazygit` | 交互式 Git TUI、可视化暂存、分支管理与冲突解决 | 下载二进制 |
| `neofetch` | `fastfetch` | 启动更快、输出更美观、模块可定制、支持更多平台 | 下载二进制或编译 |
| `tldr` | `tealdeer` | Rust 实现、启动更快 | `apt install tealdeer`（22.04+） |
| `dig` / `nslookup` | `dog` | 更友好的 DNS 查询、彩色输出、支持 JSON 格式 | `cargo install dog` 或下载二进制 |
| `fdupes` | `jdupes` | 更快的重复文件查找、支持硬链接合并 | `apt install jdupes` |
| `find` | `fselect` | 用类 SQL 语法查询文件、支持条件与聚合 | 下载二进制 |
| `curl` / `httpie` | `xh` | 更快的 HTTP 客户端、内置 JSON 处理、Rust 实现 | `cargo install xh` 或下载二进制 |
| `nc` / `netcat` | `ncat` | 支持 SSL、代理、端口转发等增强功能（Nmap 项目出品） | `apt install ncat` |
| `grep` | `ugrep` | 更快、支持 Unicode 与模糊搜索、彩色高亮 | 下载二进制或编译 |
| `less` | `moar` | 更小更快、语法高亮、可定制配色 | 下载二进制或部分源 `apt install moar` |
| `jq` | `jless` | 交互式 JSON 浏览器、支持折叠与搜索 | 下载二进制 |
| `scp` / `rsync` | `croc` | 端到端加密、跨设备免配置秒传文件 | 下载二进制或 `go install` |
| `wc`（代码统计） | `tokei` | 多语言代码行数统计、按语言分类汇总 | `cargo install tokei` |

---

## 三、说明

1. **不是替换，而是补充**：这些现代工具同样不追求取代基础命令。基础命令在脚本、最小化环境和可移植性方面仍不可替代；现代工具更适合交互式使用与本地开发环境，提供更好的视觉与操作体验。

2. **Rust 系工具是主流**：你会发现表中大量工具（`lsd`、`dust`、`procs`、`sd`、`choose`、`hexyl`、`hyperfine`、`bottom` 等）都是 Rust 写的——单二进制分发、无依赖、启动快，是近年 CLI 现代化的主要趋势。

3. **安装取舍**：`apt` 官方源中的版本可能偏旧；追求最新功能时，建议直接从 GitHub Release 下载预编译二进制，或使用 `cargo install`（需安装 Rust）。批量安装工具可用 `cargo-binstall` 或发行版包管理器一键拉取。

4. **注意别名冲突**：部分工具与系统命令同名或近似（如 `sd`、`dog`），安装后建议在 shell 配置中用 `alias` 区分，避免误用覆盖原生命令。

---

## 推荐安装清单（进阶）

如果你已熟悉上一份文档的入门工具，建议从这几个开始体验「现代终端」：
- `lsd` - 让 `ls` 输出带图标和颜色，颜值提升最直观
- `sd` - 日常查找替换，比 `sed` 简单直观得多
- `procs` - 查看进程更清晰，支持树状视图
- `dust` - 磁盘占用分析，一眼定位大头
- `hyperfine` - 对比两条命令谁更快
- `bottom` - 图形化的系统资源监控
- `lazygit` - Git 操作可视化，减少记忆命令
- `zellij` - 现代终端多窗格体验
- `direnv` - 按目录自动加载环境变量
- `trash-cli` - 给 `rm` 加上「后悔药」

以上工具均在 GitHub 上有活跃维护，安装与使用文档完善，适合逐步替换自己的日常习惯。
