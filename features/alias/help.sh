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
  h_is_zsh || return 1
  unalias run-help 2> /dev/null
  autoload -Uz run-help
  if [[ "$(h_which 'zsh')" == "$(command brew --prefix)"* ]]; then
    HELPDIR="$(command brew --prefix)/share/zsh/help"
  else
    HELPDIR="/usr/share/zsh/$ZSH_VERSION/help"
  fi
  alias help='run-help'
}

h_unalias_help() {
  h_is_zsh || return 1
  unalias help 2> /dev/null
  unset -f run-help 2> /dev/null
  HELPDIR=
  alias run-help='man'
}
