: "${H_ANYSH_DIR:=$HOME/.anysh}"

h_source_on_features() {
  local H_VERBOSE= H_SOURCE_ENABLE= H_SOURCE_FORCE=
  local feature
  while IFS= read -rd '' feature; do
    source "$feature"
  done < <(find "$H_ANYSH_DIR/features" -type f -name '[^.]*.sh' -print0)
}

h_source_on_features
