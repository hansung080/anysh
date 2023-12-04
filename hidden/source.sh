: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/callback.sh"

__H_FEATURES_DIR="$H_ANYSH_DIR/features"
__H_RESET=$'\033[0m'
__H_RED_BOLD=$'\033[1;31m'
__H_GREEN=$'\033[0;32m'
__H_YELLOW=$'\033[0;33m'

__h_is_verbose() {
  [ -n "$H_VERBOSE" ]
}

h_source_is_enable() {
  [ -n "$H_SOURCE_ENABLE" ]
}

h_source_is_force() {
  [ -n "$H_SOURCE_FORCE" ]
}

# Source features and their dependencies, in-dependencies-first and not-in-duplicate as default.
h_source() {
  h_source_is_enable || return 0

  if (($# == 0)); then
    echo >&2 -e "${__H_RED_BOLD}error${__H_RESET}: h_source: arguments required"
    return 1
  fi

  local target opts=()
  for target in "$@"; do
    opts+=('-o' '-name' "$target.sh" '-o' '-name' ".$target.sh")
  done

  local feature base fname found='' ret=0 off
  local H_ON_SOURCE=()
  while IFS= read -rd '' feature; do
    found='true'
    base="$(basename "$feature")"
    fname="${base#.}"
    fname="${fname%.sh}"
    if ! h_source_is_force; then
      if declare -f "h_is_${fname}_sourced" > /dev/null; then
        continue
      fi
      if [[ "${base:0:1}" == '.' ]]; then
        echo >&2 -e "${__H_YELLOW}warning${__H_RESET}: h_source: $fname is off"
        ret=1
        continue
      fi
    fi

    source "$feature" && h_register_on_source "$fname"
    off=''; [[ "${base:0:1}" == '.' ]] && off=' (off)'
    __h_is_verbose && echo -e "${__H_GREEN}debug${__H_RESET}: h_source: $fname just sourced$off: $feature"
  done < <(find "$__H_FEATURES_DIR" -type f \( "${opts[@]:1}" \) -print0)
  h_call_on_source

  if [ -z "$found" ]; then
    local IFS=' '
    echo >&2 -e "${__H_RED_BOLD}error${__H_RESET}: h_source: no features found: $*"
    return 1
  fi
  return "$ret"
}

# Allow to source in-duplicate and off-feature.
h_source_force() {
  local H_SOURCE_ENABLE='true'
  local H_SOURCE_FORCE='true'
  h_source "$@"
}
