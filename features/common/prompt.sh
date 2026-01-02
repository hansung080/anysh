: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

: "${H_PROMPT_SOURCED_ONCE:=}" # Do not unset
: "${H_PROMPT_HOSTNAME:=}"     # Do not unset

h_is_prompt_sourced() {
  return 0
}

h_on_source_prompt() {
  if [ -z "$H_PROMPT_SOURCED_ONCE" ]; then
    H_PROMPT_SOURCED_ONCE='true'
    h_set_prompt 'default'
  fi
}

h_prompt_username_color() {
  if is_root; then
    h_echo -n "\[${H_RED}\]"
  else
    h_echo -n "\[${H_YELLOW}\]"
  fi
}

h_prompt_suffix_color() {
  if is_root; then
    h_echo -n "\[${H_RED}\]"
  fi
}

h_set_prompt_help() {
  h_echo 'Usage:'
  h_echo '  h_set_prompt <format>'
  h_echo
  h_echo 'Formats:'
  h_echo '  stp, short-tilde-plain          Short prompt with tilde-prefixed path, plain output'
  h_echo '  stc, short-tilde-color          Short prompt with tilde-prefixed path, colored output'
  h_echo '  sap, short-absolute-plain       Short prompt with absolute path, plain output'
  h_echo '  sac, short-absolute-color       Short prompt with absolute path, colored output'
  h_echo '  ltp, long-tilde-plain, default  Long prompt with tilde-prefixed path, plain output'
  h_echo '  ltc, long-tilde-color           Long prompt with tilde-prefixed path, colored output'
  h_echo '  lap, long-absolute-plain        Long prompt with absolute path, plain output'
  h_echo '  lac, long-absolute-color        Long prompt with absolute path, colored output'
  h_echo '  lac2, long-absolute-color2      Long prompt with absolute path, advanced colored output'
  h_echo
  h_echo 'Notes:'
  h_echo '  - Each part of <format> represents the following:'
  h_echo
  h_echo '    short     Short prompt (<hostname>:<pwd>$ )'
  h_echo '    long      Long prompt (<username>@<hostname>:<pwd>$ )'
  h_echo '    tilde     Tilde-prefixed path (e.g. ~/work)'
  h_echo '    absolute  Absolute path (e.g. /Users/alice/work)'
  h_echo '    plain     Plain output (no color)'
  h_echo '    color     Colored output'
  h_echo
  h_echo '  - H_PROMPT_HOSTNAME overrides the default <hostname> in the prompt if set (e.g. H_PROMPT_HOSTNAME=local).'
  h_echo "  - The prompt suffix is '$' for Bash, '%' for Zsh, and '#' for root."
}

h_set_prompt_usage() {
  h_error 'usage: h_set_prompt <format>'
  h_error "Run 'h_set_prompt' for more information."
}

h_set_prompt_bash() {
  local reset="\[${H_RESET}\]"
  local yellow="\[${H_YELLOW}\]"

  # Escape characters (\$, \\) are used to prevent interpretation in a double-quoted string.
  case "$1" in
    'stp'|'short-tilde-plain')
      PS1="${H_PROMPT_HOSTNAME:-\h}:\w\\$ "
      ;;
    'stc'|'short-tilde-color')
      PS1="${yellow}${H_PROMPT_HOSTNAME:-\h}${reset}:\w\\$ "
      ;;
    'sap'|'short-absolute-plain')
      PS1="${H_PROMPT_HOSTNAME:-\h}:\${PWD}\\$ "
      ;;
    'sac'|'short-absolute-color')
      PS1="${yellow}${H_PROMPT_HOSTNAME:-\h}${reset}:\${PWD}\\$ "
      ;;
    'ltp'|'long-tilde-plain'|'default')
      PS1="\u@${H_PROMPT_HOSTNAME:-\h}:\w\\$ "
      ;;
    'ltc'|'long-tilde-color')
      PS1="$(h_prompt_username_color)\u${reset}@${yellow}${H_PROMPT_HOSTNAME:-\h}${reset}:\w\\$ "
      ;;
    'lap'|'long-absolute-plain')
      PS1="\u@${H_PROMPT_HOSTNAME:-\h}:\${PWD}\\$ "
      ;;
    'lac'|'long-absolute-color')
      PS1="$(h_prompt_username_color)\u${reset}@${yellow}${H_PROMPT_HOSTNAME:-\h}${reset}:\${PWD}\\$ "
      ;;
    'lac2'|'long-absolute-color2')
      # Bash cannot colorize $PWD: no prompt-length adjustment for ANSI SGR sequences, unlike Zsh (%<length>G).
      PS1="$(h_prompt_username_color)\u${reset}@${yellow}${H_PROMPT_HOSTNAME:-\h}${reset}:\${PWD}$(h_prompt_suffix_color)\\$\[${H_RESET}\] "
      ;;
    *)
      h_error -t "invalid format: $1"
      h_set_prompt_usage
      return 1
      ;;
  esac
}

h_set_prompt_zsh() {
  # Escape characters (\$, \!) are used to prevent interpretation in a double-quoted string.
  case "$1" in
    'stp'|'short-tilde-plain')
      PROMPT="${H_PROMPT_HOSTNAME:-%m}:%~%# "
      ;;
    'stc'|'short-tilde-color')
      PROMPT="%F{yellow}${H_PROMPT_HOSTNAME:-%m}%f:%~%# "
      ;;
    'sap'|'short-absolute-plain')
      PROMPT="${H_PROMPT_HOSTNAME:-%m}:%d%# "
      ;;
    'sac'|'short-absolute-color')
      PROMPT="%F{yellow}${H_PROMPT_HOSTNAME:-%m}%f:%d%# "
      ;;
    'ltp'|'long-tilde-plain'|'default')
      PROMPT="%n@${H_PROMPT_HOSTNAME:-%m}:%~%# "
      ;;
    'ltc'|'long-tilde-color')
      PROMPT="%(\!.%F{red}.%F{yellow})%n%f@%F{yellow}${H_PROMPT_HOSTNAME:-%m}%f:%~%# "
      ;;
    'lap'|'long-absolute-plain')
      PROMPT="%n@${H_PROMPT_HOSTNAME:-%m}:%d%# "
      ;;
    'lac'|'long-absolute-color')
      PROMPT="%(\!.%F{red}.%F{yellow})%n%f@%F{yellow}${H_PROMPT_HOSTNAME:-%m}%f:%d%# "
      ;;
    'lac2'|'long-absolute-color2')
      setopt 'promptsubst'
      if h_is_gnu_grep; then # GNU grep (Linux default)
        PROMPT="%(\!.%F{red}.%F{yellow})%n%f@%F{yellow}${H_PROMPT_HOSTNAME:-%m}%f:%{\$(pwd | GREP_COLORS=ms=33 grep --color=always /)%\${#PWD}G%}%(\!.%F{red}.)%#%f "
      else # BSD grep (macOS default)
        PROMPT="%(\!.%F{red}.%F{yellow})%n%f@%F{yellow}${H_PROMPT_HOSTNAME:-%m}%f:%{\$(pwd | GREP_COLOR=33 grep --color=always /)%\${#PWD}G%}%(\!.%F{red}.)%#%f "
      fi
      ;;
    *)
      h_error -t "invalid format: $1"
      h_set_prompt_usage
      return 1
      ;;
  esac
}

h_set_prompt() {
  if (($# == 0)); then
    h_set_prompt_help
    return
  fi

  if h_is_zsh; then
    h_set_prompt_zsh "$@"
  else
    h_set_prompt_bash "$@"
  fi
}
