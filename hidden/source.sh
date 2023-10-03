: "${H_ANYSH_DIR:=$HOME/.anyshrc.d}"
__H_FEATURES_DIR="$H_ANYSH_DIR/features"
__H_FEATURES=()
__H_RESET=$'\033[0m'
__H_RED_BOLD=$'\033[1;31m'
__H_GREEN=$'\033[0;32m'

__h_is_debug() {
  [ -n "$H_DEBUG" ]
}

h_source_is_force() {
  [ -n "$H_SOURCE_FORCE" ]
}

__h_source_one() {
  local target="$1"
  if ! h_source_is_force && h_is_"$target"_sourced 2> /dev/null; then
    return 1 # already sourced
  fi

  local IFS=$'\n'
  local feature base fname
  ((${#__H_FEATURES[@]} == 0)) && __H_FEATURES=($(find "$__H_FEATURES_DIR" -type f -name '*.sh'))
  for feature in "${__H_FEATURES[@]}"; do
    base="$(basename "$feature")"
    fname="${base#.}"
    fname="${fname%.sh}"
    if [[ "$fname" == "$target" ]]; then
      if ! h_source_is_force && [[ "${base:0:1}" == '.' ]]; then
        echo >&2 -e "${__H_RED_BOLD}error${__H_RESET}: $target is off"
        return 2 # is off
      else
        source "$feature"
        __h_is_debug && echo -e "${__H_GREEN}debug${__H_RESET}: $target just sourced: $feature"
        return 0 # just sourced
      fi
    fi
  done
  echo >&2 -e "${__H_RED_BOLD}error${__H_RESET}: $target not found"
  return 3 # not found
}

h_source() {
  local __H_FEATURES=()
  local fname r ret=0
  for fname in "$@"; do
    __h_source_one "$fname"; r=$?
    ((r > ret)) && ret="$r"
  done
  return "$ret"
}
