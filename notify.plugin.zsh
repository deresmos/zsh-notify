# vim: set nowrap filetype=zsh:
# 
# See README.md.

fpath=($fpath $(dirname $0:A))
zstyle ':notify:*' resources-dir $(dirname $0:A)/resources
zstyle ':notify:*' window-pid $WINDOWID

test -z "$_ZSH_NOTIFY_ROOT_PPID" && export _ZSH_NOTIFY_ROOT_PPID="$PPID"
zstyle ':notify:*' parent-pid $_ZSH_NOTIFY_ROOT_PPID

# Notify of an error with no regard to the time elapsed (but always only
# when the terminal is in background).
function notify-error {
    local time_elapsed 
    time_elapsed=$1

    terminal-is-active || zsh-notify error "$time_elapsed" < /dev/stdin &!
}

# Notify of successful command termination, but only if it took more than
# the timeout set with command-complete-timeout, and only if the terminal
# is in background).
function notify-success() {
    local time_elapsed command_complete_timeout

    time_elapsed=$1

    zstyle -s ':notify:' command-complete-timeout command_complete_timeout \
        || command_complete_timeout=30

    if (( $time_elapsed > $command_complete_timeout )); then
        terminal-is-active || zsh-notify success "$time_elapsed" < /dev/stdin &!
    fi
}

# Notify about the last command's success or failure.
function notify-command-complete() {
    last_status=$?

    local now time_elapsed error_log

    zstyle -s ':notify:' error-log error_log \
      || error_log=/dev/stderr

    (
      if [[ -n $start_time ]]; then
        now=`date "+%s"`
        (( time_elapsed = $now - $start_time ))
        if [[ $last_status -gt "0" ]]; then
            notify-error "$time_elapsed" <<< $last_command
        elif [[ -n $start_time ]]; then
            notify-success "$time_elapsed" <<< $last_command
        fi
      fi
    ) | sed 's/^/zsh-notify: /' 1> "$error_log" 2>&1

    unset last_command last_status start_time
}

function store-command-stats() {
    last_command="$1"
    start_time=`date "+%s"`
}

autoload add-zsh-hook
autoload -U zsh-notify
autoload -U terminal-is-active
add-zsh-hook preexec store-command-stats
add-zsh-hook precmd notify-command-complete
