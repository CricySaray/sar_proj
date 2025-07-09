#!/bin/bash
# 设置你的仓库路径，可根据需要修改
REPO_PATH="/home/cricy/"
# 日志文件路径
LOG_FILE="/home/cricy/log/git_auto_commit.log"
# 切换到仓库目录
cd "$REPO_PATH" || exit
DATE="[$(date +'%Y/%m/%d %H:%M:%S')]"
if [[ -n $(git ls-files --others --exclude-standard) ]]; then
  echo "$DATE : have untracked files, begin add to stage" >> "$LOG_FILE"
  git status -s >> "$LOG_FILE"
  git add --all >> "$LOG_FILE"
else
  echo "$DATE : DONT find untracked files, continue..." >> "$LOG_FILE"
fi

# 检查是否有未提交的变更
if ! git diff --quiet || ! git diff --cached --quiet; then
    # 记录日志
    echo "$DATE : monitor modified files, beginning to add and commit ..." >> "$LOG_FILE"
    echo "$DATE : below is files to add:" >> "$LOG_FILE"
    git status -s >> "$LOG_FILE"

    # 添加所有变更
    echo "$DATE : begin to add --all: " >> "$LOG_FILE"
    git add --all >> "$LOG_FILE"
    
    # 提交变更
    echo "$DATE : begin to commit:" >> "$LOG_FILE"
    git commit -m "Auto commit at $(date +'%Y-%m-%d %H:%M')" >> "$LOG_FILE"
    
    # 推送变更
    echo "$DATE : begin to push to proj/main" >> "$LOG_FILE"
    git push --set-upstream proj main >> "$LOG_FILE"
    
    # 记录成功日志
    echo "$DATE : commit and push successfully" >> "$LOG_FILE"
    echo "$DATE : ----------------------------------" >> "$LOG_FILE"
    echo " " >> "$LOG_FILE"
else
    # 记录无变更日志
    echo "$DATE : No changed files detected" >> "$LOG_FILE"
    echo "$DATE : ----------------------------------" >> "$LOG_FILE"
    echo " " >> "$LOG_FILE"
fi
