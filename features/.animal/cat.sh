: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util' 'path' 'getopt'

h_is_cat_sourced() {
  return 0
}

a_cat() {
  h_echo 'cat'
}
