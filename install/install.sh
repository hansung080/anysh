#!/bin/bash

S_RESET=$'\033[0m'
S_RED_BOLD=$'\033[1;31m'
S_YELLOW=$'\033[0;33m'
S_BLUE=$'\033[0;34m'

warn() {
  [[ "$1" == '-t' ]] && { >&2 echo -n "${S_YELLOW}warning${S_RESET}: "; shift; }
  >&2 echo "$@"
}

error() {
  [[ "$1" == '-t' ]] && { >&2 echo -n "${S_RED_BOLD}error${S_RESET}: "; shift; }
  >&2 echo "$@"
}

blue() {
  local opts=()
  while true; do
    case "$1" in
      -*)
        opts+=("$1")
        shift ;;
      *)
        break ;;
    esac
  done
  local IFS=' '
  echo "${opts[@]}" "$S_BLUE$*$S_RESET"
}

confirm() {
  echo -ne "$1"
  IFS=$' \t' read -r answer
  [[ "$answer" == "$2" ]]
}

is_shell_supported() {
  [[ "$1" == 'bash' || "$1" == 'zsh' ]]
}

command_by_pid() {
  ps -p "$1" | tail -1 | awk '{ print $4 }'
}

shell_by_pid() {
  local cmd
  cmd="$(command_by_pid "$1")"
  if [[ "${cmd:0:1}" == '-' ]]; then
    basename "${cmd:1}"
  else
    basename "$cmd"
  fi
}

default_shell() {
  basename "$SHELL"
}

parent_shell() {
  shell_by_pid "$PPID"
}

is_login_shell_by_pid() {
  [[ "$(command_by_pid "$1")" == -* ]] || \
  ps -p "$1" | grep -E -- ' -[^ ]*l[^ ]* | -[^ ]*l[^ ]*$| --login | --login$' > /dev/null
}

shell_config() {
  case "$(parent_shell)" in
    'bash')
      if is_login_shell_by_pid "$PPID"; then
        echo '.bash_profile'
      else
        echo '.bashrc'
      fi
      ;;
    'zsh') echo '.zshrc' ;;
    *) echo '.profile' ;;
  esac
}

replace_home_to_var() {
  if [[ "$1" == "$HOME"* ]]; then
    echo "\$HOME${1#$HOME}"
  else
    echo "$1"
  fi
}

anysh_download() {
  local _path="$1"
  shift
  curl -fsSL "https://raw.githubusercontent.com/hansung080/anysh/main/$_path" "$@"
}

check_optarg() {
  if [[ "$2" == -* ]] || [ -z "$2" ]; then
    error -t "check_optarg: option $1 requires an argument"
    [ -n "$3" ] && "$3"
    return 1
  fi
  return 0
}

usage() {
  error "usage: install.sh [-fp <anysh dir>]"
}

main() {
  local ANYSH_DIR="$HOME/.anysh" PHYSICAL_ANYSH_DIR
  local opt='' OPTIND=1 OPTARG='' opt_force=''
  while getopts ':fp:' opt; do
    case "$opt" in
      'f')
        opt_force='true'
        ;;
      'p')
        check_optarg "-$opt" "$OPTARG" usage || return 1
        ANYSH_DIR="$OPTARG"
        ;;
      '?')
        error -t "illegal option -$OPTARG"
        usage
        return 1
        ;;
      ':')
        error -t "option -$OPTARG requires an argument"
        usage
        return 1
        ;;
    esac
  done

  shift $((OPTIND - 1))

  if [ -n "$opt_force" ]; then
    rm -rf "$ANYSH_DIR"
  else
    if [ -e "$ANYSH_DIR" ]; then
      echo "=> The Anysh directory already exists: $(readlink -f "$ANYSH_DIR")"
      confirm '   Delete it and continue to install Anysh (yes/no) ? ' 'yes' || return 0
      rm -rf "$ANYSH_DIR"
      echo
    fi
  fi
  mkdir -p "$ANYSH_DIR"
  PHYSICAL_ANYSH_DIR="$(readlink -f "$ANYSH_DIR")"

  echo -n "=> Installing Anysh to $PHYSICAL_ANYSH_DIR ... "
  local feature gname rpath
  while IFS=' ' read -r feature _ _; do
    gname="${feature%%/*}"
    [[ "$gname" == "$feature" ]] && gname=''
    if [[ "$gname" == 'hidden' ]]; then
      rpath="$feature"
    else
      rpath="features/$feature"
    fi
    mkdir -p "$(dirname "$ANYSH_DIR/$rpath")" || return 1
    anysh_download "$rpath" -o "$ANYSH_DIR/$rpath" || return 1
  done < <(anysh_download 'list.txt')
  echo 'done'

  echo
  echo "=> To use Anysh, append the following code to \$HOME/$(shell_config) and source it: "
  blue "export H_ANYSH_DIR=\"$(replace_home_to_var "$PHYSICAL_ANYSH_DIR")\""
  blue '[ -s "$H_ANYSH_DIR/hidden/init.sh" ] && source "$H_ANYSH_DIR/hidden/init.sh" --now'

  local newline=''
  if ! is_shell_supported "$(default_shell)"; then
    [ -z "$newline" ] && { echo; newline='true'; }
    warn -t "Your default shell '$(default_shell)' is not supported by Anysh. Only bash and zsh are supported."
  fi

  if ! is_shell_supported "$(parent_shell)"; then
    [ -z "$newline" ] && { echo; newline='true'; }
    warn -t "Your current shell '$(parent_shell)' is not supported by Anysh. Only bash and zsh are supported."
  fi
}

main "$@"
