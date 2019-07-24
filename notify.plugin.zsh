# vim: set nowrap filetype=zsh:
# 
# See README.md.
#
fpath=($fpath $(dirname $0:A))

zstyle ':notify:*' resources-dir $(dirname $0:A)/resources
zstyle ':notify:*' window-pid $WINDOWID

test -z "$_ZSH_NOTIFY_ROOT_PPID" && export _ZSH_NOTIFY_ROOT_PPID="$PPID"
zstyle ':notify:*' parent-pid $_ZSH_NOTIFY_ROOT_PPID

function notify {
  local _type time_elapsed command_timeout

  _type=$1
  time_elapsed=$2
  command_timeout=$3

  if (( $time_elapsed < $command_timeout )); then
      return
  fi

  if [[ "$_type" == 'success' ]]; then
      notify-if-background success "$time_elapsed" < /dev/stdin &!
  elif [[ "$_type" == 'error' ]]; then
      notify-if-background error "$time_elapsed" < /dev/stdin &!
  fi
}

# Notify of failed command termination, but only if it took at least
# 0 seconds (and if the terminal is in background).
function notify-error {
    local time_elapsed command_error_timeout

    time_elapsed=$1
    zstyle -s ':notify:' command-error-timeout command_error_timeout \
        || command_error_timeout=0

    notify "error" "$time_elapsed" "$command_error_timeout" < /dev/stdin &!
}

# Notify of successful command termination, but only if it took at least
# 30 seconds (and if the terminal is in background).
function notify-success() {
    local time_elapsed command_success_timeout ignore_commands

    zstyle -s ':notify:' ignore-success-command ignore_commands \
        || ignore_commands=''

    # Check ignore command
    for ignore_command in $ignore_commands; do
        regex="${ignore_command}*"
        if [[ "$last_command" =~ $regex ]]; then
            return
        fi
    done

    time_elapsed=$1
    zstyle -s ':notify:' command-success-timeout command_success_timeout \
        || command_success_timeout=30

    notify "success" "$time_elapsed" "$command_success_timeout" < /dev/stdin &!
}

# Notify about the last command's success or failure.
function notify-command-complete() {
    last_status=$?

    local now time_elapsed

    if [[ -n $start_time ]]; then
      now=`date "+%s"`
      ((time_elapsed = $now - $start_time ))
      if [[ $last_status -gt "0" ]]; then
          notify-error "$time_elapsed" <<< $last_command
      elif [[ -n $start_time ]]; then
          notify-success "$time_elapsed" <<< $last_command
      fi
    fi
    unset last_command last_status start_time
}

function store-command-stats() {
    last_command=$1
    start_time=`date "+%s"`
}

autoload add-zsh-hook
autoload -U notify-if-background
add-zsh-hook preexec store-command-stats
add-zsh-hook precmd notify-command-complete
