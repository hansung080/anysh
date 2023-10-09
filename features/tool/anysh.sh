: "${H_ANYSH_DIR:=$HOME/.anyshrc.d}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

H_ANYSH_VERSION='1.0.0'
H_FEATURES_DIR="$H_ANYSH_DIR/features"

h_is_anysh_sourced() {
  return 0
}

h_anysh_get_groups() {
  find "$H_FEATURES_DIR" -depth 1 -type d -name "${1:-*}" -exec basename {} \;
}

h_anysh_get_features() {
  local target="$1"
  case "$target" in
    ''|'*')
      find "$H_FEATURES_DIR" -type f -name '*.sh' -exec expr 'X{}' : "X$H_FEATURES_DIR/\(.*\)" \;
      ;;
    :*)
      target="${target:1}"
      local group groups=()
      while IFS= read -r group; do
        groups+=("$H_FEATURES_DIR/$group")
      done < <(h_anysh_get_groups "$target")
      if ((${#groups[@]} == 0)); then
        h_error -t "invalid group: $target"
        return 1
      fi
      find "${groups[@]}" -type f -name '*.sh' -exec expr 'X{}' : "X$H_FEATURES_DIR/\(.*\)" \;
      ;;
    *)
      if ! find "$H_FEATURES_DIR" -type f \( -name "$target.sh" -o -name ".$target.sh" \) -exec expr 'X{}' : "X$H_FEATURES_DIR/\(.*\)" \; | grep '.'; then
        h_error -t "invalid feature: $target"
        return 1
      fi
      ;;
  esac
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

h_anysh_ls() {
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
  done < <(h_anysh_get_features "$1")

  local gn fn sn
  ((gn = gmax - ${#t_gname} + 2))
  ((fn = fmax - ${#t_fname} + 2))
  ((sn = smax - ${#t_state} + 2))
  h_echo "$t_gname$(h_repeat ' ' "$gn")$t_fname$(h_repeat ' ' "$fn")$t_state$(h_repeat ' ' "$sn")$t_deps"

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
  :
}

h_anysh_on() {
  local IFS=$'\n'
  local feature="$1" file base fname
  for file in $(h_anysh_find_features); do
    base="$(basename "$file")"
    fname="${base#*-}"
    fname="${fname%.sh}"
    if [[ "$fname" == "$feature" ]]; then
      if [[ "${base:0:1}" == '.' ]]; then
        mv "$file" "$(dirname "$file")/${base#.}"
        h_echo "$feature is turned on"
      else
        h_echo "$feature is already on"
      fi
      return 0
    fi
  done
  h_error -t "$feature not found"
  return 1
}

h_anysh_off() {
  local IFS=$'\n'
  local feature="$1" file base fname
  for file in $(h_anysh_find_features); do
    base="$(basename "$file")"
    fname="${base#*-}"
    fname="${fname%.sh}"
    if [[ "$fname" == "$feature" ]]; then
      if [[ "${base:0:1}" == '.' ]]; then
        h_echo "$feature is already off"
      else
        mv "$file" "$(dirname "$file")/.$base"
        h_echo "$feature is turned off"
      fi
      return 0
    fi
  done
  h_error -t "$feature not found"
  return 1
}

h_anysh_update() {
  :
}

h_anysh_usage() {
  h_error "Run 'anysh help' for more information on the usage."
}

h_anysh_help() {
  h_echo 'Usage:'
  h_echo '  anysh [<options...>] <command> [<arguments...>]'
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
  local cmd="$1"
  shift
  case "$cmd" in
    'ls')        h_anysh_ls "$@";;
    'ls-remote') h_anysh_ls_remote "$@";;
    'on')        h_anysh_on "$@";;
    'off')       h_anysh_off "$@";;
    'update')    h_anysh_update "$@";;
    'version')   h_echo "$H_ANYSH_VERSION";;
    'help')      h_anysh_help;;
    *)
      h_error -t "invalid command: $cmd"
      h_anysh_usage
      return 1
      ;;
  esac
}
