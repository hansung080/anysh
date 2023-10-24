: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_path_sourced() {
  return 0
}

h_in_path() {
  [[ ":$PATH:" == *":$1:"* ]]
}

h_in_path2() {
  local paths
  h_split ':' "$PATH" paths
  h_in_array "$1" paths
}

h_in_path3() {
  local paths
  h_split ':' "$PATH" paths
  h_in_elems "$1" "${paths[@]}"
}

h_add_path_front() {
  if [ -z "$PATH" ]; then
    export PATH="$1"
  elif ! h_in_path "$1"; then
    export PATH="$1:$PATH"
  fi
}

h_add_path_back() {
  if [ -z "$PATH" ]; then
    export PATH="$1"
  elif ! h_in_path "$1"; then
    export PATH="$PATH:$1"
  fi
}

h_dedup_path() {
  local paths p
  h_split ':' "$PATH" paths
  PATH=''
  for p in "${paths[@]}"; do
    h_add_path_back "$p"
  done
}

h_path() {
  local paths p i=1
  h_split ':' "$PATH" paths
  for p in "${paths[@]}"; do
    h_echo "$i: $p"
    ((++i))
  done
}

h_readlink() {
  [ -e "$1" ] || return 1
  local file="$1" link _path
  while [ -h "$file" ]; do
    link="$(expr "X$(ls -ld "$file")" : 'X.* -> \(.*\)$')"
    if [ -z "$link" ]; then
      return 1
    elif [[ "${link:0:1}" == '/' ]]; then
      file="$link"
    else
      file="$(dirname "$file")/$link"
    fi
  done
  _path="$(cd "$(dirname "$file")" && pwd -P)" && \
  _path+="/$(basename "$file")" && \
  echo "$_path"
}
