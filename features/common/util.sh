H_RESET=$'\033[0m'
H_BLACK=$'\033[0;30m'
H_BLACK_BOLD=$'\033[1;30m'
H_RED=$'\033[0;31m'
H_RED_BOLD=$'\033[1;31m'
H_GREEN=$'\033[0;32m'
H_YELLOW=$'\033[0;33m'
H_BLUE=$'\033[0;34m'

h_is_util_sourced() {
  return 0
}

h_on_unset_util() {
  unset -v H_RESET
  unset -v H_BLACK
  unset -v H_BLACK_BOLD
  unset -v H_RED
  unset -v H_RED_BOLD
  unset -v H_GREEN
  unset -v H_YELLOW
  unset -v H_BLUE
}

h_is_verbose() {
  [ -n "$H_VERBOSE" ]
}

h_is_bash() {
  [ -n "$BASH_VERSION" ]
}

h_is_zsh() {
  [ -n "$ZSH_VERSION" ]
}

h_is_linux() {
  [[ "$(uname -s)" == 'Linux' ]]
}

h_is_mac() {
  [[ "$(uname -s)" == 'Darwin' ]]
}

h_is_func_declared() {
  #declare -F "$1" > /dev/null # This works only in Bash.
  declare -f "$1" > /dev/null # This works in both Bash and Zsh.
  # In Bash and Zsh, typeset is exactly the same as declare, but considered obsolete.
  #typeset -F "$1" > /dev/null # This works only in Bash.
  #typeset -f "$1" > /dev/null # This works in both Bash and Zsh.
}

h_is_sourced() {
  h_is_func_declared "h_is_$1_sourced"
}

h_is_whitespace() {
  [[ "$1" == ' ' || "$1" == $'\t' || "$1" == $'\n' ]]
}

h_echo() {
  echo "$@"
}

h_debug() {
  h_is_verbose || return 0
  [[ "$1" == '-t' ]] && { h_echo -n "${H_GREEN}debug${H_RESET}: "; shift; }
  h_echo "$@"
}

h_info() {
  [[ "$1" == '-t' ]] && { h_echo -n "${H_BLUE}info${H_RESET}: "; shift; }
  h_echo "$@"
}

h_warn() {
  [[ "$1" == '-t' ]] && { >&2 h_echo -n "${H_YELLOW}warning${H_RESET}: "; shift; }
  >&2 h_echo "$@"
}

h_error() {
  [[ "$1" == '-t' ]] && { >&2 h_echo -n "${H_RED_BOLD}error${H_RESET}: "; shift; }
  >&2 h_echo "$@"
}

h_command_by_pid() {
  ps -p "$1" | tail -1 | awk '{ print $4 }'
}

h_shell_by_pid() {
  local cmd
  cmd="$(h_command_by_pid "$1")"
  if [[ "${cmd:0:1}" == '-' ]]; then
    basename "${cmd:1}"
  else
    basename "$cmd"
  fi
}

h_default_shell() {
  basename "$SHELL"
}

h_current_shell() {
  h_shell_by_pid "$$"
}

h_parent_shell() {
  h_shell_by_pid "$PPID"
}

h_is_interactive_shell() {
  if h_is_zsh; then
    setopt | grep '^interactive$' > /dev/null
  else
    case "$-" in
      *i*) return 0 ;;
      *) return 1 ;;
    esac
  fi
}

h_is_login_shell() {
  if h_is_bash; then
    shopt -q 'login_shell'
  elif h_is_zsh; then
    setopt | grep '^login$' > /dev/null
  else
    return 2
  fi
}

h_is_login_shell_by_pid() {
  [[ "$(h_command_by_pid "$1")" == -* ]] || \
  ps -p "$1" | grep -E -- ' -[^ ]*l[^ ]* | -[^ ]*l[^ ]*$| --login | --login$' > /dev/null
}

# If null fields don't exist, h_split, h_split_trim_ws, h_split_trim, and h_split_raw will have the same behavior.
# Otherwise, In Bash h_split and h_split_trim_ws, In Zsh h_split and h_split_raw will have the same behavior.
# NOTE: Thus, if separator is whitespace and null fields exist, h_split will behave in a different way in Bash and Zsh, so h_split must not be used.
h_split() {
  if [ -z "$2" ]; then
    eval "$3"='()'
  elif h_is_zsh; then
    if [[ "$1" == '/' ]]; then
      eval "$3"='("${(@s:'"$1"':)2}")'
    else
      eval "$3"='("${(@s/'"$1"'/)2}")'
    fi
  else
    #IFS="$1" read -ra "$3" <<< "$2" # This reads only the first item delimited by newline.
    IFS="$1" read -rd '' -a "$3" < <(echo -n "$2$1"; echo -ne '\0')
  fi
}

h_split_trim_ws() {
  h_split "$@" || return
  if h_is_zsh && h_is_whitespace "$1"; then
    h_trim_array "$3"
  fi
}

h_split_trim() {
  h_split "$@" || return
  if h_is_zsh; then
    h_trim_array "$3"
  else
    if ! h_is_whitespace "$1"; then
      h_trim_array "$3"
    fi
  fi
}

h_split_raw() {
  if h_is_zsh; then
    h_split "$@"
  else
    if [ -z "$2" ]; then
      eval "$3"='()'
      return
    fi

    local _elem
    eval "$3"='()'
    while IFS= read -rd "$1" _elem; do
      eval "$3"+="('$_elem')"
    done < <(echo -n "$2$1")
  fi
}

h_join_array() {
  local IFS="$1"
  eval h_echo '"${'"$2"'[*]}"'
}

h_join_elems() {
  local IFS="$1"
  shift
  h_echo "$*"
}

h_in_array() {
  local _target="$1" _elem
  eval set -- '"${'"$2"'[@]}"'
  for _elem in "$@"; do
    [[ "$_elem" == "$_target" ]] && return 0
  done
  return 1
}

h_in_elems() {
  local target="$1" elem
  shift
  for elem in "$@"; do
    [[ "$elem" == "$target" ]] && return 0
  done
  return 1
}

h_delete_one_array() {
  local _target="$1" _name="${3:-$2}" _elem _deleted=''
  eval set -- '"${'"$2"'[@]}"'
  eval "$_name"='()'
  for _elem in "$@"; do
    if [[ -n "$_deleted" || "$_elem" != "$_target" ]]; then
      eval "$_name"+="('$_elem')"
    else
      _deleted='true'
    fi
  done
}

h_delete_all_array() {
  local _target="$1" _name="${3:-$2}" _elem
  eval set -- '"${'"$2"'[@]}"'
  eval "$_name"='()'
  for _elem in "$@"; do
    if [[ "$_elem" != "$_target" ]]; then
      eval "$_name"+="('$_elem')"
    fi
  done
}

h_trim_array() {
  h_delete_all_array '' "$1" "$2"
}

h_dedup_array() {
  local _name="${2:-$1}" _elem
  eval set -- '"${'"$1"'[@]}"'
  eval "$_name"='()'
  for _elem in "$@"; do
    if ! h_in_array "$_elem" "$_name"; then
      eval "$_name"+="('$_elem')"
    fi
  done
}

h_diff_array() {
  local _name2="$2" _name3="${3:-$1}" _elem
  eval set -- '"${'"$1"'[@]}"'
  eval "$_name3"='()'
  for _elem in "$@"; do
    if ! h_in_array "$_elem" "$_name2"; then
      eval "$_name3"+="('$_elem')"
    fi
  done
}

h_repeat() {
  local i out
  for ((i == 0; i < $2; ++i)); do
    out+="$1"
  done
  h_echo "$out"
}

h_which() {
  if h_is_zsh; then
    whence -p "$@"
  else
    which "$@"
  fi
}

h_md5() {
  local line
  if h_which md5 > /dev/null; then
    while IFS= read -r line; do
      h_echo "${line##* }"
    done < <(md5 "$@")
  elif h_which md5sum > /dev/null; then
    while IFS= read -r line; do
      h_echo "${line%% *}"
    done < <(md5sum "$@")
  else
    h_error -t 'command not found: md5, md5sum'
    return 1
  fi
}

h_is_setopt() {
  h_is_zsh && setopt | grep "^$1$" > /dev/null
}

h_setopt_if_not() {
  h_is_zsh && ! setopt | grep "^$1$" > /dev/null && setopt "$1"
}

h_unsetopt_if_set() {
  if h_is_zsh && [[ "$2" == '0' ]]; then
    unsetopt "$1"
  fi
}

h_move_no_overwrite() {
  if [ -e "$2" ]; then
    h_error -t "cannot overwrite: $1 -> $2"
    return 1
  fi
  mv -n "$1" "$2"
}

h_github_download() {
  if (($# < 4)); then
    h_error 'usage: h_github_download <user> <repo> <branch> <path> [<options...>]'
    return 1
  fi
  local user="$1" repo="$2" branch="$3" _path="$4"
  shift 4
  curl -fsSL "https://raw.githubusercontent.com/$user/$repo/$branch/$_path" "$@"
}

h_check_optarg_notdash() {
  if [[ "$2" == -* ]]; then
    h_error -t "option $1 requires an argument"
    [ -n "$3" ] && "$3"
    return 1
  fi
  return 0
}

h_check_optarg_notdash_notnull() {
  if [[ "$2" == -* || -z "$2" ]]; then
    h_error -t "option $1 requires an argument"
    [ -n "$3" ] && "$3"
    return 1
  fi
  return 0
}

h_check_optarg_notnull() {
  if [ -z "$2" ]; then
    h_error -t "option $1 requires an argument"
    [ -n "$3" ] && "$3"
    return 1
  fi
  return 0
}

h_check_optarg_number() {
  if [[ ! "$2" =~ ^[0-9]+$ ]]; then
    h_error -t "option $1 requires a number"
    [ -n "$3" ] && "$3"
    return 1
  fi
  return 0
}

h_test_style() {
  h_echo "normal"
  h_echo "${H_BLACK}black${H_RESET}"
  h_echo "${H_BLACK_BOLD}black bold${H_RESET}"
  h_echo "${H_RED}red${H_RESET}"
  h_echo "${H_RED_BOLD}red bold${H_RESET}"
  h_echo "${H_GREEN}green${H_RESET}"
  h_echo "${H_YELLOW}yellow${H_RESET}"
  h_echo "${H_BLUE}blue${H_RESET}"
}
