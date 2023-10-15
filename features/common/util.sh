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

h_is_verbose() {
  [ -n "$H_VERBOSE" ]
}

h_is_bash() {
  [ -n "${BASH_VERSION}" ]
}

h_is_zsh() {
  [ -n "${ZSH_VERSION}" ]
}

h_is_linux() {
  [[ "$(uname -s)" == 'Linux' ]]
}

h_is_mac() {
  [[ "$(uname -s)" == 'Darwin' ]]
}

h_is_whitespace() {
  [[ "$1" == ' ' || "$1" == $'\t' || "$1" == $'\n' ]]
}

h_echo() {
  echo -e "$@"
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

h_shell() {
  ps -p $$ | tail -1 | awk '{ print $4 }'
}

h_shell_name() {
  local sh
  sh="$(h_shell)"
  if [[ "${sh:0:1}" == '-' ]]; then
    h_echo "${sh:1}"
  else
    basename "$sh"
  fi
}

h_trim_array() {
  local _arr="${2:-$1}" _elem
  eval set -- '"${'"$1"'[@]}"'
  eval "$_arr"='()'
  for _elem in "$@"; do
    if [ -n "$_elem" ]; then
      eval "$_arr"+="('$_elem')"
    fi
  done
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
    while read -rd "$1" _elem; do
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

h_dedup_array() {
  local _arr="${2:-$1}" _elem
  eval set -- '"${'"$1"'[@]}"'
  eval "$_arr"='()'
  for _elem in "$@"; do
    if ! h_in_array "$_elem" "$_arr"; then
      eval "$_arr"+="('$_elem')"
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

h_test_style() {
  h_echo "${H_BLACK}black${H_RESET}"
  h_echo "${H_BLACK_BOLD}black bold${H_RESET}"
  h_echo "${H_RED}red${H_RESET}"
  h_echo "${H_RED_BOLD}red bold${H_RESET}"
  h_echo "${H_GREEN}green${H_RESET}"
  h_echo "${H_YELLOW}yellow${H_RESET}"
  h_echo "${H_BLUE}blue${H_RESET}"
}
