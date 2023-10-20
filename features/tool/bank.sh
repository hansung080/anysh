: "${H_ANYSH_DIR:=$HOME/.anyshrc.d}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_bank_sourced() {
  return 0
}

h_bank() {
  h_echo 'bank'
}
