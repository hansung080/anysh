: "${H_ANYSH_DIR:=$HOME/.anysh}"

h_init() {
  local H_VERBOSE= H_SOURCE_ENABLE= H_SOURCE_FORCE=
  local feature
  while IFS= read -rd '' feature; do
    [[ "$1" == '-v' ]] && echo "source $feature"
    source "$feature"
  done < <(find "$H_ANYSH_DIR/hidden" "$H_ANYSH_DIR/features" -type f -name '[^.]*.sh' -print0)
}

if [[ "$1" == '--now' ]]; then
  h_init ''
fi
