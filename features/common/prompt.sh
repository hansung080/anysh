: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_set_prompt_short() {
  if h_is_zsh; then
    setopt 'promptsubst'
    PROMPT='%n@%{$(pwd)%${#PWD}G%}%# '
  else
    if [[ "$(whoami)" == 'root' ]]; then
      export PS1='`whoami`@`pwd`# '
    else
      export PS1='`whoami`@`pwd`$ '
    fi
  fi
}

h_set_prompt_short_color() {
  if h_is_zsh; then
    setopt 'promptsubst'
    PROMPT='%(!.%F{red}.%F{yellow})%n%f@%{$(pwd|grep --color=always /)%${#PWD}G%}%(!.%F{red}.)%#%f '
  else
    if [[ "$(whoami)" == 'root' ]]; then
      export PS1='${H_RED}`whoami`${H_RESET}@`pwd`${H_RED}#${H_RESET} '
    else
      export PS1='${H_YELLOW}`whoami`${H_RESET}@`pwd`$ '
    fi
  fi
}

h_set_prompt_long() {
  if h_is_zsh; then
    setopt 'promptsubst'
    PROMPT='%n@%m:%{$(pwd)%${#PWD}G%}%# '
  else
    if [[ "$(whoami)" == 'root' ]]; then
      export PS1='`whoami`@`hostname`:`pwd`# '
    else
      export PS1='`whoami`@`hostname`:`pwd`$ '
    fi
  fi
}

h_set_prompt_long_color() {
  if h_is_zsh; then
    setopt 'promptsubst'
    PROMPT='%(!.%F{red}.%F{yellow})%n%f@%F{yellow}%m%f:%{$(pwd|grep --color=always /)%${#PWD}G%}%(!.%F{red}.)%#%f '
  else
    if [[ "$(whoami)" == 'root' ]]; then
      export PS1='${H_RED}`whoami`${H_RESET}@${H_YELLOW}`hostname`${H_RESET}:`pwd`${H_RED}#${H_RESET} '
    else
      export PS1='${H_YELLOW}`whoami`${H_RESET}@${H_YELLOW}`hostname`${H_RESET}:`pwd`$ '
    fi
  fi
}

h_set_prompt_help() {
  h_echo 'Usage:'
  h_echo '  h_set_prompt [<type>]'
  h_echo
  h_echo 'Type:'
  h_echo '  short        Set prompt with format `whoami`@`pwd`$'
  h_echo '  short-color  Set prompt with format `whoami`@`pwd`$ and color'
  h_echo '  long         Set prompt with format `whoami`@`hostname`:`pwd`$'
  h_echo '  long-color   Set prompt with format `whoami`@`hostname`:`pwd`$ and color'
  h_echo '  help         Display this help message'
  h_echo '  * Default type is short if <type> is omitted'
  h_echo '  * In prompt, $ for Bash, % for Zsh, and # for root'
}

h_set_prompt_usage() {
  h_error "Run 'h_set_prompt help' for more information on the usage."
}

h_set_prompt() {
  case "$1" in
    'short'|'')    h_set_prompt_short ;;
    'short-color') h_set_prompt_short_color ;;
    'long')        h_set_prompt_long ;;
    'long-color')  h_set_prompt_long_color ;;
    'help')        h_set_prompt_help ;;
    *)
      h_error -t "invalid type: $1"
      h_set_prompt_usage
      return 1
      ;;
  esac
}
