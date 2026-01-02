# Anysh

Anysh is a versatile CLI utility built from modular shell functions.

Each function is either:
- a standalone utility, or
- an extension of an existing shell command.

A collection of functions is called a **feature**, and a collection of features is called a **group**.

With Anysh, you can list available features, enable or disable them, and update them as needed.
It lets you selectively enable extended shell features without permanently overriding existing shell commands.

For example, the `cd` feature extends the original `cd` command by adding directory history tracking.
When the `cd` feature is enabled, the extended version is used.
When it is disabled, the original `cd` command behaves as usual.

## Supported Shells

Anysh currently supports the following shells:
- Bash
- Zsh

Other shells are not fully supported, and some features may not work as expected.

## Installation

To install Anysh to `$HOME/.anysh`, run:

```sh
curl -fsSL 'https://raw.githubusercontent.com/hansung080/anysh/main/install/install.sh' \
  | bash -s -- -f
``` 

To install Anysh to a custom directory (`<anysh-dir>`), run:

```sh
curl -fsSL 'https://raw.githubusercontent.com/hansung080/anysh/main/install/install.sh' \
  | bash -s -- -fp <anysh-dir>
```

After installation, append the following code to your shell profile file
(`~/.bashrc`, `~/.bash_profile`, `~/.zshrc`, or `~/.profile`) and source it:

```sh
# This overrides the default hostname in the prompt if set (optional). 
H_PROMPT_HOSTNAME=<hostname>

# This is required for Anysh to work. 
export H_ANYSH_DIR="$HOME/.anysh"
[ -s "$H_ANYSH_DIR/hidden/init.sh" ] && source "$H_ANYSH_DIR/hidden/init.sh" --now
```

If you installed Anysh to a custom directory, set `H_ANYSH_DIR` accordingly:

```sh
export H_ANYSH_DIR=<anysh-dir>
```

## Usage

For usage information, run:

```sh
anysh --help
```
