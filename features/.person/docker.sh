: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_docker_sourced() {
  return 0
}

d_docker_person() {
  h_echo 'docker in person'
}
