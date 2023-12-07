: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_cd_sourced() {
  return 0
}

h_dirs_size() {
  if h_is_bash; then
    dirs -v | grep -c '^[ 0-9][0-9]\+  .'
  elif h_is_zsh; then
    dirs -v | grep -c '^[0-9]\+\t.'
  else
    h_error -t "unsupported shell: $(h_current_shell)"
    return 1
  fi
}

h_dirs_usage() {
  h_error 'usage: h_dirs [-clpv] [+N] [-N]'
}

h_dirs_zsh() {
  local opt opt_c='' opt_l='' opt_p='' opt_v='' opt_n='' size
  for opt in "$@"; do
    case "$opt" in
      '-c') opt_c='true' ;;
      '-l') opt_l='true' ;;
      '-p') opt_p='true' ;;
      '-v') opt_v='true' ;;
      [-+][0-9]*)
        if [[ "$opt" =~ ^[-+][0-9]+$ ]]; then
          if [[ "${opt:0:1}" == '+' ]]; then
            opt_n="${opt:1}"
          else
            size="$(h_dirs_size)"
            opt_n="${opt:1}"
            ((opt_n = size - opt_n - 1))
          fi
        else
          h_error -t "invalid option: $opt"
          h_dirs_usage
          return 1
        fi
        ;;
      '--')
        break
        ;;
      *)
        h_error -t "invalid option: $opt"
        h_dirs_usage
        return 1
        ;;
    esac
  done

  if [ -n "$opt_c" ]; then
    dirs -c
  elif [ -z "$opt_n" ]; then
    local opt_lpv=()
    [ -n "$opt_l" ] && opt_lpv+=('-l')
    [ -n "$opt_p" ] && opt_lpv+=('-p')
    [ -n "$opt_v" ] && opt_lpv+=('-v')
    dirs "${opt_lpv[@]}"
  else
    local matched_line next_line after_context
    matched_line="$(dirs -v | grep -nm 1 "^${opt_n}\t." | sed -E 's/^([0-9]+):.*$/\1/')"
    if [ -z "$matched_line" ]; then
      h_error -t "directory stack index out of range: $opt_n"
      return 1
    elif [[ ! "$matched_line" =~ ^[0-9]+$ ]]; then
      h_error -t "invalid line number: $matched_line"
      return 1
    fi

    next_line="$(dirs -v | grep -nm 1 "^$((opt_n + 1))\t." | sed -E 's/^([0-9]+):.*$/\1/')"
    if [ -z "$next_line" ]; then
      next_line="$(dirs -v | grep -c '.')"
      ((++next_line))
    fi
    if [[ ! "$next_line" =~ ^[0-9]+$ ]]; then
      h_error -t "invalid line number: $next_line"
      return 1
    fi

    ((after_context = next_line - matched_line - 1))
    if ((after_context < 0)); then
      h_error -t "invalid after context: $after_context"
      return 1
    fi

    if [[ -n "$opt_l" ]]; then
      if [[ -n "$opt_v" ]]; then
        dirs -lv | grep -m 1 -A "$after_context" "^${opt_n}\t."
      else
        dirs -lv | grep -m 1 -A "$after_context" "^${opt_n}\t." | sed "s/^${opt_n}\t//"
      fi
    else
      if [[ -n "$opt_v" ]]; then
        dirs -v | grep -m 1 -A "$after_context" "^${opt_n}\t."
      else
        dirs -v | grep -m 1 -A "$after_context" "^${opt_n}\t." | sed "s/^${opt_n}\t//"
      fi
    fi
  fi
}

h_dirs() {
  if h_is_zsh; then
    h_dirs_zsh "$@"
  else
    dirs "$@"
  fi
}
