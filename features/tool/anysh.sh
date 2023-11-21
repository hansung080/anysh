: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util' 'getopt'

H_ANYSH_VERSION='1.0.0'
H_HIDDEN_DIR="$H_ANYSH_DIR/hidden"
H_FEATURES_DIR="$H_ANYSH_DIR/features"

h_is_anysh_sourced() {
  return 0
}

h_anysh_get_hidden() {
  (($# == 0)) && return 0
  local target opts=()
  for target in "$@"; do
    opts+=('-o' '-name' "$target.sh" '-o' '-name' ".$target.sh")
  done

  find "$H_HIDDEN_DIR" -type f \( "${opts[@]:1}" \) -exec expr 'X{}' : "X$H_ANYSH_DIR/\(.*\)" \;
}

h_anysh_get_groups() {
  (($# == 0)) && return 0
  local target opts=()
  for target in "$@"; do
    opts+=('-o' '-name' "$target")
  done

  find "$H_FEATURES_DIR" -depth 1 -type d \( "${opts[@]:1}" \) -exec basename {} \;
}

h_anysh_get_features() {
  (($# == 0)) && return 0
  local target group_args=() feature_opts=() groups=()
  for target in "$@"; do
    case "$target" in
      '*')
        find "$H_FEATURES_DIR" -type f -name '*.sh' -exec expr 'X{}' : "X$H_FEATURES_DIR/\(.*\)" \;
        return
        ;;
      :*)
        group_args+=("${target:1}")
        ;;
      *)
        feature_opts+=('-o' '-name' "$target.sh" '-o' '-name' ".$target.sh")
        ;;
    esac
  done

  if ((${#group_args[@]} > 0)); then
    h_split $'\n' "$(h_anysh_get_groups "${group_args[@]}")" groups
    if ((${#groups[@]} > 0)); then
      find "${groups[@]/#/$H_FEATURES_DIR/}" -type f -name '*.sh' -exec expr 'X{}' : "X$H_FEATURES_DIR/\(.*\)" \;
    fi
  fi

  if ((${#feature_opts[@]} > 0)); then
    if ((${#groups[@]} > 0)); then
      local _groups=("${groups[@]/#/^}")
      find "$H_FEATURES_DIR" -type f \( "${feature_opts[@]:1}" \) -exec expr 'X{}' : "X$H_FEATURES_DIR/\(.*\)" \; | grep -Ev "$(h_join_elems '|' "${_groups[@]/%//}")"
      return 0
    else
      find "$H_FEATURES_DIR" -type f \( "${feature_opts[@]:1}" \) -exec expr 'X{}' : "X$H_FEATURES_DIR/\(.*\)" \;
    fi
  fi
}

h_anysh_get_all_features() {
  h_anysh_get_hidden "$@" && \
  h_anysh_get_features "$@"
}

__h_anysh_parse_feature() {
  dir="$(dirname "$feature")"
  if [[ "$dir" == '.' ]]; then
    gname=''
  else
    gname="${dir%%/*}"
  fi

  base="$(basename "$feature")"
  fname="${base#.}"
  fname="${fname%.sh}"
  if [[ "${base:0:1}" == '.' ]]; then
    state='off'
  else
    state='on'
  fi
}

__h_anysh_set_path() {
  local prefix
  if [[ "$gname" == 'hidden' ]]; then
    rpath="$feature"
    prefix="$H_ANYSH_DIR"
  else
    rpath="features/$feature"
    prefix="$H_FEATURES_DIR"
  fi

  if [ -f "$prefix/$dir/$fname.sh" ]; then
    if [[ "$dir" == '.' ]]; then
      lpath="$prefix/$fname.sh"
    else
      lpath="$prefix/$dir/$fname.sh"
    fi
  elif [ -f "$prefix/$dir/.$fname.sh" ]; then
    if [[ "$dir" == '.' ]]; then
      lpath="$prefix/.$fname.sh"
    else
      lpath="$prefix/$dir/.$fname.sh"
    fi
  else
    lpath=''
  fi
}

h_anysh_download() {
  if (($# < 1)); then
    h_error 'usage: h_anysh_download <path> [<options...>]'
    return 1
  fi
  h_github_download 'hansung080' 'anysh' 'main' "$@"
}

h_anysh_get_all_features_remote() {
  (($# == 0)) && return 0
  h_setopt_if_not 'globsubst'; local globsubst_ret="$?"
  local feature dir base gname fname state deps hash sep=' ' target
  while IFS="$sep" read -r feature deps hash; do
    __h_anysh_parse_feature
    for target in "$@"; do
      if [[ "${target:0:1}" == ':' ]]; then
        if [[ "$gname" == ${target:1} ]]; then
          h_echo "$feature$sep$deps$sep$hash"
          break
        fi
      else
        if [[ "$fname" == $target ]]; then
          h_echo "$feature$sep$deps$sep$hash"
          break
        fi
      fi
    done
  done < <(h_anysh_download 'list.txt')
  h_unsetopt_if_set 'globsubst' "$globsubst_ret"
}

h_anysh_get_deps() {
  grep -E '^ *h_source +' "$1" | sed 's/h_source//' | xargs echo
}

h_anysh_ls() {
  (($# == 0)) && set -- '*'
  local t_gname='GROUP' t_fname='FEATURE' t_state='STATE' t_deps='DEPENDENCIES'
  local feature dir base gname fname state deps sep=' '
  local features=() gmax="${#t_gname}" glen fmax="${#t_fname}" flen smax="${#t_state}"
  while IFS= read -r feature; do
    __h_anysh_parse_feature
    deps="$(h_anysh_get_deps "$H_FEATURES_DIR/$feature")"
    deps="${deps:--}"
    features+=("${gname:=-}$sep$fname$sep$state$sep${deps// /,}")
    glen="${#gname}"; ((glen > gmax)) && gmax="$glen"
    flen="${#fname}"; ((flen > fmax)) && fmax="$flen"
  done < <(h_anysh_get_features "$@")

  local gn fn sn
  ((gn = gmax - ${#t_gname} + 2))
  ((fn = fmax - ${#t_fname} + 2))
  ((sn = smax - ${#t_state} + 2))
  h_echo "$t_gname$(h_repeat ' ' "$gn")$t_fname$(h_repeat ' ' "$fn")$t_state$(h_repeat ' ' "$sn")$t_deps"
  ((${#features[@]} == 0)) && return 1

  local style
  while IFS="$sep" read -r gname fname state deps; do
    ((gn = gmax - ${#gname} + 2))
    ((fn = fmax - ${#fname} + 2))
    ((sn = smax - ${#state} + 2))
    if [[ "$state" == 'on' ]]; then
      style="$H_BLUE"
    else
      style=''
    fi
    h_echo "$style$gname$(h_repeat ' ' "$gn")$fname$(h_repeat ' ' "$fn")$state$(h_repeat ' ' "$sn")$deps$H_RESET"
  done < <(IFS=$'\n'; h_echo "${features[*]}" | sort)
}

h_anysh_is_synced() {
  if [ -f "$1" ]; then
    if [[ "$2" == "$(h_md5 "$1")" ]]; then
      return 0
    else
      return 1
    fi
  else
    return 2
  fi
}

h_anysh_get_sync() {
  h_anysh_is_synced "$1" "$2"
  case $? in
    0) h_echo 'synced' ;;
    1) h_echo 'not-synced' ;;
    2) h_echo 'not-installed' ;;
    *) h_error -t 'failed to get sync'; return 1 ;;
  esac
}

h_anysh_ls_remote() {
  (($# == 0)) && set -- '*'
  local t_gname='GROUP' t_fname='FEATURE' t_state='STATE' t_deps='DEPENDENCIES' t_sync='SYNC'
  local feature dir base gname fname state rpath lpath deps hash sync sep=' '
  local features=() gmax="${#t_gname}" glen fmax="${#t_fname}" flen smax="${#t_state}" dmax="${#t_deps}" dlen
  while IFS="$sep" read -r feature deps hash; do
    __h_anysh_parse_feature
    __h_anysh_set_path
    sync="$(h_anysh_get_sync "$lpath" "$hash")"
    features+=("${gname:=-}$sep$fname$sep$state$sep$deps$sep$sync")
    glen="${#gname}"; ((glen > gmax)) && gmax="$glen"
    flen="${#fname}"; ((flen > fmax)) && fmax="$flen"
    dlen="${#deps}"; ((dlen > dmax)) && dmax="$dlen"
  done < <(h_anysh_get_all_features_remote "$@")

  local gn fn sn dn
  ((gn = gmax - ${#t_gname} + 2))
  ((fn = fmax - ${#t_fname} + 2))
  ((sn = smax - ${#t_state} + 2))
  ((dn = dmax - ${#t_deps} + 2))
  h_echo "$t_gname$(h_repeat ' ' "$gn")$t_fname$(h_repeat ' ' "$fn")$t_state$(h_repeat ' ' "$sn")$t_deps$(h_repeat ' ' "$dn")$t_sync"
  ((${#features[@]} == 0)) && return 1

  local style
  while IFS="$sep" read -r gname fname state deps sync; do
    ((gn = gmax - ${#gname} + 2))
    ((fn = fmax - ${#fname} + 2))
    ((sn = smax - ${#state} + 2))
    ((dn = dmax - ${#deps} + 2))
    if [[ "$sync" != 'synced' ]]; then
      style="$H_RED"
    else
      style=''
    fi
    h_echo "$style$gname$(h_repeat ' ' "$gn")$fname$(h_repeat ' ' "$fn")$state$(h_repeat ' ' "$sn")$deps$(h_repeat ' ' "$dn")$sync$H_RESET"
  done < <(IFS=$'\n'; h_echo "${features[*]}" | sort)
}

h_anysh_check_args_nonzero() {
  if (($# == 0)); then
    h_error -t "argument <features...> required"
    h_anysh_usage
    return 1
  fi
  return 0
}

h_anysh_print_result() {
  if [ -z "$1" ]; then
    shift
    local IFS=' '
    h_error -t "no features found: $*"
    return 1
  fi
  h_info "${1# }"
}

__h_anysh_add_deps() {
  if [[ "$1" != '*' ]]; then
    local tdep=()
    h_split "$2" "$3" tdep
    tdeps+=("${tdep[@]}")
    targets+=("$fname")
  fi
}

__h_anysh_on_process() {
  if [[ "$state" == 'on' ]]; then
    out+="$osep$fname"
    source "$H_FEATURES_DIR/$feature"
  else
    out+="$osep$H_BLUE$fname$H_RESET"
    h_move_no_overwrite "$H_FEATURES_DIR/$feature" "$H_FEATURES_DIR/$dir/${base#.}" && \
    source "$H_FEATURES_DIR/$dir/${base#.}"
  fi
  osep=' '
}

h_anysh_on() {
  h_anysh_check_args_nonzero "$@" || return 1
  local feature dir base gname fname state
  local tdeps=() targets=() out='' osep=' '
  while IFS= read -r feature; do
    __h_anysh_parse_feature
    __h_anysh_add_deps "$1" ' ' "$(h_anysh_get_deps "$H_FEATURES_DIR/$feature")"
    __h_anysh_on_process
  done < <(h_anysh_get_features "$@")

  h_dedup_array tdeps
  h_diff_array tdeps targets
  osep=$'\n'
  while IFS= read -r feature; do
    __h_anysh_parse_feature
    __h_anysh_on_process
  done < <(h_anysh_get_features "${tdeps[@]}")

  h_anysh_print_result "$out" "$@"
}

h_anysh_unset_funcs() {
  local _path func
  for _path in "$@"; do
    while IFS= read -r func; do
      unset -f "$func"
    done < <(grep -E '^ *[A-Za-z0-9_-]+ *\(\)' "$_path" | sed 's/().*//' | tr -d ' ')
  done
}

__h_anysh_off_process() {
  if [[ "$state" == 'on' ]]; then
    out+="$osep$H_YELLOW$fname$H_RESET"
    h_move_no_overwrite "$H_FEATURES_DIR/$feature" "$H_FEATURES_DIR/$dir/.$base" && \
    h_is_sourced "$fname" && unsets+=("$H_FEATURES_DIR/$dir/.$base")
  else
    out+="$osep$fname"
    h_is_sourced "$fname" && unsets+=("$H_FEATURES_DIR/$feature")
  fi
  osep=' '
}

h_anysh_off() {
  h_anysh_check_args_nonzero "$@" || return 1
  local feature dir base gname fname state
  local out='' osep=' ' unsets=()
  while IFS= read -r feature; do
    __h_anysh_parse_feature
    __h_anysh_off_process
  done < <(h_anysh_get_features "$@")

  h_anysh_print_result "$out" "$@" || return 1
  h_anysh_unset_funcs "${unsets[@]}"
}

h_anysh_update_is_default() {
  [ -n "$H_ANYSH_UPDATE_DEFAULT" ]
}

h_anysh_update_is_reset() {
  [ -n "$H_ANYSH_UPDATE_RESET" ]
}

__h_anysh_update_process() {
  opath=''
  if h_anysh_is_synced "$lpath" "$hash"; then
    if h_anysh_update_is_default && [[ "${lpath#$H_ANYSH_DIR}" != "$rpath" ]]; then
      if [[ "$(basename "$rpath")" == .* ]]; then
        out+="$osep$H_YELLOW$fname$H_RESET"
      else
        out+="$osep$H_BLUE$fname$H_RESET"
      fi
      h_move_no_overwrite "$lpath" "$H_ANYSH_DIR/$rpath" && \
      opath="$H_ANYSH_DIR/$rpath"
    else
      out+="$osep$fname"
      opath="$lpath"
    fi
  else
    out+="$osep$H_RED$fname$H_RESET"
    if h_anysh_update_is_default || [ -z "$lpath" ]; then
      rm -f "$lpath" && \
      mkdir -p "$(dirname "$H_ANYSH_DIR/$rpath")" && \
      h_anysh_download "$rpath" -o "$H_ANYSH_DIR/$rpath" && \
      opath="$H_ANYSH_DIR/$rpath"
    else
      mkdir -p "$(dirname "$lpath")" && \
      h_anysh_download "$rpath" -o "$lpath" && \
      opath="$lpath"
    fi
  fi
  if [ -n "$opath" ]; then
    if [[ "$(basename "$opath")" == .* ]]; then
      h_is_sourced "$fname" && unsets+=("$opath")
    else
      source "$opath"
    fi
  fi
  osep=' '
}

h_anysh_update() {
  (($# == 0)) && set -- '*'
  h_anysh_update_is_reset && rm -rf "$H_ANYSH_DIR"
  local feature dir base gname fname state rpath lpath deps hash sep=' '
  local tdeps=() targets=() out='' osep=' ' opath unsets=()
  while IFS="$sep" read -r feature deps hash; do
    __h_anysh_parse_feature
    __h_anysh_set_path
    __h_anysh_add_deps "$1" ',' "$deps"
    __h_anysh_update_process
  done < <(h_anysh_get_all_features_remote "$@")

  h_dedup_array tdeps
  h_diff_array tdeps targets
  osep=$'\n'
  while IFS="$sep" read -r feature deps hash; do
    __h_anysh_parse_feature
    __h_anysh_set_path
    __h_anysh_update_process
  done < <(h_anysh_get_all_features_remote "${tdeps[@]}")

  h_anysh_print_result "$out" "$@" || return 1
  h_anysh_unset_funcs "${unsets[@]}"
}

h_anysh_src_is_force() {
  [ -n "$H_ANYSH_SRC_FORCE" ]
}

__h_anysh_src_process() {
  if [[ "$state" == 'on' ]]; then
    out+="$osep$fname"
    source "$H_FEATURES_DIR/$feature"
  else
    out+="$osep$H_YELLOW$fname$H_RESET"
    if h_anysh_src_is_force; then
      source "$H_FEATURES_DIR/$feature"
    else
      h_warn -t "$fname is off"
    fi
  fi
  osep=' '
}

h_anysh_src() {
  h_anysh_check_args_nonzero "$@" || return 1
  local feature dir base gname fname state
  local tdeps=() targets=() out='' osep=' '
  while IFS= read -r feature; do
    __h_anysh_parse_feature
    __h_anysh_add_deps "$1" ' ' "$(h_anysh_get_deps "$H_FEATURES_DIR/$feature")"
    __h_anysh_src_process
  done < <(h_anysh_get_features "$@")

  h_dedup_array tdeps
  h_diff_array tdeps targets
  osep=$'\n'
  while IFS= read -r feature; do
    __h_anysh_parse_feature
    __h_anysh_src_process
  done < <(h_anysh_get_features "${tdeps[@]}")

  h_anysh_print_result "$out" "$@"
}

h_anysh_check_all_features_nodup() {
  local feature base fname fnames=() dups=()
  while IFS= read -r feature; do
    base="$(basename "$feature")"
    fname="${base#.}"
    fname="${fname%.sh}"
    if h_in_array "$fname" fnames; then
      dups+=("$fname")
    else
      fnames+=("$fname")
    fi
  done < <(h_anysh_get_all_features '*')

  if ((${#dups[@]} > 0)); then
    local IFS=' '
    h_error -t "duplicated features: ${dups[*]}"
    return 1
  fi
  return 0
}

h_anysh_usage() {
  h_error "Run 'anysh --help' for more information on the usage."
}

h_anysh_help() {
  h_echo 'Usage:'
  h_echo '  anysh [<options...>] <command> [<features...>]'
  h_echo '    - Use :<groups...> instead of <features...> to specify groups.'
  h_echo '    - Glob characters (* ? [ ]) can be used in <features...> or :<groups...> for pattern matching.'
  h_echo
  h_echo 'Options:'
  h_echo '  -h, --help     Display this help message'
  h_echo '  -V, --version  Display the version of anysh'
  h_echo '  -v, --verbose  Display debug logs. Not used at the moment.'
  h_echo
  h_echo 'Usage by Command:'
  h_echo '  anysh ls [<features...>]         List installed <features...>, or all features if no arguments'
  h_echo '  anysh ls-remote [<features...>]  List remote <features...> available for update, or all features if no arguments'
  h_echo '  anysh on <features...>           Turn on <features...> and their dependencies'
  h_echo '  anysh off <features...>          Turn off <features...>'
  h_echo '  anysh update [<features...>]     Update <features...> and their dependencies into the latest, or all features if no arguments'
  h_echo '    --default                      Update with the default state'
  h_echo '    --reset                        Remove and reinstall anysh'
  h_echo '  anysh src <features...>          Source <features...> and their dependencies, not-in-order and in-duplicate'
  h_echo '    -f, --force                    Allow to source off-feature'
}

anysh() {
  local H_VERBOSE=
  local H_SOURCE_ENABLE=
  local H_SOURCE_FORCE=
  local H_ANYSH_UPDATE_DEFAULT=
  local H_ANYSH_UPDATE_RESET=
  local H_ANYSH_SRC_FORCE=

  local options
  if ! options="$(getopt -o 'hVvf' -l 'help,version,verbose,default,reset,force' -- "$@")"; then
    h_anysh_usage
    return 1
  fi

  eval set -- "$options"

  while true; do
    case "$1" in
      '-h'|'--help')
        h_anysh_help
        return ;;
      '-V'|'--version')
        h_echo "$H_ANYSH_VERSION"
        return ;;
      '-v'|'--verbose')
        H_VERBOSE='true'
        shift ;;
      '--default')
        H_ANYSH_UPDATE_DEFAULT='true'
        shift ;;
      '--reset')
        H_ANYSH_UPDATE_RESET='true'
        shift ;;
      '-f'|'--force')
        H_ANYSH_SRC_FORCE='true'
        shift ;;
      '--')
        shift
        break ;;
    esac
  done

  local cmd="$1"
  shift

  local arg
  for arg in "$@"; do
    if [[ "$arg" == '*' ]]; then
      set -- '*'
      break
    fi
  done

  case "$cmd" in
    'ls')        h_anysh_ls "$@" ;;
    'ls-remote') h_anysh_ls_remote "$@" ;;
    'on')        h_anysh_on "$@" ;;
    'off')       h_anysh_off "$@" ;;
    'update')    h_anysh_update "$@" ;;
    'src')       h_anysh_src "$@" ;;
    *)
      h_error -t "invalid command: $cmd"
      h_anysh_usage
      return 1
      ;;
  esac
}
