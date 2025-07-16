#-------------------------------------------------
# some more ls aliases
alias cr='cd ~/project/backend/run'
alias ct='cd ~/project/test_temp/'

alias cs='tclsh cat_all.tcl'
alias ts='tclsh'
alias tk='touch .gitkeep'; # for updating empty dir to git
alias his='history'
alias bat='batcat'
alias fd='find ./ -type f -name '
alias vi='vim .gitignore'
alias vm='vim Makefile'
alias p='pwd'
alias vt='vim ~/.tmux.conf'
alias tm='tmux'
alias vc='vim ~/.cshrc'
alias d='du -sh'
alias vinvs='vim ~/.invs_alias.tcl'
alias gp='grep -rni'
alias ma='make'
alias open='xdg-open'
alias md='mkdir -p'
alias tt='tree'
alias s='source'
alias v='vim'
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
alias c='cd'
alias .='cd ..'
alias ..='cd ../../'
alias ...='cd ../../../'
alias ....='cd ../../../../'

alias pop='perl ~/project/scr_sar/perl/teamshare.pl -pop'
alias push='perl ~/project/scr_sar/perl/teamshare.pl -push'

#------------------------------------------------
# change newest dir
# 进入最新修改的文件夹（支持层数参数）
lc() {
  local depth="${1:-1}"  # 默认层数为1
  local current_dir="$(pwd)"
  local target_dir=""
  local found=false
  # 检查参数是否为正整数
  if ! [[ "$depth" =~ ^[0-9]+$ ]]; then
    echo "songError: Please provide a positive integer!" >&2
    return 1
  fi
  # 执行指定层数的递归
  for ((i=1; i<=depth; i++)); do
    # 查找当前目录下最新的子目录
    target_dir=$(ls -dt */ 2>/dev/null | head -1)
    if [[ -z "$target_dir" ]]; then
      echo "Unable to continue: No deeper subdirectories"
      break
    fi
    # 进入最新的子目录
    cd "$target_dir" || return 1
    echo "[$i] Enter Directory: $(pwd)"
    found=true
  done
  # 如果未找到任何子目录，输出提示
  if ! $found; then
    echo "No directory was found" >&2
    cd "$current_dir" || return 1
    return 1
  fi
}

#------------------------------------------------
# GIT alias 
alias vg='vim ~/.gitconfig'
# 在.bashrc或.zshrc中添加
if [ -f /usr/share/bash-completion/completions/git ]; then
  source /usr/share/bash-completion/completions/git
fi
# 启用命令补全 using bash-completion tool
alias g='git'
__git_complete g __git_main  # 使g命令也支持补全

#------------------------------------------------
# config proxy
alias proxy='export all_proxy=http://192.168.5.4:7897'
alias unproxy='unset all_proxy'

#------------------------------------------------
# export vars
export DISPLAY=172.23.112.1:0

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

