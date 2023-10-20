: "${H_ANYSH_DIR:=$HOME/.anyshrc.d}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util' 'getopt'

H_ANYSH_VERSION='1.0.0'
H_FEATURES_DIR="$H_ANYSH_DIR/features"

h_is_anysh_sourced() {
  return 0
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
    else
      find "$H_FEATURES_DIR" -type f \( "${feature_opts[@]:1}" \) -exec expr 'X{}' : "X$H_FEATURES_DIR/\(.*\)" \;
    fi
  fi
}

__h_anysh_parse_feature() {
  dir="$(dirname "$feature")"
  if [[ "$dir" == '.' ]]; then
    gname="-"
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

h_anysh_get_deps() {
  grep -E '^ *h_source +' "$1" | sed 's/h_source//' | xargs echo
}

h_anysh_get_funcs() {
  grep -E '^ *[A-Za-z0-9_-]+ *\(\)' "$1" | sed 's/().*//' | tr -d ' '
}

h_anysh_unset_funcs() {
  local func
  while IFS= read -r func; do
    unset -v "$func"
  done < <(h_anysh_get_funcs "$1")
}

h_anysh_ls() {
  (($# == 0)) && set -- '*'
  local t_gname='GROUP' t_fname='FEATURE' t_state='STATE' t_deps='DEPENDENCIES'
  local feature dir base gname fname state deps
  local features=() sep=' ' gmax="${#t_gname}" glen fmax="${#t_fname}" flen smax="${#t_state}"
  while IFS= read -r feature; do
    __h_anysh_parse_feature
    deps="$(h_anysh_get_deps "$H_FEATURES_DIR/$feature")"
    deps="${deps:--}"
    features+=("$gname$sep$fname$sep$state$sep${deps// /,}")
    glen="${#gname}"
    if ((glen > gmax)); then
      gmax="$glen"
    fi
    flen="${#fname}"
    if ((flen > fmax)); then
      fmax="$flen"
    fi
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

h_anysh_ls_remote() {
  (($# == 0)) && set -- '*'
}

h_anysh_check_args_nonzero() {
  if (($# == 0)); then
    h_error -t "argument <features...> required"
    h_anysh_usage
    return 1
  fi
  return 0
}

h_anysh_on() {
  h_anysh_check_args_nonzero "$@" || return 1
  local feature dir base gname fname state
  local dep=() deps=() targets=() out=''
  while IFS= read -r feature; do
    __h_anysh_parse_feature
    if [[ "$1" != '*' ]]; then
      h_split ' ' "$(h_anysh_get_deps "$H_FEATURES_DIR/$feature")" dep
      deps+=("${dep[@]}")
      targets+=("$gname")
    fi
    source "$H_FEATURES_DIR/$feature"
    if [[ "$state" == 'on' ]]; then
      out+=" $gname"
    else
      out+=" $H_BLUE$gname$H_RESET"
      mv "$H_FEATURES_DIR/$feature" "$H_FEATURES_DIR/$dir/${base#.}"
    fi
  done < <(h_anysh_get_features "$@")

  h_dedup_array deps
  h_diff_array deps targets
  local sep=$'\n'
  while IFS= read -r feature; do
    __h_anysh_parse_feature
    source "$H_FEATURES_DIR/$feature"
    if [[ "$state" == 'on' ]]; then
      out+="$sep$gname"
    else
      out+="$sep$H_BLUE$gname$H_RESET"
      mv "$H_FEATURES_DIR/$feature" "$H_FEATURES_DIR/$dir/${base#.}"
    fi
    sep=' '
  done < <(h_anysh_get_features "${deps[@]}")

  if [ -n "$out" ]; then
    h_info "${out# }"
  else
    local IFS=' '
    h_error -t "no features matched: $*"
    return 1
  fi
}

h_anysh_off() {
  h_anysh_check_args_nonzero "$@" || return 1
  local feature dir base gname fname state
  local out=''
  while IFS= read -r feature; do
    __h_anysh_parse_feature
    h_is_sourced "$gname" && h_anysh_unset_funcs "$H_FEATURES_DIR/$feature"
    if [[ "$state" == 'on' ]]; then
      out+=" $H_BLUE$gname$H_RESET"
      mv "$H_FEATURES_DIR/$feature" "$H_FEATURES_DIR/$dir/.$base"
    else
      out+=" $gname"
    fi
  done < <(h_anysh_get_features "$@")

  if [ -n "$out" ]; then
    h_info "${out# }"
  else
    local IFS=' '
    h_error -t "no features matched: $*"
    return 1
  fi
}

h_anysh_update_is_default() {
  [ -n "$H_ANYSH_UPDATE_DEFAULT" ]
}

h_anysh_update_is_reset() {
  [ -n "$H_ANYSH_UPDATE_RESET" ]
}

h_anysh_update() {
  h_anysh_check_args_nonzero "$@" || return 1
}

h_anysh_src_is_force() {
  [ -n "$H_ANYSH_SRC_FORCE" ]
}

h_anysh_src() {
  h_anysh_check_args_nonzero "$@" || return 1
}

h_anysh_hsrc() {
  h_anysh_check_args_nonzero "$@" || return 1
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
  h_echo '  -v, --verbose  Display debug log'
  h_echo
  h_echo 'Usage by Command:'
  h_echo '  anysh ls [<features...>]         List installed <features...>, or all features if <features...> not provided'
  h_echo '  anysh ls-remote [<features...>]  List remote <features...> available for update, or all features if <features...> not provided'
  h_echo '  anysh on <features...>           Turn on <features...> and their dependencies'
  h_echo '  anysh off <features...>          Turn off <features...>'
  h_echo '  anysh update <features...>       Update <features...> and their dependencies into the latest version'
  h_echo '    --default                      Update with the default state'
  h_echo '    --reset                        Remove and reinstall anysh'
  h_echo '  anysh src <features...>          Source <features...> and their dependencies using source which sources not-in-order and in-duplicate'
  h_echo '    -f, --force                    Allow to source off-feature'
  h_echo '  anysh hsrc <features...>         Source <features...> and their dependencies using h_source which sources dependencies-first and not-in-duplicate'
  h_echo '    -f, --force                    Allow to source in-duplicate and off-feature'
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
        H_SOURCE_FORCE='true'
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
    'hsrc')      H_SOURCE_ENABLE='true' h_anysh_hsrc "$@" ;;
    *)
      h_error -t "invalid command: $cmd"
      h_anysh_usage
      return 1
      ;;
  esac
}
