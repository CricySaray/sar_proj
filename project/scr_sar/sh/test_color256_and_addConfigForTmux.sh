# The awk command below can detect the color support type of the current terminal. If the colors appear 
# as a smooth gradient, the terminal supports 256 colors. If they show as distinct color blocks with 
# overlapping hues, it does not support 256 colors, and further debugging is required.

awk 'BEGIN{
  s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
  for (colnum=0; colnum<77; colnum++) {
    r=255-(colnum*255/76); g=(colnum*510/76); b=(colnum*255/76);
    if (g>255) g=510-g;
    printf "\033[48;2;%d;%d;%dm",r,g,b;
    printf "\033[38;2;%d;%d;%dm",255-r,255-g,255-b;
    printf "%s\033[0m",substr(s,colnum+1,1);
  } print "";
}'

# When the colors displayed in your tmux terminal differ from those in the native 
# Linux terminal, you can add the following code to the `.tmux.conf` file and then reload tmux.
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
set -g focus-events on
set -g default-command "export TERM=xterm-256color; exec zsh"
