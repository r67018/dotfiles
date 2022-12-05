### hello fish ###
# unable to show greeting message
set fish_greeting

status is-interactive
set is_interactive $status
if [ $is_interactive -eq 0 ]
    set aa ~/aa/cat.txt
    set has_lolcat (which lolcat > /dev/null; echo $status)
    if [ $SHLVL -le 2 ]
        if [ $has_lolcat -eq 0 ]
            lolcat $aa
        else
            cat $aa
        end
    end
end

### set key binding ###
set fish_vi_key_bindings

### color setting ###
set fish_color_command white
set fish_color_comment yellow
set fish_color_quote   green
set fish_color_error   red
set fish_color_end     green
set fish_color_param   cyan

### alias ###
alias :q="exit"
alias ls="ls --color=always"
alias la="ls -lhA"
alias l="ls -1A"
alias sl="ls"
alias grep="grep --color=always"
alias egrep="egrep --color=always"
alias fgrep="fgrep --color=always"
alias less="less -R"
alias vim="nvim"

### environment variables ###
set WHOME /mnt/c/Users/swear
set WDownloads /mnt/c/Users/swear/Downloads
set EDITOR "vim"
set DENO_INSTALL "/home/ryo/.deno"
bass source ~/.cargo/env
# fzf
set FZF_DEFAULT_OPTS "--height=50% --layout=reverse"

### PATH ###
set -x PATH ~/go/bin $PATH
set -x PATH "$DENO_INSTALL/bin" $PATH
set -x PATH ~/dev/bin $PATH
set -x PATH ~/.local/bin $PATH

### set xserver ###
if [ -e /mnt/c/WINDOWS/System32/wsl.exe ]
    export DISPLAY=(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
end

### fzf config ###
set FZF_CTRL_T_COMMAND 'rg --files --hidden --follow --glob "!.git/*"'
set FZF_CTRL_T_OPTS '--preview "bat --color=always --style=header,grid --line-range :100 {}"'

### execute genie ###
# if [ -z $INSIDE_GENIE ]
# #     genie -l
#     genie -s
#     if [ $status -eq 0 ]
#         genie -s
#     end
# end

### activate systemd ###
# if not ps -aux | grep systemd | grep -v grep
#     sudo daemonize /usr/bin/unshare --fork --pid --mount-proc /lib/systemd/systemd --system-unit=basic.target
#     exec nsenter --target (pidof systemd) --all su - $LOGNAME
# end

### execute tmux ###
# execute only first shell
if [ $SHLVL -eq 1 ]
    # attach session
    tmux a -t main
    set tmux_return $status
    # create session if it fail
    if [ $tmux_return -eq 1 ]
        tmux new-session -s main
    end
end

set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin /home/ryo/.ghcup/bin $PATH # ghcup-env
