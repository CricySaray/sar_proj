# xargs 命令速查表与常用用法

`xargs` 从标准输入读取条目（item），并以这些条目作为参数去构造并执行命令行。本文件严格依据本机 `man xargs`（GNU findutils，`xargs` 4.9.0）整理，所有选项描述均与 manpage 保持一致。

## 默认行为（DESCRIPTION 要点）

- 默认从**标准输入**读取条目；条目以 **blank（空格/制表符）或换行**分隔，blank 可用**双引号、单引号或反斜杠**保护；**空行被忽略**。
- 默认执行的命令是 **`echo`**（未指定 command 时）。
- 每次执行命令时，先放置 initial-arguments，再追加从输入读到的条目。
- 命令行会一直拼接到达到**系统定义的长度上限**为止（除非用了 `-n` 或 `-L`）；必要时会多次调用命令以耗尽所有输入条目——通常命令的调用次数远少于条目数，带来显著性能收益。
- 文件名中可能包含空格和换行，默认行为对这些情况处理不正确，应改用 **`-0`**（配合 `find -print0`）。
- 若某次命令调用以状态 **255** 退出，xargs 会**立即停止**，不再读取后续输入，并在 stderr 报错。

---

## 一、选项速查表（严格对应 manpage）

### 1. 输入读取与分割

| 选项 | 说明（按 manpage） |
|------|--------------------|
| `-0, --null` | 输入条目以 **NUL 字符**（而非空白）结束；引号和反斜杠不再是特殊字符（每个字符都按字面处理）。**禁用 EOF 字符串**（被当作普通参数）。适用于输入条目可能含空格、引号、反斜杠的场景。GNU `find -print0` 产生的输入恰好适配此模式 |
| `-a file, --arg-file=file` | 从**文件 file** 读取条目而非标准输入。使用该选项时，命令运行时 **stdin 保持原样**；否则 stdin 会被重定向到 `/dev/null` |
| `-d delim, --delimiter=delim` | 输入条目以**指定字符**结束。delim 可以是单个字符、C 风格转义（如 `\n`）、或八进制/十六进制转义码（规则同 `printf`）。**不支持多字节字符**。引号和反斜杠不再是特殊字符。**禁用 EOF 字符串**。可用于「换行分隔」的输入，但 manpage 建议「几乎总是更应让上游程序改用 `--null`」 |
| `-E eof-str` | 设置 **EOF 字符串**为 eof-str。若输入中出现单独一行为 eof-str，其后所有输入被忽略。若既没用 `-E` 也没用 `-e`，则不使用 EOF 字符串 |
| `-e[eof-str], --eof[=eof-str]` | `-E` 的同义词。**不符合 POSIX**，应使用 `-E`。若省略 eof-str，则没有 EOF 字符串 |

### 2. 每次命令行的参数/行数控制

| 选项 | 说明（按 manpage） |
|------|--------------------|
| `-I replace-str` | 用从标准输入读到的名字**替换 initial-arguments 中出现的 replace-str**。此时**未加引号的 blank 不再终止条目**，分隔符改为换行符。**隐含 `-x` 和 `-L 1`** |
| `-i[replace-str], --replace[=replace-str]` | 若指定了 replace-str，等同于 `-Ireplace-str`；若省略，等同 `-I{}`。**已弃用**，请用 `-I` |
| `-L max-lines` | 每条命令行最多使用 **max-lines 行非空输入行**。行尾的 blank 会导致该输入行在逻辑上延续到下一行。**隐含 `-x`** |
| `-l[max-lines], --max-lines[=max-lines]` | `-L` 的同义词。与 `-L` 不同，max-lines 可省略，省略时默认 **1**。**已弃用**（POSIX 规定使用 `-L`） |
| `-n max-args, --max-args=max-args` | 每条命令行最多使用 **max-args 个参数**。若大小（见 `-s`）被超过，会使用少于 max-args 个参数；除非同时给出 `-x`（此时 xargs 直接退出） |

### 3. 并行与交互

| 选项 | 说明（按 manpage） |
|------|--------------------|
| `-P max-procs, --max-procs=max-procs` | 最多同时运行 **max-procs 个进程**，默认 **1**。取 **0** 表示尽可能多地同时运行。**建议与 `-n` 或 `-L` 配合**，否则往往只会执行一次 exec。运行期间可向 xargs 发 **SIGUSR1** 增加并发数、**SIGUSR2** 减少并发数（上限见 `--show-limits`，下限为 1）。注意：并行进程若共享 stdout，输出顺序不确定、很可能混在一起，需自行加锁或让各进程写独立文件 |
| `-o, --open-tty` | 在执行命令前，把子进程的 stdin **重新打开为 `/dev/tty`**。用于让 xargs 运行**交互式**应用 |
| `-p, --interactive` | 逐条询问用户是否运行该命令行，并从终端读取一行；仅当响应以 `y` 或 `Y` 开头时才运行。**隐含 `-t`** |
| `--process-slot-var=name` | 在每个运行中的子进程里，把环境变量 name 设为**唯一值**；子进程退出后该值会被复用。可用于简单的负载分配 |

### 4. 长度限制与空输入

| 选项 | 说明（按 manpage） |
|------|--------------------|
| `-r, --no-run-if-empty` | 若标准输入**不含任何非空白（nonblank）内容**，则不运行命令。正常情况下（不加此选项）即使没有输入也会运行一次命令。**GNU 扩展** |
| `-s max-chars, --max-chars=max-chars` | 每条命令行最多 **max-chars 个字符**，包括命令、initial-arguments 以及各参数字符串结尾的 NUL。允许的最大值依系统而定。若该值超过 128KiB，默认取 128KiB；否则默认即最大值（1KiB = 1024 字节）。xargs 会自动适应更紧的约束 |
| `-x, --exit` | 若大小（见 `-s`）被超过则**退出** |
| `--show-limits` | 显示操作系统、xargs 缓冲区选择以及 `-s` 选项共同决定的命令行长度限制。若不想让 xargs 做任何事，可将输入从 `/dev/null` 管道传入（并可加 `--no-run-if-empty`） |

### 5. 调试与其它

| 选项 | 说明（按 manpage） |
|------|--------------------|
| `-t, --verbose` | 在执行命令**之前**，把该命令行**打印到标准错误输出（stderr）**。注意：**命令仍会被执行**，`-t` 只是回显，并非「只预览不执行」 |
| `--help` | 打印选项摘要并退出 |
| `--version` | 打印版本号并退出 |

> **互斥关系**：`--max-lines`（`-L`、`-l`）、`--replace`（`-I`、`-i`）、`--max-args`（`-n`）三者**互斥**。若同时给出，xargs 一般使用**最后出现的那个**，并在 stderr 给出警告。例外：`-n1` 在 `--replace` 及其别名 `-I`/`-i` 之后会被忽略（因为不构成实际冲突）。

---

## 二、退出状态（EXIT STATUS）

| 状态码 | 含义 |
|--------|------|
| `0` | 成功 |
| `1` | 其它错误 |
| `123` | 某次命令调用以 1–125 状态退出 |
| `124` | 命令以 **255** 状态退出（对应「255 即停止」的规则） |
| `125` | 命令被**信号**杀死 |
| `126` | 命令**无法运行** |
| `127` | 命令**未找到** |

> 超过 128 的退出码由 shell 用来表示程序因致命信号而死。

---

## 三、常用使用场景与命令解析

### 1. 从文件读取条目并批量创建目录

```bash
xargs -a dirs.txt mkdir -p
```

- 依据 manpage 对 `-a` 的描述：从文件 `dirs.txt` 读条目，命令运行时 **stdin 保持原样**（不会像默认那样被重定向到 `/dev/null`）。
- `mkdir -p` 会按需多次调用以耗尽全部条目。

### 2. 删除 find 找到的文件（manpage 示例）

```bash
# 方式一：注意文件名含空格/换行时处理不正确
find /tmp -name core -type f -print | xargs /bin/rm -f

# 方式二：正确处理含空格或换行的文件名
find /tmp -name core -type f -print0 | xargs -0 /bin/rm -f
```

- `-print0` 以 NUL 分隔输出，与 `-0` 严格配对（manpage 说明 GNU find 的 `-print0` 正是为 `-0` 准备的输入）。
- manpage 同时指出更高效的做法是直接 `find /tmp -depth -name core -type f -delete`（省去 fork/exec 启动 rm 和额外的 xargs 进程）。

### 3. 用 `-I` 把参数放到命令的任意位置

```bash
find . -name '*.c' | xargs -I {} mv {} backup/
```

- `-I {}`：用读到的名字**替换** initial-arguments 里的 `{}`，因此参数可以出现在命令中间。
- 关键语义（manpage）：此时**未加引号的 blank 不再终止条目**，分隔符是换行；并且**隐含 `-x` 和 `-L 1`**（即一次一行）。

### 4. 并行执行（`-P` 配合 `-n` 或 `-L`）

```bash
find . -name '*.png' -print0 | xargs -0 -P 4 -n 1 optipng
```

- `-P 4` 最多同时跑 4 个进程（默认 1）；`-n 1` 每次只传 1 个参数，两者配合才真正并行。
- manpage 提醒：并行进程共享 stdout 时**输出顺序不确定、易混叠**，需要时用加锁或各自写独立文件。

### 5. 每个参数单独执行一次（`-n 1`）

```bash
cat urls.txt | xargs -n 1 curl -O
```

- `-n 1`：每条命令行最多 1 个参数，即每读到一个 URL 就执行一次 `curl -O <url>`。
- 若大小超过 `-s`，会用少于 max-args 的参数；除非加了 `-x`（此时退出）。

### 6. 按指定字符切分（`-d`）

```bash
grep -l 'TODO' *.txt | xargs -d '\n' sed -i 's/TODO/FIXME/'
```

- `-d '\n'`：以换行符作为条目分隔符（`\n` 是 C 风格转义，规则同 `printf`）；引号/反斜杠不再特殊，并禁用 EOF 字符串。
- manpage 建议：这种「换行分隔」场景**几乎总是更应让上游改用 `--null`**。

### 7. 回显即将执行的命令（`-t`）

```bash
find . -name '*.bak' | xargs -t rm -f
```

- 依据 manpage：`-t` 在**执行前把命令行打印到 stderr**；命令**仍然会被执行**，`-t` 不是「dry-run」。
- 想要「只看不执行」，xargs 本身没有对应选项；`-t` 只是便于观察拼出的命令长什么样。

### 8. 交互式确认（`-p`，隐含 `-t`）

```bash
find /var/cache -name '*.tmp' | xargs -p rm -f
```

- 每条命令执行前提示并从终端读取一行，**仅当响应以 `y` 或 `Y` 开头才执行**。
- 注意 manpage：`-p` **隐含 `-t`**。

### 9. 空输入不执行（`-r`）

```bash
grep -l 'pattern' *.c | xargs -r rm
```

- 依据 manpage：若标准输入**不含任何非空白内容**，则不运行命令；默认（不加 `-r`）即使没输入也会运行一次。
- 精确语义是「nonblank」：输入只有空格/空行时也算「空」，不会执行。该选项是 **GNU 扩展**。

### 10. 查看长度限制与控制命令行长度（`--show-limits`、`-s`）

```bash
xargs --show-limits
seq 1 100000 | xargs -s 10000 echo
```

- `--show-limits`：显示 OS、xargs 缓冲区与 `-s` 共同决定的长度限制；若不希望 xargs 执行任何命令，从 `/dev/null` 管道输入。
- `-s 10000`：每条命令行最多 10000 字符（**含**命令、initial-arguments 及参数结尾的 NUL），超出自动分批。

### 11. 按行分组（`-L`）

```bash
seq 1 100 | xargs -L 10 echo
```

- `-L 10`：每条命令行最多 10 行非空输入；**隐含 `-x`**。
- 注意 manpage：行尾的 blank 会使该输入行在逻辑上延续到下一行。`-l` 是 `-L` 的已弃用同义词。

### 12. 逻辑 EOF（`-E`）

```bash
printf 'a\nb\nEND\nc\n' | xargs -E END echo
# 输出：a b
```

- 输入中出现单独一行的 `END` 后，其后的 `c` 被忽略（依据 `-E` 的 manpage 描述）。

### 13. 生成系统用户清单（manpage 示例）

```bash
cut -d: -f1 < /etc/passwd | sort | xargs echo
```

- 从 `/etc/passwd` 取用户名字段、排序后交给 `xargs echo`，生成一行紧凑的系统用户列表。

---

## 四、核心要点速记

| 需求 | 用法 | 依据的 manpage 语义 |
|------|------|---------------------|
| 处理含空格/换行的文件名 | `find ... -print0 \| xargs -0` | `-0` 以 NUL 分隔，引号/反斜杠不特殊，禁用 EOF |
| 从文件读条目 | `xargs -a file` | `-a` 读文件，stdin 保持不变 |
| 把参数插到命令中间 | `xargs -I {} cmd {}` | `-I` 替换 initial-arguments，隐含 `-x` 和 `-L 1` |
| 并行执行 | `xargs -P N`（默认 1，`0` 不限） | 建议配合 `-n`/`-L`；共享 stdout 会混叠 |
| 每个参数跑一次 | `xargs -n 1` | `-n` 每次最多 N 个参数 |
| 空输入不执行 | 加 `-r` | stdin 不含 nonblank 时不运行（GNU 扩展） |
| 回显命令（仍会执行） | 加 `-t` | 执行前打印到 **stderr** |
| 逐条确认 | 加 `-p` | 以 `y`/`Y` 开头才执行，隐含 `-t` |
| 按行切分 | `xargs -d '\n'` | 自定义分隔符，禁用 EOF；更推荐 `--null` |
| 查看长度限制 | `xargs --show-limits` | 显示 OS/缓冲区/`-s` 共同限制 |

**一句话总结**：`xargs` 从标准输入（或 `-a` 指定的文件）读取条目 → 按规则（`-n`/`-L`/`-I`，三者互斥）分组 → 可选并行（`-P`）→ 把条目追加到命令后执行（默认命令为 `echo`）。命令以状态 255 退出时 xargs 立即停止。



## Appendix
```plain

XARGS(1)                                                  General Commands Manual                                                 XARGS(1)

NAME
       xargs - build and execute command lines from standard input

SYNOPSIS
       xargs [options] [command [initial-arguments]]

DESCRIPTION
       This  manual page documents the GNU version of xargs.  xargs reads items from the standard input, delimited by blanks (which can be
       protected with double or single quotes or a backslash) or newlines, and executes the command (default is echo) one  or  more  times
       with any initial-arguments followed by items read from standard input.  Blank lines on the standard input are ignored.

       The  command  line  for  command  is built up until it reaches a system-defined limit (unless the -n and -L options are used).  The
       specified command will be invoked as many times as necessary to use up the list of input items.  In general,  there  will  be  many
       fewer  invocations  of command than there were items in the input.  This will normally have significant performance benefits.  Some
       commands can usefully be executed in parallel too; see the -P option.

       Because Unix filenames can contain blanks and newlines, this default behaviour is often problematic;  filenames  containing  blanks
       and/or  newlines  are  incorrectly  processed by xargs.  In these situations it is better to use the -0 option, which prevents such
       problems.   When using this option you will need to ensure that the program which produces the input for xargs  also  uses  a  null
       character as a separator.  If that program is GNU find for example, the -print0 option does this for you.

       If any invocation of the command exits with a status of 255, xargs will stop immediately without reading any further input.  An er‐
       ror message is issued on stderr when this happens.

OPTIONS
       -0, --null
              Input items are terminated by a null character instead of by whitespace, and the quotes and backslash are not special (every
              character  is taken literally).  Disables the end of file string, which is treated like any other argument.  Useful when in‐
              put items might contain white space, quote marks, or backslashes.  The GNU find -print0 option produces input  suitable  for
              this mode.

       -a file, --arg-file=file
              Read  items  from  file  instead  of standard input.  If you use this option, stdin remains unchanged when commands are run.
              Otherwise, stdin is redirected from /dev/null.

       --delimiter=delim, -d delim
              Input items are terminated by the specified character.  The specified delimiter may be a single character, a C-style charac‐
              ter escape such as \n, or an octal or hexadecimal escape code.  Octal and hexadecimal escape codes are understood as for the
              printf command.   Multibyte characters are not supported.  When processing the input, quotes and backslash are not  special;
              every  character  in the input is taken literally.  The -d option disables any end-of-file string, which is treated like any
              other argument.  You can use this option when the input consists of simply newline-separated items, although  it  is  almost
              always better to design your program to use --null where this is possible.

       -E eof-str
              Set  the  end  of file string to eof-str.  If the end of file string occurs as a line of input, the rest of the input is ig‐
              nored.  If neither -E nor -e is used, no end of file string is used.

       -e[eof-str], --eof[=eof-str]
              This option is a synonym for the -E option.  Use -E instead, because it is POSIX compliant while this  option  is  not.   If
              eof-str is omitted, there is no end of file string.  If neither -E nor -e is used, no end of file string is used.

       -I replace-str
              Replace  occurrences  of replace-str in the initial-arguments with names read from standard input.  Also, unquoted blanks do
              not terminate input items; instead the separator is the newline character.  Implies -x and -L 1.

       -i[replace-str], --replace[=replace-str]
              This option is a synonym for -Ireplace-str if replace-str is specified.  If the replace-str argument is missing, the  effect
              is the same as -I{}.  This option is deprecated; use -I instead.

       -L max-lines
              Use  at most max-lines nonblank input lines per command line.  Trailing blanks cause an input line to be logically continued
              on the next input line.  Implies -x.

       -l[max-lines], --max-lines[=max-lines]
              Synonym for the -L option.  Unlike -L, the max-lines argument is optional.  If max-lines is not specified,  it  defaults  to
              one.  The -l option is deprecated since the POSIX standard specifies -L instead.

       -n max-args, --max-args=max-args
              Use at most max-args arguments per command line.  Fewer than max-args arguments will be used if the size (see the -s option)
              is exceeded, unless the -x option is given, in which case xargs will exit.

       -P max-procs, --max-procs=max-procs
              Run  up to max-procs processes at a time; the default is 1.  If max-procs is 0, xargs will run as many processes as possible
              at a time.  Use the -n option or the -L option with -P; otherwise chances are that only one exec will be done.  While  xargs
              is running, you can send its process a SIGUSR1 signal to increase the number of commands to run simultaneously, or a SIGUSR2
              to  decrease  the number.  You cannot increase it above an implementation-defined limit (which is shown with --show-limits).
              You cannot decrease it below 1.  xargs never terminates its commands; when asked to decrease, it merely waits for more  than
              one existing command to terminate before starting another.

              Please  note  that it is up to the called processes to properly manage parallel access to shared resources.  For example, if
              more than one of them tries to print to stdout, the output will be produced in an indeterminate order (and very likely mixed
              up) unless the processes collaborate in some way to prevent this.  Using some kind of locking scheme is one way  to  prevent
              such  problems.   In  general,  using a locking scheme will help ensure correct output but reduce performance.  If you don't
              want to tolerate the performance difference, simply arrange for each process to produce a separate output file (or otherwise
              use separate resources).

       -o, --open-tty
              Reopen stdin as /dev/tty in the child process before executing the command.  This is useful if you want xargs to run an  in‐
              teractive application.

       -p, --interactive
              Prompt  the user about whether to run each command line and read a line from the terminal.  Only run the command line if the
              response starts with `y' or `Y'.  Implies -t.

       --process-slot-var=name
              Set the environment variable name to a unique value in each running child process.  Values are reused once  child  processes
              exit.  This can be used in a rudimentary load distribution scheme, for example.

       -r, --no-run-if-empty
              If  the  standard  input  does not contain any nonblanks, do not run the command.  Normally, the command is run once even if
              there is no input.  This option is a GNU extension.

       -s max-chars, --max-chars=max-chars
              Use at most max-chars characters per command line, including the command and initial-arguments and the terminating nulls  at
              the  ends  of the argument strings.  The largest allowed value is system-dependent, and is calculated as the argument length
              limit for exec, less the size of your environment, less 2048 bytes of headroom.  If this value is more than  128KiB,  128Kib
              is  used as the default value; otherwise, the default value is the maximum.  1KiB is 1024 bytes.  xargs automatically adapts
              to tighter constraints.

       --show-limits
              Display the limits on the command-line length which are imposed by the operating system, xargs' choice of  buffer  size  and
              the  -s  option.   Pipe  the input from /dev/null (and perhaps specify --no-run-if-empty) if you don't want xargs to do any‐
              thing.

       -t, --verbose
              Print the command line on the standard error output before executing it.

       -x, --exit
              Exit if the size (see the -s option) is exceeded.

       --help Print a summary of the options to xargs and exit.

       --version
              Print the version number of xargs and exit.

       The options --max-lines (-L, -l), --replace (-I, -i) and --max-args (-n) are mutually exclusive. If some of them are  specified  at
       the  same  time,  then xargs will generally use the option specified last on the command line, i.e., it will reset the value of the
       offending option (given before) to its default value.  Additionally, xargs will issue a warning diagnostic on stderr.   The  excep‐
       tion to this rule is that the special max-args value 1 ('-n1') is ignored after the --replace option and its aliases -I and -i, be‐
       cause it would not actually conflict.

EXAMPLES
       find /tmp -name core -type f -print | xargs /bin/rm -f

       Find  files named core in or below the directory /tmp and delete them.  Note that this will work incorrectly if there are any file‐
       names containing newlines or spaces.

       find /tmp -name core -type f -print0 | xargs -0 /bin/rm -f

       Find files named core in or below the directory /tmp and delete them, processing filenames in such a way  that  file  or  directory
       names containing spaces or newlines are correctly handled.

       find /tmp -depth -name core -type f -delete

       Find files named core in or below the directory /tmp and delete them, but more efficiently than in the previous example (because we
       avoid the need to use fork(2) and exec(2) to launch rm and we don't need the extra xargs process).

       cut -d: -f1 < /etc/passwd | sort | xargs echo

       Generates a compact listing of all the users on the system.

EXIT STATUS
       xargs exits with the following status:

              0      if it succeeds

              123    if any invocation of the command exited with status 1-125

              124    if the command exited with status 255

              125    if the command is killed by a signal

              126    if the command cannot be run

              127    if the command is not found

              1      if some other error occurred.

       Exit codes greater than 128 are used by the shell to indicate that a program died due to a fatal signal.

STANDARDS CONFORMANCE
       As of GNU xargs version 4.2.9, the default behaviour of xargs is not to have a logical end-of-file marker.  POSIX (IEEE Std 1003.1,
       2004 Edition) allows this.

       The  -l  and  -i  options  appear in the 1997 version of the POSIX standard, but do not appear in the 2004 version of the standard.
       Therefore you should use -L and -I instead, respectively.

       The -o option is an extension to the POSIX standard for better compatibility with BSD.

       The POSIX standard allows implementations to have a limit on the size of arguments to the exec functions.  This limit could  be  as
       low as 4096 bytes including the size of the environment.  For scripts to be portable, they must not rely on a larger value.  Howev‐
       er, I know of no implementation whose actual limit is that small.  The --show-limits option can be used to discover the actual lim‐
       its in force on the current system.

BUGS
       It is not possible for xargs to be used securely, since there will always be a time gap between the production of the list of input
       files  and their use in the commands that xargs issues.  If other users have access to the system, they can manipulate the filesys‐
       tem during this time window to force the action of the commands xargs runs to apply to files that you didn't intend.   For  a  more
       detailed  discussion of this and related problems, please refer to the ``Security Considerations'' chapter in the findutils Texinfo
       documentation.  The -execdir option of find can often be used as a more secure alternative.

       When you use the -I option, each line read from the input is buffered internally.   This means that there is an upper limit on  the
       length  of  input line that xargs will accept when used with the -I option.  To work around this limitation, you can use the -s op‐
       tion to increase the amount of buffer space that xargs uses, and you can also use an extra invocation of xargs to ensure that  very
       long lines do not occur.  For example:

       somecommand | xargs -s 50000 echo | xargs -I '{}' -s 100000 rm '{}'

       Here,  the first invocation of xargs has no input line length limit because it doesn't use the -i option.  The second invocation of
       xargs does have such a limit, but we have ensured that it never encounters a line which is longer than it can handle.   This is not
       an ideal solution.  Instead, the -i option should not impose a line length limit, which is why this discussion appears in the  BUGS
       section.  The problem doesn't occur with the output of find(1) because it emits just one filename per line.

REPORTING BUGS
       GNU findutils online help: <https://www.gnu.org/software/findutils/#get-help>
       Report any translation bugs to <https://translationproject.org/team/>

       Report any other issue via the form at the GNU Savannah bug tracker:
              <https://savannah.gnu.org/bugs/?group=findutils>
       General topics about the GNU findutils package are discussed at the bug-findutils mailing list:
              <https://lists.gnu.org/mailman/listinfo/bug-findutils>

COPYRIGHT
       Copyright  ©  1990-2022  Free  Software  Foundation,  Inc.   License  GPLv3+:  GNU  GPL version 3 or later <https://gnu.org/licens‐
       es/gpl.html>.
       This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.

SEE ALSO
       find(1), kill(1), locate(1), updatedb(1), fork(2), execvp(3), locatedb(5), signal(7)

       Full documentation <https://www.gnu.org/software/findutils/xargs>
       or available locally via: info xargs

                                                                                                                                  XARGS(1)
xargs --help

Usage: xargs [OPTION]... COMMAND [INITIAL-ARGS]...
Run COMMAND with arguments INITIAL-ARGS and more arguments read from input.

Mandatory and optional arguments to long options are also
mandatory or optional for the corresponding short option.
  -0, --null                   items are separated by a null, not whitespace;
                                 disables quote and backslash processing and
                                 logical EOF processing
  -a, --arg-file=FILE          read arguments from FILE, not standard input
  -d, --delimiter=CHARACTER    items in input stream are separated by CHARACTER,
                                 not by whitespace; disables quote and backslash
                                 processing and logical EOF processing
  -E END                       set logical EOF string; if END occurs as a line
                                 of input, the rest of the input is ignored
                                 (ignored if -0 or -d was specified)
  -e, --eof[=END]              equivalent to -E END if END is specified;
                                 otherwise, there is no end-of-file string
  -I R                         same as --replace=R
  -i, --replace[=R]            replace R in INITIAL-ARGS with names read
                                 from standard input, split at newlines;
                                 if R is unspecified, assume {}
  -L, --max-lines=MAX-LINES    use at most MAX-LINES non-blank input lines per
                                 command line
  -l[MAX-LINES]                similar to -L but defaults to at most one non-
                                 blank input line if MAX-LINES is not specified
  -n, --max-args=MAX-ARGS      use at most MAX-ARGS arguments per command line
  -o, --open-tty               Reopen stdin as /dev/tty in the child process
                                 before executing the command; useful to run an
                                 interactive application.
  -P, --max-procs=MAX-PROCS    run at most MAX-PROCS processes at a time
  -p, --interactive            prompt before running commands
      --process-slot-var=VAR   set environment variable VAR in child processes
  -r, --no-run-if-empty        if there are no arguments, then do not run COMMAND;
                                 if this option is not given, COMMAND will be
                                 run at least once
  -s, --max-chars=MAX-CHARS    limit length of command line to MAX-CHARS
      --show-limits            show limits on command-line length
  -t, --verbose                print commands before executing them
  -x, --exit                   exit if the size (see -s) is exceeded
      --help                   display this help and exit
      --version                output version information and exit

Please see also the documentation at https://www.gnu.org/software/findutils/.
You can report (and track progress on fixing) bugs in the "xargs"
program via the GNU findutils bug-reporting page at
https://savannah.gnu.org/bugs/?group=findutils or, if
you have no web access, by sending email to <bug-findutils@gnu.org>.
```
