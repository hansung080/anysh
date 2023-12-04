: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/callback.sh"

h_init() {
  local H_VERBOSE= H_SOURCE_ENABLE= H_SOURCE_FORCE=
  local feature base fname
  local H_ON_SOURCE=()
  while IFS= read -rd '' feature; do
    base="$(basename "$feature")"
    fname="${base%.sh}"
    source "$feature" && h_register_on_source "$fname"
    [[ "$1" == '-v' ]] && echo "sourced $feature"
  done < <(find "$H_ANYSH_DIR/hidden" "$H_ANYSH_DIR/features" -type f -name '[^.]*.sh' -print0)
  h_call_on_source
}

if [[ "$1" == '--now' ]]; then
  h_init ''
fi
