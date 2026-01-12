alias his 'history'
alias tt 'tree'
# open newest file
alias vn 'vi `ls -t * | head -1`'
# change newest dir
alias cl 'cd `ls -dt */ | head -1`'
alias cl 'ls -td */ >/dev/null && cd "`ls -td */ | head -n 1`" || echo No non-hidden subdirectories available'

setenv sort_big_perlfile "~/scr_sar/perl/sort_big.pl"
setenv icc2ToinvsFile_fix_timing "/simulation/.../pteco2invs.pl"
setenv logv_error_pick_out_file "/simulation/.../file"

alias rp 'realpath'
alias so 'perl $sort_big_perlfile'
alias toinvs 'perl $icc2ToinvsFile_fix_timing'
alias ca 'calibredrv'
alias sum '~/SC5018/PT/last/summary.pl'
alias top 'cd /simulation/arsong/SC5018/PR/flow_from_wcyuan'
alias err 'perl $logv_error_pick_out_file'
alias d 'du -sh'
alias vinvs 'vim ~/.invs_alias.tcl'
alias gp 'grep -rni'
alias ma 'make'
alias open 'xdg-open'
alias bu 'busers'
alias bq 'bqueues'
alias bj 'bjobs -w'
alias invs 'bsub -n 4 -q normal -Is innovus -execute "stty columns 279; stty rows 25; setMultiCpuUsage -localCpu 4; source ~/.invs_alias.tcl"'
alias pt 'bsub -n 4 -q normal -Is pt_shell -x "set_host_options -max_cores 16"'
alias icc 'bsub -n 4 -q normal -Is icc2_shell'
alias tt 'tree'
alias s 'source'
alias t 'lt'
alias lt 'ls -lhtr'
alias tl 'lt'
alias la 'ls -alht'
alias ll 'ls -hl'
alias l 'ls -hlt'
alias p 'pwd'
alias . 'cd ../'
alias .. 'cd ../../'
alias ... 'cd ../../../'
alias .... 'cd ../../../../'
alias ..... 'cd ../../../../../'
alias g 'gvim'
alias v 'vim'
alias vm 'vim Makefile'
alias vc 'vim ~/.cshrc'
alias sc 'source ~/.cshrc'
alias vv 'vim ~/.vimrc'
alias sv 'source ~/.vimrc'
alias vt 'vim ~/.tmux.conf'
alias tm 'tmux'
alias md 'mkdir'
alias c 'cd'
alias cl 'ls -td */ >/dev/null && cd "`ls -td */ | head -n 1`" || echo No non-hidden subdirectories available'
alias lc 'cl'

alias ww 'mkdir -p work ; cd work'


alias setPrompt 'set prompt="%{\e[32m%}%{\e[1m%}[%h]%{\e[0m%} %{\e[31m%}%{\e[1m%}%W/%D %T%{\e[0m%} [%n@%m %{\e[34m%}%/%{\e[0m%}]$ "'
alias cd 'chdir \!* && setPrompt'
setPrompt

setenv teamshare_file '/simulation/arsong/scr_sar/perl/team_share.pl'
alias pop 'perl $teamshare_file -pop'
alias push 'perl $teamshare_file -push'

