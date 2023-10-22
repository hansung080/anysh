: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_eagle_sourced() {
  return 0
}

a_eagle() {
  h_echo 'eagle'
}
