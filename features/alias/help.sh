: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_is_help_sourced() {
  return 0
}

h_on_source_help() {
  h_alias_help
}

h_on_unset_help() {
  h_unalias_help
}

h_alias_help() {
  h_is_zsh || return 0
  unalias run-help 2> /dev/null
  autoload -Uz run-help
  local brew
  if brew="$(h_which 'brew')" && [[ "$(h_which 'zsh')" == "$("$brew" --prefix)"* ]]; then
    HELPDIR="$("$brew" --prefix)/share/zsh/help"
  else
    HELPDIR="/usr/share/zsh/$ZSH_VERSION/help"
  fi
  alias help='run-help'
}

h_unalias_help() {
  h_is_zsh || return 0
  unalias help 2> /dev/null
  unset -f run-help 2> /dev/null
  HELPDIR=
  alias run-help='man'
}
