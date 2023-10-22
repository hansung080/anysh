: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_fish_sourced() {
  return 0
}

a_fish() {
  h_echo 'fish'
}
