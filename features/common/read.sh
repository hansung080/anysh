: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_read_sourced() {
  return 0
}

h_read_ext() {
  local cmd
  if cmd="$(h_which read)"; then
    "$cmd" "$@"
  else
    h_error -t 'command not found: read'
  fi
}

h_pause() {
  IFS= h_read_ext -rsn 1 -p "${1-Press any key to continue...}"
}

h_confirm() {
  h_echo -ne "$1"
  IFS=$' \t' read -r answer
  [[ "$answer" == "$2" ]]
}
