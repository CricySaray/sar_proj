#!/bin/bash
set -e

# env 仅给 cc‑switch 子进程设置中文locale，当前终端环境不受任何改动
exec env \
LANG=zh_CN.UTF-8 \
LC_ALL=zh_CN.UTF-8 \
LANGUAGE="zh_CN:zh:en_US:en" \
cc-switch


