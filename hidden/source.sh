: "${H_ANYSH_DIR:=$HOME/.anyshrc.d}"
__H_FEATURES_DIR="$H_ANYSH_DIR/features"
__H_RESET=$'\033[0m'
__H_RED_BOLD=$'\033[1;31m'
__H_GREEN=$'\033[0;32m'

__h_is_verbose() {
  [ -n "$H_VERBOSE" ]
}

h_source_is_force() {
  [ -n "$H_SOURCE_FORCE" ]
}

__h_source_one() {
  local target="$1"
  if ! h_source_is_force && h_is_"$target"_sourced 2> /dev/null; then
    return 1 # feature already sourced
  fi

  local feature
  while IFS= read -rd '' feature; do
    if ! h_source_is_force && [[ "$(basename "$feature")" == .* ]]; then
      echo >&2 -e "${__H_RED_BOLD}error${__H_RESET}: h_source: $target is off"
      return 2 # feature is off
    else
      source "$feature"
      __h_is_verbose && echo -e "${__H_GREEN}debug${__H_RESET}: h_source: $target just sourced: $feature"
      return 0 # feature just sourced
    fi
  done < <(find "$__H_FEATURES_DIR" -type f \( -name "$target.sh" -o -name ".$target.sh" \) -print0)
  echo >&2 -e "${__H_RED_BOLD}error${__H_RESET}: h_source: $target not found"
  return 3 # feature not found
}

h_source() {
  local fname r ret=0
  for fname in "$@"; do
    __h_source_one "$fname"; r=$?
    ((r > ret)) && ret="$r"
  done
  return "$ret"
}
