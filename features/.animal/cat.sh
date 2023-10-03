: "${H_ANYSH_DIR:=$HOME/.anyshrc.d}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_cat_sourced() {
  return 0
}

a_cat() {
  h_echo 'cat'
}
