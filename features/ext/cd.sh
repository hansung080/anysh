: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

H_CD_DEFAULT_SIZE=20
: "${H_CD_SIZE:=$H_CD_DEFAULT_SIZE}"
: "${H_CD_DUP:=}"

h_is_cd_sourced() {
  return 0
}

h_on_unset_cd() {
  unset -v H_CD_DEFAULT_SIZE
  unset -v H_CD_SIZE
  unset -v H_CD_DUP
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
    (builtin cd "$opt" &> /dev/null)
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
        ({ builtin cd "$opt_n" > /dev/null && pwd; } | sed "1 s/^/$(h_dirs_get_index "$opt_n")\t/")
      else
        (builtin cd "$opt_n" > /dev/null && pwd)
      fi
    else
      if [[ -n "$opt_v" ]]; then
        (builtin cd "$opt_n" | sed "1 s/^/$(h_dirs_get_index "$opt_n")\t/")
      else
        (builtin cd "$opt_n")
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

h_popd() {
  if h_is_zsh; then
    local cur="$PWD" prev="$OLDPWD"
    popd "$@" || return
    if [[ "$cur" == "$PWD" ]]; then
      OLDPWD="$prev"
    fi
  else
    popd "$@"
  fi
}

h_popd_from() {
  local index="${1:-1}" sign="${2:-+}" dir
  while h_popd "$sign$index" &> /dev/null; do
    :
  done
}

h_cd_dedup_by() {
  local target="$1" index="${2:-1}" sign="${3:-+}" dir
  while dir="$(h_dirs -l "$sign$index" 2> /dev/null)"; do
    if [[ "$dir" == "$target" ]]; then
      h_popd "$sign$index" > /dev/null
    else
      ((++index))
    fi
  done
}

h_cd_dedup() {
  local sign="${1:-+}" index=0 dir
  while dir="$(h_dirs -l "$sign$index" 2> /dev/null)"; do
    h_cd_dedup_by "$dir" "$((index + 1))" "$sign"
    ((++index))
  done
}

h_cd_check_optarg() {
  if [[ -z "$2" || "$2" == -* ]]; then
    h_error -t "option $1 requires an argument"
    [ -n "$3" ] && "$3"
    return 1
  fi
  return 0
}

h_cd_get_optarg() {
  local arg
  if [[ "$1" == *=* ]]; then
    arg="${1#*=}"
  else
    arg="$2"
  fi
  h_cd_check_optarg "${1%%=*}" "$arg" "$3" || return 1
  echo "$arg"
}

h_cd_help() {
  h_echo 'Usage:'
  h_echo '  cd [<options...>] [<dir>]'
  h_echo
  h_echo 'Options:'
  h_echo '  --helpx            Display this help message'
  h_echo '  ++                 Display all directories with their index of the directory stack'
  h_echo '  +++                Display all directories with their index of the directory stack, in long format instead of using ~ expression'
  h_echo '  +<index>           Change the current directory to a directory identified by <index>. e.g. +0 identifies the top directory'
  h_echo '  -<inverted index>  Change the current directory to a directory identified by <inverted index>. e.g. -0 identifies the bottom directory'
  h_echo '  -                  Change the current directory to the previous directory'
  h_echo '  --config           Display the current configuration'
  h_echo "  --size <size>      Resize the directory stack to <size>, default: $H_CD_DEFAULT_SIZE"
  h_echo '  --dup              Enable duplication in the directory stack, default: no-dup'
  h_echo '  --no-dup           Disable duplication in the directory stack'
  h_echo '  --clear            Clear the directory stack'
}

h_cd_usage() {
  h_error "Run 'cd --helpx' for more information on the usage."
}

cd() {
  local args=() arg size z=0 sign='+'
  h_is_zsh && z=1
  h_is_setopt 'pushdminus' && sign='-'

  while (($# > 0)); do
    case "$1" in
      '--helpx')
        h_cd_help
        return ;;
      '++')
        dirs -v
        return ;;
      '+++')
        dirs -l -v
        return ;;
      '-')
        [ -z "$OLDPWD" ] && { h_error -t 'OLDPWD not set'; return 1; }
        args+=("$OLDPWD")
        shift ;;
      '--config')
        h_echo "H_CD_DEFAULT_SIZE=$H_CD_DEFAULT_SIZE"
        h_echo "H_CD_SIZE=$H_CD_SIZE"
        h_echo "H_CD_DUP=$H_CD_DUP"
        return ;;
      '--size'|'--size='*)
        size="$(h_cd_get_optarg "$1" "$2" h_cd_usage)" || return 1
        [[ "$size" =~ ^[0-9]+$ ]] || { h_error -t "<size> must be a number"; return 1; }
        ((size >= 1)) || { h_error -t "<size> must be greater than or equal to 1"; return 1; }
        H_CD_SIZE="$size"
        h_popd_from "$size" "$sign"
        return ;;
      '--dup')
        H_CD_DUP='true'
        return ;;
      '--no-dup')
        H_CD_DUP=
        h_cd_dedup "$sign"
        return ;;
      '--clear')
        dirs -c
        return ;;
      '--')
        for arg in "$@"; do
          if [[ "$arg" == '-' ]]; then
            args+=("$PWD/-")
          else
            args+=("$arg")
          fi
        done
        break ;;
      *)
        if [[ "$1" =~ ^[+-][0-9]+$ ]]; then
          args+=("$(h_dirs -l "$1")") || return 1
        else
          args+=("$1")
        fi
        shift ;;
    esac
  done

  if [ ${#args[@]} -eq 0 ] || [[ ${#args[@]} -eq 1 && "${args[0 + z]}" == '--' ]]; then
    args+=("$HOME")
  fi

  if [[ "${args[0 + z]}" == -[^-]* ]]; then
    builtin cd "${args[@]}" || return
  else
    pushd "${args[@]}" > /dev/null || return
  fi

  if [ -z "$H_CD_DUP" ]; then
    h_cd_dedup_by "$PWD" 1 "$sign"
  fi

  h_popd "$sign$H_CD_SIZE" &> /dev/null || true
}
