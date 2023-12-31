#!/bin/bash

export H_ANYSH_DIR="$(dirname "$(readlink -f "$0")")"
source "$H_ANYSH_DIR/hidden/source.sh"
H_VERBOSE= H_SOURCE_ENABLE='true' H_SOURCE_FORCE=
h_source 'util' 'anysh' || exit 1

main() {
  h_anysh_check_all_features_nodup || exit 1
  local list_file="$H_ANYSH_DIR/list.txt"
  rm -f "$list_file"

  local feature gname lpath deps hash sep=' '
  while IFS= read -r feature; do
    gname="${feature%%/*}"
    [[ "$gname" == "$feature" ]] && gname=''
    if [[ "$gname" == 'hidden' ]]; then
      lpath="$H_ANYSH_DIR/$feature"
      deps='-'
    else
      lpath="$H_FEATURES_DIR/$feature"
      deps="$(h_anysh_get_deps "$lpath")"
      deps="${deps:--}"
    fi
    hash="$(h_md5 "$lpath")" || hash='-'
    echo "$feature$sep${deps// /,}$sep$hash" >> "$list_file"
  done < <(h_anysh_get_all_features '*')
}

main
