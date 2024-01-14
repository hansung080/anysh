: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_make_sourced() {
  return 0
}

h_make_check_args() {
  local project="$1"
  local type="$2"
  local usage="usage: $3 <project> [bin | lib]"

  if [[ "$project" == '' ]]; then
    h_echo -e "$H_ERROR: <project> not provided"
    h_echo "$usage"
    return 1
  fi

  if [[ "$type" != 'bin' ]] && [[ "$type" != 'lib' ]]; then
    h_echo -e "$H_ERROR: <type> must be either bin or lib"
    h_echo "$usage"
    return 1
  fi
  return 0
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

h_make_new() {
  local project="$1"
  local type="$2"
  if ! h_make_check_args "$project" "$type" 'h_make_new'; then
    return 1
  fi

  mkdir -p "$project/src" "$project/test"
  local makefile="$type.mk"
  curl -fsSL "https://raw.githubusercontent.com/hansung080/study/master/c/examples/make-sample/$makefile" | sed "s/make-sample/$project/g" > "$project/$makefile"
  curl -fsSL 'https://raw.githubusercontent.com/hansung080/study/master/c/examples/make-sample/project.mk' | sed "s/bin\.mk/$makefile/g" > "$project/Makefile"
  h_make_c_main "$project-test" > "$project/test/main.c"
  if [[ "$type" == 'bin' ]]; then
    h_make_c_main "$project" > "$project/src/main.c"
  else
    touch "$project/src/lib.c"
  fi
}

h_make_update() {
  local project="$1"
  local type="$2"
  if ! h_make_check_args "$project" "$type" 'h_make_update'; then
    return 1
  fi

  local makefile="$type.mk"
  curl -fsSL "https://raw.githubusercontent.com/hansung080/study/master/c/examples/make-sample/$makefile" | sed "s/make-sample/$project/g" > "$makefile"
}

alias makev='make __verbose=true'

h_make_help() {
  h_echo 'Usage:'
  h_echo '  make [<options...>] [<targets...>]'
  h_echo
  h_echo 'Options:'
  h_echo '  --helpx        Display this help message'
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
