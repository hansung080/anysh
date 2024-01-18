: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_make_sourced() {
  return 0
}

h_make_is_bin() {
  [ -n "$H_MAKE_BIN" ]
}

h_make_is_lib() {
  [ -n "$H_MAKE_LIB" ]
}

h_make_is_project() {
  [ -n "$H_MAKE_PROJECT" ]
}

h_make_is_all() {
  [ -n "$H_MAKE_ALL" ]
}

h_make_update_is_none() {
  [[ -z "$H_MAKE_BIN" && -z "$H_MAKE_LIB" && -z "$H_MAKE_PROJECT" && -z "$H_MAKE_ALL" ]]
}

h_make_check_options() {
  local opts=()
  [ -n "$H_MAKE_BIN" ] && opts+=('--bin')
  [ -n "$H_MAKE_LIB" ] && opts+=('--lib')
  [ -n "$H_MAKE_PROJECT" ] && opts+=('--project')
  [ -n "$H_MAKE_ALL" ] && opts+=('--all')
  [ -n "$H_MAKE_VERBOSE" ] && opts+=('--verbose(-v)')
  [ -n "$H_MAKE_ARGS" ] && opts+=('--args')
  [ -n "$H_MAKE_OLD_PROJECT" ] && opts+=('--old-project')
  [ -n "$H_MAKE_NEW_PROJECT" ] && opts+=('--new-project')
  [ -n "$H_MAKE_STATIC" ] && opts+=('--static')

  local arg
  for arg in "$@"; do
    h_delete_array "$arg" opts
  done

  if ((${#opts[@]} > 0)); then
    h_error -t "invalid options: $(h_join_elems ' ' "${opts[@]}")"
    return 1
  fi
  return 0
}

h_make_download() {
  if (($# < 1)); then
    h_error 'usage: h_make_download <path> [<options...>]'
    return 1
  fi
  h_github_download 'hansung080' 'make-kit' 'main' "$@"
}

h_make_c_main() {
  local content="\
#include <stdio.h>

int main(int argc, char* argv[]) {
    printf(\"Hello, $1!"'\\n'"\");
    return 0;
}"
  h_echo "$content"
}

h_make_new_usage() {
  h_error 'usage: make new <project> [--bin | --lib]'
}

h_make_new() {
  h_make_check_options '--bin' '--lib' || { h_make_new_usage; return 1; }
  (($# == 0)) && { h_error -t 'argument <project> required'; h_make_new_usage; return 1; }
  (($# > 1)) && { h_error -t "too many arguments: $(h_join_elems ' ' "$@")"; h_make_new_usage; return 1; }

  local project="$1" makefile='bin.mk'
  if h_make_is_bin; then
    makefile='bin.mk'
  elif h_make_is_lib; then
    makefile='lib.mk'
  fi

  if [ -e "$project" ]; then
    h_error -t "\`$project\` already exists"
    return 1
  fi

  local type
  mkdir -p "$project/src" "$project/test"
  h_make_download "c-project/$makefile" | sed "s/c-project/$project/g" > "$project/$makefile"
  h_make_download 'c-project/project.mk' | sed "s/bin\.mk/$makefile/g" > "$project/Makefile"
  if [[ "$makefile" == 'bin.mk' ]]; then
    h_make_c_main "$project" > "$project/src/main.c"
    type='binary'
  else
    touch "$project/src/lib.c"
    type='library'
  fi
  h_make_c_main "$project-test" > "$project/test/main.c"

  h_info "Created a $type project \`$project\`"
}

h_make_status_usage() {
  h_error 'usage: make status'
}

h_make_status() {
  h_make_check_options || { h_make_status_usage; return 1; }
  (($# != 0)) && { h_error -t "no arguments required: $(h_join_elems ' ' "$@")"; h_make_status_usage; return 1; }

  local makefiles=('bin.mk' 'lib.mk' 'project.mk') makefile fmax=0 flen
  for makefile in "${makefiles[@]}"; do
    if [ -f "$makefile" ]; then
      flen="${#makefile}"; ((flen > fmax)) && fmax="$flen"
    fi
  done

  local project hash sync fn style
  project="$(basename "$(pwd -P)")"
  for makefile in "${makefiles[@]}"; do
    if [ -f "$makefile" ]; then
      hash="$(h_make_download "c-project/$makefile" | sed "s/c-project/$project/g" | h_md5)"
      sync="$(h_get_sync "$makefile" "$hash")"
      ((fn = fmax - ${#makefile} + 2))
      if [[ "$sync" != 'synced' ]]; then
        style="$H_RED"
      else
        style=''
      fi
      h_echo "$style$makefile$(h_repeat ' ' "$fn")$sync$H_RESET"
    fi
  done
}

h_make_update_usage() {
  h_error 'usage: make update [--bin | --lib | --project | --all]'
}

h_make_update() {
  h_make_check_options '--bin' '--lib' '--project' '--all' || { h_make_update_usage; return 1; }
  (($# != 0)) && { h_error -t "no arguments required: $(h_join_elems ' ' "$@")"; h_make_update_usage; return 1; }

  local project makefiles=() makefile
  project="$(basename "$(pwd -P)")"
  if h_make_update_is_none; then
    for makefile in 'bin.mk' 'lib.mk' 'project.mk'; do
      [ -f "$makefile" ] && makefiles+=("$makefile")
    done
  else
    if h_make_is_all; then
      makefiles+=('bin.mk' 'lib.mk' 'project.mk')
    else
      h_make_is_bin && makefiles+=('bin.mk')
      h_make_is_lib && makefiles+=('lib.mk')
      h_make_is_project && makefiles+=('project.mk')
    fi
  fi

  for makefile in "${makefiles[@]}"; do
    h_make_download "c-project/$makefile" | sed "s/c-project/$project/g" > "$makefile"
  done

  if ((${#makefiles[@]} > 0)); then
    h_info "Updated $(h_join_elems ' ' "${makefiles[@]}")"
  else
    h_info 'Updated nothing'
  fi
}

h_make_help() {
  h_echo 'Usage:'
  h_echo '  make [<options...>] [<targets...>]'
  h_echo
  h_echo 'Options:'
  h_echo '  --helpx  Display this help message'
  h_echo
  h_echo 'Usage by Targets:'
  h_echo '  make new <project>   Create a <project>, default: --bin'
  h_echo '    --bin              Create a binary project'
  h_echo '    --lib              Create a library project'
  h_echo '  make status          Check if local makefiles are up-to-date'
  h_echo '  make update          Download bin.mk, lib.mk, or project.mk if they exist in the local directory'
  h_echo '    --bin              Download bin.mk regardless of its existence'
  h_echo '    --lib              Download lib.mk regardless of its existence'
  h_echo '    --project          Download project.mk regardless of its existence'
  h_echo '    --all              Download bin.mk, lib.mk, and project.mk regardless of their existence'
  h_echo '  make [build]         Build the project, [build] can be omitted'
  h_echo '    -v, --verbose      Display stdout for build, default: no stdout'
  h_echo "                       CAUTION: -v is also used by command make. Thus, 'make --version' can be used for 'command make -v'."
  h_echo '    --static           Build a static library for a library project, default: dynamic library'
  h_echo '  make run             Build and run the project'
  h_echo '    --args <args>      Pass <args> to the program'
  h_echo '  make test            Build and test the project'
  h_echo '    --args <args>      Pass <args> to the test-program'
  h_echo '  make clean           Clean the project'
  h_echo '  make rename-project  Rename the project in test code'
  h_echo '    --old-project <name>  Specify the old project name'
  h_echo '    --new-project <name>  Specify the new project name'
  h_echo '  make version         Display the version of the makefile'
  h_echo '  make var             Display variables defined in the makefile (for debugging)'
  h_echo '  make env             Display environment variables used in the makefile (for debugging)'
  h_echo '  make all             Build all projects including dependent projects'
  h_echo '  make clean-all       Clean all projects including dependent projects'
  h_echo '  make ext             Display extended variables defined in project.mk (for debugging)'
}

h_make_usage() {
  h_error "Run 'make --helpx' for more information on the usage."
}

make() {
  local H_MAKE_BIN=
  local H_MAKE_LIB=
  local H_MAKE_PROJECT=
  local H_MAKE_ALL=
  local H_MAKE_VERBOSE=
  local H_MAKE_ARGS=
  local H_MAKE_ARGS_ARG=
  local H_MAKE_OLD_PROJECT=
  local H_MAKE_OLD_PROJECT_ARG=
  local H_MAKE_NEW_PROJECT=
  local H_MAKE_NEW_PROJECT_ARG=
  local H_MAKE_STATIC=

  local args=() optarg=''
  while (($# > 0)); do
    case "$1" in
      '--helpx')
        h_make_help
        return ;;
      '--bin')
        H_MAKE_BIN='true'
        shift ;;
      '--lib')
        H_MAKE_LIB='true'
        shift ;;
      '--project')
        H_MAKE_PROJECT='true'
        shift ;;
      '--all')
        H_MAKE_ALL='true'
        shift ;;
      '-v'|'--verbose')
        H_MAKE_VERBOSE='true'
        shift ;;
      '--args'|'--args='*)
        H_MAKE_ARGS='true'
        if [[ "$1" == *=* ]]; then
          optarg="${1#*=}"
          shift
        else
          optarg="$2"
          h_check_optarg_notdash_notnull "$1" "$optarg" h_make_usage || return 1
          shift 2
        fi
        H_MAKE_ARGS_ARG="$optarg"
        ;;
      '--old-project'|'--old-project='*)
        H_MAKE_OLD_PROJECT='true'
        if [[ "$1" == *=* ]]; then
          optarg="${1#*=}"
          h_check_optarg_notnull "${1%%=*}" "$optarg" h_make_usage || return 1
          shift
        else
          optarg="$2"
          h_check_optarg_notdash_notnull "$1" "$optarg" h_make_usage || return 1
          shift 2
        fi
        H_MAKE_OLD_PROJECT_ARG="$optarg"
        ;;
      '--new-project'|'--new-project='*)
        H_MAKE_NEW_PROJECT='true'
        if [[ "$1" == *=* ]]; then
          optarg="${1#*=}"
          h_check_optarg_notnull "${1%%=*}" "$optarg" h_make_usage || return 1
          shift
        else
          optarg="$2"
          h_check_optarg_notdash_notnull "$1" "$optarg" h_make_usage || return 1
          shift 2
        fi
        H_MAKE_NEW_PROJECT_ARG="$optarg"
        ;;
      '--static')
        H_MAKE_STATIC='true'
        shift ;;
      '--')
        args+=("$@")
        break ;;
      *)
        args+=("$1")
        shift ;;
    esac
  done

  set -- "${args[@]}"

  if [[ "$1" == 'new' || "$1" == 'status' || "$1" == 'update' ]]; then
    args=()
    while (($# > 0)); do
      case "$1" in
        --)
          shift
          args+=("$@")
          break ;;
        -*)
          h_error -t "invalid option: $1"
          h_make_usage
          return 1 ;;
        *)
          args+=("$1")
          shift ;;
      esac
    done
    set -- "${args[@]}"
  fi

  case "$1" in
    'new')    h_make_new "${@:2}" ;;
    'status') h_make_status "${@:2}" ;;
    'update') h_make_update "${@:2}" ;;
    *)
      __verbose="$H_MAKE_VERBOSE" \
      __args="$H_MAKE_ARGS_ARG" \
      __old_project="$H_MAKE_OLD_PROJECT_ARG" \
      __new_project="$H_MAKE_NEW_PROJECT_ARG" \
      __static="$H_MAKE_STATIC" \
      command make "$@" ;;
  esac
}
