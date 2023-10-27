: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_fox_sourced() {
  return 0
}

a_fox() {
  h_echo 'fox'
}
