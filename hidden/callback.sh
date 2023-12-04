h_register_on_source() {
  H_ON_SOURCE+=("$1")
}

h_call_on_source() {
  local fname
  for fname in "${H_ON_SOURCE[@]}"; do
    if declare -f "h_on_source_$fname" > /dev/null; then
      "h_on_source_$fname"
    fi
  done
}

h_call_on_unset() {
  local _path base fname
  for _path in "$@"; do
    base="$(basename "$_path")"
    fname="${base#.}"
    fname="${fname%.sh}"
    if declare -f "h_on_unset_$fname" > /dev/null; then
      "h_on_unset_$fname"
    fi
  done
}
