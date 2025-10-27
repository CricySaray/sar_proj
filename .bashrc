#-------------------------------------------------
# some more ls aliases
alias cr='cd ~/project/backend/run'
alias ct='cd ~/project/test_temp/'

alias te='perl ~/project/scr_sar/perl/misc/genTree_basedOnIndentedFile.pl'
alias vte='vim ~/project/scr_sar/perl/misc/genTree_basedOnIndentedFile.pl'

alias fa='perl /home/cricy/project/scr_sar/perl/file_archiver.pl'
alias vfa='vim /home/cricy/project/scr_sar/perl/file_archiver.pl'

alias ef='perl ~/project/scr_sar/perl/encrypt_perlScript.pl'
alias vef='vim ~/project/scr_sar/perl/encrypt_perlScript.pl'

function ww() {
  ca $1
  wn all_$1
}
function ca() {
  filename="$1"
  tclsh ~/project/scr_sar/tcl/misc/cat_all_sourced_file/cat_all.recursive.tcl $filename || return 
  if [[ "$filename" == *.tcl ]]; then 
    target_file="all_$filename"
    sed -i 's/;$//g' $target_file
  fi
}
alias rp='realpath'
alias vwn='vim ~/project/scr_sar/perl/tcl_namespace_wrapper.pl'
alias wn='perl ~/project/scr_sar/perl/tcl_namespace_wrapper.pl'
alias vca='vim ~/project/scr_sar/tcl/misc/cat_all_sourced_file/cat_all.recursive.tcl'
alias fd='fdfind -Is'
alias cs='ca ./fix_trans.invs.tcl'
alias ts='tclsh'
alias tk='touch .gitkeep'; # for updating empty dir to git
alias his='history'
alias bat='batcat'
alias vi='vim .gitignore'
alias vm='vim Makefile'
alias p='pwd'
alias vt='vim ~/.tmux.conf'
alias tm='tmux'
alias vc='vim ~/.cshrc'
alias d='du -sh'
alias vinvs='vim ~/.invs_alias.tcl'
alias vpt='vim ~/.pt_alias.tcl'
alias gp='grep -rni'
alias ma='make'
alias open='xdg-open'
alias md='mkdir -p'
alias tt='tree'
alias s='source'
alias v='vim'
alias bv='vim -esnc' # vim on batch mode
# usage of bv, for example:
# > bv 'argdo g/test/d|update' -c 'q' an*
# It can batch delete all lines containing the "test" character in files with the "an*" pattern. 
# Then, use the `update` command to save the modified files, and finally exit the editor with a 
# single `q` command. Note that the `q` command must be written separately in a `-c` option.
alias vv='vim ~/.vimrc'
alias sv='source ~/.vimrc'
alias vb='vim ~/.bashrc'
alias sb='source ~/.bashrc'
alias lt='ls -lthr'
alias tl='lt -lthr'
alias t='lt -lthr'
alias ll='ls -alF'
alias la='ls -alhr'
alias l='ls -CF'
alias .='cd ..'
alias ..='cd ../../'
alias ...='cd ../../../'
alias ....='cd ../../../../'

alias pop='perl ~/project/scr_sar/perl/teamshare.pl -pop'
alias push='perl ~/project/scr_sar/perl/teamshare.pl -push'

#------------------------------------------------
# config for attr (manage filesystem, add attribute info for files)
alias sf='setfattr'
alias gf='getfattr'

#------------------------------------------------
# config for python3
export PYTHON_HOME=/usr/bin/python3
export PATH=$PYTHON_HOME/bin:$PATH

export PERL5LIB=/usr/local/lib/x86_64-linux-gnu/perl/5.34.0:$PERL5LIB

#------------------------------------------------
# config for autojump (github : wting/autojump)
[[ -s /home/cricy/.autojump/etc/profile.d/autojump.sh ]] && source /home/cricy/.autojump/etc/profile.d/autojump.sh


#------------------------------------------------
# vim + fdfind
# 使用fdfind搜索文件并通过vim打开
function vf() {
  if [[ $# -eq 0 ]]; then
    local search_dir="/home/cricy/"
    local search_term=""
  elif [[ $# -eq 1 ]]; then
    local search_dir="$1"
    local search_term=""
  fi
  local file=$(fdfind --type f ${search_term:+.} -H -E '.git' "$search_term" "$search_dir" 2>/dev/null | \
               fzf --preview 'bat --style=numbers --color=always {} 2>/dev/null')
  if [[ -n "$file" ]]; then
    vim "$file"
  fi
}

#------------------------------------------------
# cd + fdfind
# 使用fdfind搜索目录并直接cd跳转
alias r='cdf'
alias cc='cdf'
function cdf() {
# 使用fdfind搜索文件并通过vim打开
  if [[ $# -eq 0 ]]; then
    local search_dir="$HOME"
    local search_term=""
  else
    local search_dir="$1"
    local search_term="$2"
  fi
  local selected_dir=$(fdfind --type d ${search_term:+~} -H -E '.git' "$search_term" "$search_dir" 2>/dev/null | \
                      fzf --preview 'tree -L 2 {} 2>/dev/null' --height=35%)
  if [[ -n "$selected_dir" ]]; then
    cd "$selected_dir" || return
    pwd  # 可选：显示当前目录
  fi
  # 检查 autojump 是否可用
  if ! command -v autojump &> /dev/null; then
    echo "autojump not found. Directory not recorded." >&2
    return 1
  fi
  # 记录当前目录到 autojump 数据库
  if ! autojump -a "$PWD"; then
    echo "Failed to add directory to autojump database." >&2
    return 1
  fi
  autojump --purge &> /dev/null
  return 0
}

#------------------------------------------------
# cd + fdfind
# 在 ~/.bashrc 文件中添加或修改以下内容
function c() {
  # 使用内置的 cd 命令
  builtin cd "$@" || return 1
  # 检查 autojump 是否可用
  if ! command -v autojump &> /dev/null; then
    echo "autojump not found. Directory not recorded." >&2
    return 1
  fi
  # 记录当前目录到 autojump 数据库
  if ! autojump -a "$PWD"; then
    echo "Failed to add directory to autojump database." >&2
    return 1
  fi
  autojump --purge &> /dev/null
  return 0
}
alias c='c'


#------------------------------------------------
# change newest dir
# 进入最新修改的文件夹（支持层数参数和忽略列表）
alias cl='lc'
lc() {
  local depth="${1:-1}"         # 默认层数为1
  local current_dir="$(pwd)"
  local target_dir=""
  local found=false
  # 定义要忽略的文件夹列表（可自定义）
  local ignore_list=("log" "test_temp" "backup")
  # 检查参数是否为正整数
  if ! [[ "$depth" =~ ^[0-9]+$ ]]; then
    echo "Error: Please provide a positive integer argument" >&2
    return 1
  fi
  # 执行指定层数的递归
  for ((i=1; i<=depth; i++)); do
    # 查找当前目录下最新的子目录（排除忽略列表中的文件夹）
    target_dir=$(ls -dt */ 2>/dev/null | grep -vE "^($(IFS="|"; echo "${ignore_list[*]}"))/" | head -1)
    if [[ -z "$target_dir" ]]; then
      echo "Cannot proceed: No deeper subdirectories found"
      break
    fi
    # 进入最新的子目录
    cd "$target_dir" || return 1
    echo "[$i] Entered: $(pwd)"
    found=true
  done
  # 如果未找到任何子目录，输出提示
  if ! $found; then
    echo "No subdirectories found!" >&2
    cd "$current_dir" || return 1
    return 1
  fi
}
# vn：打开当前目录下最新的文件。
# vn ~/projects：打开 ~/projects 目录下最新的文件。
# vn . 3：递归查找当前目录下 3 层深度内的最新文件。
vn() {
  local dir="${1:-.}"           # 默认搜索当前目录，可指定路径
  local max_depth="${2:-1}"     # 默认不递归，可指定递归深度
  local ignore_dirs=("log" "temp")
  local ignore_filter=""
  # 构建忽略过滤器，只包含存在于搜索路径中的文件夹
  for ignore_dir in "${ignore_dirs[@]}"; do
    if [[ -d "$dir/$ignore_dir" ]]; then
      ignore_filter+=" -not -path '*/$ignore_dir/*'"
    fi
  done
  # 查找最新文件
  local cmd="find '$dir' -maxdepth $max_depth -type f $ignore_filter -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-"
  local newest_file=$(eval "$cmd")
  if [[ -n "$newest_file" ]]; then
    vim "$newest_file"
  else
    echo "No files found in $dir!" >&2
    return 1
  fi
}

#------------------------------------------------
# GIT alias 
alias vg='vim ~/.gitconfig'
alias gs='git status -s'
alias gpu='g p'
# 在.bashrc或.zshrc中添加
if [ -f /usr/share/bash-completion/completions/git ]; then
  source /usr/share/bash-completion/completions/git
fi
# 启用命令补全 using bash-completion tool
alias g='git'
__git_complete g __git_main  # 使g命令也支持补全

#------------------------------------------------
# config proxy
#alias proxy='export all_proxy=http://192.168.5.98:7897'
#alias unproxy='unset all_proxy'

#------------------------------------------------
# export vars
export DISPLAY=255.255.255.252

#------------------------------------------------
# - fzf command config:
# -- Customizing fzf options for completion
# Use ~~ as the trigger sequence instead of the default **
export FZF_COMPLETION_TRIGGER='~~'
# Options to fzf command
export FZF_COMPLETION_OPTS='--border --info=inline'
# Options for path completion (e.g. vim **<TAB>)
export FZF_COMPLETION_PATH_OPTS='--walker file,dir,follow,hidden'
# Options for directory completion (e.g. cd **<TAB>)
export FZF_COMPLETION_DIR_OPTS='--walker dir,follow'
# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments ($@) to fzf.
_fzf_comprun() {
  local command=$1
  shift
  case "$command" in
    cd)           fzf --preview 'tree -C {} | head -200'   "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
  esac
}
# -- Customizing completion source for paths and directories
# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}
# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}


#--------------------------------------------------
# default config when install

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
source "$HOME/.cargo/env"
. "$HOME/.cargo/env"


#-------------------------------------------------
# command line status : prompt setting

# Git 状态检查函数
function parse_git_status() {
    # 检查是否在 Git 仓库中
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return ""
    fi
    local GIT_STATUS=""
    local BRANCH=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    # 检查是否有未提交的修改
    if ! git diff --no-ext-diff --quiet --exit-code; then
        GIT_STATUS+="\[\e[31m\]✗\[\e[0m\]"  # 红色叉号表示有未暂存修改
    fi
    # 检查是否有已暂存但未提交的文件
    if ! git diff --no-ext-diff --cached --quiet --exit-code; then
        GIT_STATUS+="\[\e[33m\]+\[\e[0m\]"  # 黄色加号表示有已暂存文件
    fi
    # 检查本地提交是否领先于远程
    local UPSTREAM=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    if [ -n "$UPSTREAM" ]; then
        local AHEAD=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
        if [ "$AHEAD" -gt 0 ]; then
            GIT_STATUS+="\[\e[32m\]↑${AHEAD}\[\e[0m\]"  # 绿色箭头表示有未推送提交
        fi
    fi
    # 如果有状态，添加分支名并用括号包裹
    if [ -n "$GIT_STATUS" ]; then
        echo " (\[\e[36m\]${BRANCH}\[\e[0m\]${GIT_STATUS})"
    else
        echo " (\[\e[36m\]${BRANCH}\[\e[0m\])"
    fi
}
precmd() {
    # 根据上一次命令执行状态设置颜色
    if [ $? -eq 0 ]; then
        STATUS_COLOR="\[\e[32m\]"  # 绿色（成功）
    else
        STATUS_COLOR="\[\e[31m\]"  # 红色（失败）
    fi
    # 设置PS1（包含命令计数、时间和执行状态颜色）
    PS1="${STATUS_COLOR}[\#]\u \[\e[1m\]\D{%Y/%m/%d} \A\[\e[0m\]$(parse_git_status) \[\e[34m\]\[\e[1m\]\w\[\e[0m\] \$ "
}
PROMPT_COMMAND=precmd
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ;} history -a"
