: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_cd_sourced() {
  return 0
}

h_dirs_size() {
  (
    local count=1
    while popd &> /dev/null; do
      ((++count))
    done
    h_echo "$count"
  )
}

h_dirs_check_index() {
  local opt="$1"
  if [[ ! "$opt" =~ ^[+-][0-9]+$ ]]; then
    h_error -t "invalid option: $opt"
    return 1
  fi
  if h_is_zsh; then
    (cd "$opt" &> /dev/null)
  else
    dirs "$opt" &> /dev/null
  fi
  if [ $? -ne 0 ]; then
    h_error -t "directory stack index out of range: $opt"
    return 1
  fi
  return 0
}

h_dirs_get_index() {
  local opt="$1"
  h_dirs_check_index "$opt" || return 1
  if [[ "${opt:0:1}" == '+' ]]; then
    h_echo "${opt:1}"
  else
    h_echo "$(($(h_dirs_size) - ${opt:1} - 1))"
  fi
}

h_dirs_usage() {
  h_error 'usage: h_dirs [-clpv] [+N] [-N]'
}

__h_dirs_zsh_process_options() {
  for opt in "$@"; do
    case "$opt" in
      '-c') opt_c='true' ;;
      '-l') opt_l='true' ;;
      '-p') opt_p='true' ;;
      '-v') opt_v='true' ;;
      '--') break ;;
      [+-]*)
        if [[ "$opt" =~ ^[+-][0-9]+$ ]]; then
          opt_n="$opt"
        else
          h_error -t "invalid number: $opt"
          h_dirs_usage
          return 1
        fi
        ;;
      *)
        h_error -t "invalid option: $opt"
        h_dirs_usage
        return 1
        ;;
    esac
  done
}

h_dirs_zsh() {
  local opt opt_c='' opt_l='' opt_p='' opt_v='' opt_n=''
  __h_dirs_zsh_process_options "$@" || return 1

  if [ -n "$opt_c" ]; then
    dirs -c
  elif [ -z "$opt_n" ]; then
    local opt_lpv=()
    [ -n "$opt_l" ] && opt_lpv+=('-l')
    [ -n "$opt_p" ] && opt_lpv+=('-p')
    [ -n "$opt_v" ] && opt_lpv+=('-v')
    dirs "${opt_lpv[@]}"
  else
    h_dirs_check_index "$opt_n" || return 1
    if [[ -n "$opt_l" ]]; then
      if [[ -n "$opt_v" ]]; then
        ({ cd "$opt_n" > /dev/null && pwd; } | sed "1 s/^/$(h_dirs_get_index "$opt_n")\t/")
      else
        (cd "$opt_n" > /dev/null && pwd)
      fi
    else
      if [[ -n "$opt_v" ]]; then
        (cd "$opt_n" | sed "1 s/^/$(h_dirs_get_index "$opt_n")\t/")
      else
        (cd "$opt_n")
      fi
    fi
  fi
}

# NOTE: This function has a bug: The command 'h_dirs_zsh2 {+|-}N' will print a wrong directory entry,
#       if the pattern '\nN\t.' exists in a directory path.
h_dirs_zsh2() {
  local opt opt_c='' opt_l='' opt_p='' opt_v='' opt_n=''
  __h_dirs_zsh_process_options "$@" || return 1

  if [ -n "$opt_c" ]; then
    dirs -c
  elif [ -z "$opt_n" ]; then
    local opt_lpv=()
    [ -n "$opt_l" ] && opt_lpv+=('-l')
    [ -n "$opt_p" ] && opt_lpv+=('-p')
    [ -n "$opt_v" ] && opt_lpv+=('-v')
    dirs "${opt_lpv[@]}"
  else
    local index matched_line next_line after_context
    index="$(h_dirs_get_index "$opt_n")" || return 1
    matched_line="$(dirs -v | grep -nm 1 "^${index}\t." | sed -E 's/^([0-9]+):.*$/\1/')"
    if [ -z "$matched_line" ]; then
      h_error -t "no matched line: $index"
      return 1
    elif [[ ! "$matched_line" =~ ^[0-9]+$ ]]; then
      h_error -t "invalid line number: $matched_line"
      return 1
    fi

    next_line="$(dirs -v | grep -nm 1 "^$((index + 1))\t." | sed -E 's/^([0-9]+):.*$/\1/')"
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
        dirs -lv | grep -m 1 -A "$after_context" "^${index}\t."
      else
        dirs -lv | grep -m 1 -A "$after_context" "^${index}\t." | sed "1 s/^${index}\t//"
      fi
    else
      if [[ -n "$opt_v" ]]; then
        dirs -v | grep -m 1 -A "$after_context" "^${index}\t."
      else
        dirs -v | grep -m 1 -A "$after_context" "^${index}\t." | sed "1 s/^${index}\t//"
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
