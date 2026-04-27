#!/bin/bash

# 功能：当前目录及所有子目录 文件批量替换字符串 + 保留文件时间戳
# 用法：chmod +x replace_all_keep_time.sh && ./replace_all_keep_time.sh

# ====================== 直接在这里修改 ======================
OLD_STR="sar song"
NEW_STR="aiden song"
# ============================================================

echo -e "\n开始处理当前目录及所有子目录中的所有文件...\n"

# 遍历当前目录 + 所有子目录 所有文件
find . -type f | while read -r FILE; do
    # 跳过本脚本自己，避免把脚本内容改坏
    if [[ "$FILE" == "$0" ]]; then
        continue
    fi

    # 保存文件原始时间戳
    MTIME=$(stat -c %y "$FILE")

    # 执行替换（使用 | 作为分隔符，支持路径、斜杠等字符）
    sed -i "s|${OLD_STR}|${NEW_STR}|g" "$FILE" 2>/dev/null

    # 恢复时间戳
    touch -d "$MTIME" "$FILE"

    echo "✅ 已处理: $FILE"
done

echo -e "\n🎉 全部处理完成！文件时间戳均保持不变。"
