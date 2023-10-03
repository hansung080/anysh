: "${H_ANYSH_DIR:=$HOME/.anyshrc.d}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_dog_sourced() {
  return 0
}

a_dog() {
  h_echo 'dog'
}
