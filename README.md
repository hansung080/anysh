# Anysh
Anysh is a versatile CLI utility composed of various shell functions. These functions consist of independent functions
and extended functions which extended from existing commands. A group of functions is called a feature, and a group of
feature is called a group. Using Anysh, you can see the list of features, turn on/off features, and update features.
For instance, the cd function is extended from the cd command and additionally has the history tracking ability. If you
turn on cd, you will use the cd with history tracking ability, and if you turn off cd, you will use the original cd.

## Supported Shells
Anysh supports only the following shells at the moment. If you are using another shell, Some features of Anysh will not
work.
- Bash
- Zsh

## Install Anysh
To install Anysh to `$HOME/.anysh`, run:
```sh
curl -fsSL 'https://raw.githubusercontent.com/hansung080/anysh/main/install/install.sh' | bash
``` 

Or, to install Anysh to the `<anysh dir>` you specified, run:
```sh
curl -fsSL 'https://raw.githubusercontent.com/hansung080/anysh/main/install/install.sh' | bash -s -- -p <anysh dir>
```

After installation, to use Anysh, append the following code to your shell profile such as .bashrc, .bash_profile, .zshrc
, etc. and source it. If you specified the <anysh dir> when installation, you must modify it as `export H_ANYSH_DIR="<anysh dir>"`
in the following code:
```sh
export H_ANYSH_DIR="$HOME/.anysh"
[ -s "$H_ANYSH_DIR/hidden/init.sh" ] && source "$H_ANYSH_DIR/hidden/init.sh"
```

## How to use Anysh
To learn how to use Anysh, run:
```sh
anysh --help
```
