#!/bin/bash

export H_ANYSH_DIR="$(dirname "$(readlink -f "$0")")"
source "$H_ANYSH_DIR/hidden/source.sh"
H_VERBOSE= H_SOURCE_ENABLE='true' H_SOURCE_FORCE=
h_source 'anysh' || exit 1

#h_anysh_check_all_features_nodup || exit 1
h_anysh_check_all_features_nodup
LIST_FILE="$H_ANYSH_DIR/list.txt"
rm -f "$LIST_FILE"

main() {
  local feature gname fpath deps hash sep=' '
  while IFS= read -r feature; do
    gname="${feature%%/*}"
    [[ "$gname" == "$feature" ]] && gname=''
    if [[ "$gname" == 'hidden' ]]; then
      fpath="$H_ANYSH_DIR/$feature"
      deps='-'
    else
      fpath="$H_FEATURES_DIR/$feature"
      deps="$(h_anysh_get_deps "$fpath")"
      deps="${deps:--}"
    fi
    hash='-'
    echo "$feature$sep${deps// /,}$sep$hash" >> "$LIST_FILE"
  done < <(h_anysh_get_all_features '*')
}

main
