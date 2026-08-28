# Rsync 命令全面使用指南

`rsync` 是Linux系统自带的高效文件复制工具，支持本地复制、远程服务器复制、增量备份、目录同步等多种场景，具备灵活的过滤规则和元数据保留能力。本文档总结了`rsync`的常用选项和常见使用场景。

## 一、常用选项速查表

| 完整选项          | 简写 | 用途说明                                                                 | 常用场景                     |
|-------------------|------|--------------------------------------------------------------------------|------------------------------|
| `--verbose`       | `-v` | 输出详细的执行信息，显示复制的文件和统计数据                               | 调试复制过程，确认哪些文件被复制 |
| `--archive`       | `-a` | 归档复制模式，等价于 `-rlptgoD`，递归复制+保留所有元数据（权限、时间戳、所有者、组、设备文件、特殊文件） | 最常用的完整备份场景，保留文件完整属性 |
| `--recursive`     | `-r` | 递归复制目录内容，不保留元数据                                           | 简单递归复制目录，不需要保留权限/时间戳 |
| `--links`         | `-l` | 保留符号链接文件，不会复制成实际文件                                       | 复制包含软链接的目录          |
| `--perms`         | `-p` | 保留文件权限信息（如`chmod`设置的权限）                                     | 需要严格保留文件权限的场景    |
| `--times`         | `-t` | 保留文件的修改时间戳                                                     | 增量备份时判断文件是否更新    |
| `--group`         | `-g` | 保留文件的所属组信息                                                     | 多用户环境下的完整备份        |
| `--owner`         | `-o` | 保留文件的所有者信息（需要root权限）                                     | 系统级别的完整备份            |
| `--devices`       | `-D` | 保留设备文件（需要root权限）                                             | 复制系统设备文件的备份        |
| `--specials`      | `-D` | 保留特殊文件（如FIFO管道）                                               | 复制包含特殊文件的目录        |
| `--compress`      | `-z` | 传输时压缩数据，减少带宽使用                                             | 远程复制大文件，或者网络带宽有限的场景 |
| `--progress`      | `-P` | 显示单个文件的传输进度，等价于 `--partial --progress`                     | 复制大文件时查看进度          |
| `--partial`       | 无   | 保留未完成传输的文件，支持断点续传                                       | 网络不稳定时的大文件复制      |
| `--exclude=PATTERN` | 无 | 排除匹配通配符的文件/目录，比如 `--exclude="*.log"`                        | 复制时跳过指定类型的文件      |
| `--exclude-from=FILE` | 无 | 从指定文件中读取排除规则，每行一个模式                                   | 需要排除大量文件的场景        |
| `--include=PATTERN` | 无 | 包含匹配通配符的文件/目录，和 `--exclude` 配合使用（先包含再排除）         | 只复制特定类型的文件，比如只复制`.jpg`和`.png` |
| `--dry-run`       | `-n` | 不实际执行复制，只预览会发生的操作                                       | 测试复制规则是否正确          |
| `--update`        | `-u` | 只复制比目标文件更新的文件，或者不存在的文件                               | 增量备份，避免覆盖更新的文件  |
| `--delete`        | 无   | 删除目标目录中多余的文件（让目标目录和源目录完全一致）                     | 同步两个目录，确保目标和源完全相同 |
| `--human-readable`| `-h` | 以人类可读的格式显示文件大小（如KB、MB）                                   | 查看传输统计时更直观          |
| `--checksum`      | `-c` | 基于文件的checksum而不是时间戳/大小来判断是否需要复制                     | 当时间戳不可靠时的精确复制    |
| `--rsh=COMMAND`   | `-e` | 指定远程shell程序，默认是ssh，比如 `-e ssh` 或者 `-e "ssh -p 2222"`        | 远程服务器之间的文件复制      |
| `--quiet`         | `-q` | 静默模式，只输出错误信息，不输出正常的复制日志                           | 脚本中使用rsync，避免多余输出 |
| `--no-perms`      | 无   | 不保留文件权限（和`--archive`配合使用，取消`-p`选项）                   | 共享目录复制，不需要严格权限  |

## 二、常见使用场景示例

### 1. 基础本地目录完整复制（保留所有元数据）
最常用的场景，复制目录并保留文件的所有属性（权限、时间戳、所有者等）：
```bash
# 复制 /home/user/docs 目录内的所有内容到 /backup/docs
rsync -av /home/user/docs/ /backup/docs/
```
> 注意：源目录末尾的`/`表示复制目录内的内容，而非复制整个`docs`目录到目标下。如果省略`/`，则会将`docs`目录本身复制到`/backup`下，最终路径为`/backup/docs/docs`。

### 2. 简单递归复制目录（不保留元数据）
快速复制目录，不需要保留原有文件属性：
```bash
# 递归复制 /home/user/temp 目录到 /tmp/temp_copy
rsync -r /home/user/temp/ /tmp/temp_copy/
```

### 3. 远程服务器文件复制
支持本地和远程服务器之间的文件/目录复制，默认使用SSH作为传输通道：
```bash
# 本地文件复制到远程服务器
rsync -av /local/file.txt user@remote_host:/remote/path/

# 从远程服务器复制文件到本地
rsync -av user@remote_host:/remote/file.txt /local/path/

# 复制远程整个目录到本地
rsync -av user@remote_host:/remote/docs/ /local/backup/
```
> 提示：为了避免每次输入密码，建议配置SSH密钥对认证。

### 4. 排除特定文件/目录的复制
跳过不需要复制的文件或目录：
```bash
# 复制 /home/user 到 /backup/home，排除所有.log日志文件和temp临时目录
rsync -av --exclude="*.log" --exclude="temp/" /home/user/ /backup/home/
```
> 可以多次使用`--exclude`来排除多个不同的模式，目录排除建议加上末尾的`/`以精确匹配目录。

### 5. 从文件读取排除规则
当需要排除大量文件时，将排除规则写入文件统一管理：
```bash
# 1. 创建排除规则文件
cat > exclude_list.txt << 'EOF'
*.log
temp/
*.tmp
.git/
node_modules/
EOF

# 2. 使用exclude-from加载排除规则
rsync -av --exclude-from=exclude_list.txt /home/user/docs/ /backup/docs/
```

### 6. 只复制特定类型的文件
通过包含和排除规则组合，只复制需要的文件类型：
```bash
# 只复制.jpg和.png图片文件，排除其他所有文件
rsync -av --include="*.jpg" --include="*.png" --exclude="*" /home/user/photos/ /backup/photos/
```
> 注意：规则顺序很重要，先包含需要的文件类型，再排除所有其他文件，否则包含规则会被覆盖。

### 7. 增量备份（只复制更新的文件）
只复制比目标文件更新的文件，或者新增的文件，适合做增量备份：
```bash
# 增量备份 /home/user/docs 到 /backup/docs
rsync -avu /home/user/docs/ /backup/docs/
```
> `-u`选项会跳过目标目录中已经存在且比源文件更新的文件，避免覆盖已经被修改的文件。

### 8. 同步两个目录（镜像备份）
让目标目录和源目录完全一致，删除目标中多余的文件：
```bash
# 同步 /var/www/html 到 /backup/www，删除目标中不存在于源的文件
rsync -av --delete /var/www/html/ /backup/www/
```
> ⚠️ 警告：`--delete`会永久删除目标目录中的多余文件，使用前一定要先通过`-n`选项预览效果：`rsync -avn --delete /var/www/html/ /backup/www/`。

### 9. 断点续传大文件
即使传输中断，下次执行同一命令可以继续传输未完成的文件：
```bash
# 复制大文件到远程服务器，支持断点续传并显示进度
rsync -avP /large/file.iso user@remote_host:/remote/path/
```
> `-P`等价于`--partial --progress`，会保留未完成的传输文件并显示实时进度。

### 10. 预览复制操作（不实际执行）
在实际执行复制前预览会发生的操作，避免误操作：
```bash
# 预览排除.log文件后的复制结果
rsync -avn --exclude="*.log" /home/user/docs/ /backup/docs/
```
> `-n`选项只会输出将要执行的操作，不会实际修改任何文件。

### 11. 显示传输进度
查看每个文件的传输速度、剩余时间等进度信息：
```bash
# 复制大文件目录并显示实时进度
rsync -av --progress /home/user/large_files/ /backup/large_files/
```

### 12. 压缩传输减少带宽使用
在网络带宽有限的场景下，压缩传输数据以加快速度：
```bash
# 远程复制目录时启用压缩
rsync -avz /large/directory/ user@remote_host:/backup/directory/
```

### 13. 保留符号链接
复制时保留软链接本身，而不是复制链接指向的实际文件：
```bash
# 复制包含软链接的目录，保留所有符号链接
rsync -avl /home/user/links/ /backup/links/
```
> 默认情况下rsync会复制软链接指向的实际文件，使用`-l`选项可以保留软链接本身。

### 14. 脚本中静默使用rsync
在shell脚本中使用rsync，只输出错误信息，避免多余的日志输出：
```bash
# 静默备份目录，只有发生错误时才会输出信息
rsync -aq /home/user/docs/ /backup/docs/
```

### 15. 使用非默认SSH端口复制
当远程服务器使用非标准SSH端口时，指定端口进行复制：
```bash
# 使用端口2222复制文件到远程服务器
rsync -av -e "ssh -p 2222" /local/file.txt user@remote_host:/remote/path/
```

## 三、额外技巧与注意事项
1.  **目录末尾的`/`规则**：
    - 源目录末尾加`/`：复制目录内的所有内容到目标目录
    - 源目录末尾不加`/`：复制整个目录本身到目标目录（会创建子目录）
2.  **权限限制**：普通用户使用`-o`（保留所有者）时，只能保留自己拥有的文件的所有者信息，系统级备份需要root权限。
3.  **`--delete`的安全使用**：永远先使用`-n`预览`--delete`的效果，避免误删重要文件。
4.  **checksum模式**：`-c`选项会基于文件的MD5/SHA1校验和来判断是否需要复制，适合跨文件系统复制时时间戳不可靠的场景，但会消耗更多CPU资源。
5.  **远程复制的性能优化**：对于大文件传输，可以结合`-z`压缩和`-P`断点续传，同时使用`--block-size=SIZE`调整传输块大小以优化性能。
6.  **查看完整文档**：可以通过`man rsync`或`rsync --help`查看所有选项的详细说明。