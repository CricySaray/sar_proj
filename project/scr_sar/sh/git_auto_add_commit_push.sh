#!/bin/bash
# 设置你的仓库路径，可根据需要修改
REPO_PATH="/home/cricy/"
# 日志文件路径
LOG_FILE="/home/cricy/log/git_auto_commit.log"
# 切换到仓库目录
cd "$REPO_PATH" || exit
if [[ -n $(git ls-files --others --exclude-standard) ]]; then
  echo "have untracked files, begin add to stage" >> "$LOG_FILE"
  git add --all
else
  echo "DONT find untracked files, continue..."
fi

# 检查是否有未提交的变更
if ! git diff --quiet || ! git diff --cached --quiet; then
    # 记录日志
    echo "$(date) : monitor modified files, beginning to add and commit ..." >> "$LOG_FILE"
    echo "$(date) : below is files to add:" >> "$LOG_FILE"
    git status -s >> "$LOG_FILE"

    # 添加所有变更
    echo "$(date) : begin to add --all: " >> "$LOG_FILE"
    git add --all >> "$LOG_FILE"
    
    # 提交变更
    echo "$(date) : begin to commit:" >> "$LOG_FILE"
    git commit -m "Auto commit at $(date +'%Y-%m-%d %H:%M')" >> "$LOG_FILE"
    
    # 推送变更
    echo "$(date) : begin to push to proj/main" >> "$LOG_FILE"
    git push --set-upstream proj main >> "$LOG_FILE"
    
    # 记录成功日志
    echo "$(date) : 提交并推送成功" >> "$LOG_FILE"
    echo "$(date) : ----------------------------------" >> "$LOG_FILE"
    echo " " >> "$LOG_FILE"
else
    # 记录无变更日志
    echo "$(date) : 未检测到变更" >> "$LOG_FILE"
    echo "$(date) : ----------------------------------" >> "$LOG_FILE"
    echo " " >> "$LOG_FILE"
fi
