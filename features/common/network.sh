: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
h_source 'util'

h_networksetup() {
  h_is_mac || { h_error -t 'supported only on macOS'; return 1; }

  if networksetup "$@" &> /dev/null; then
    networksetup "$@"
  else
    networksetup "$@" >&2
  fi
}

h_ssid() {
  local network="${1:-$H_WIFI_DEFAULT_NETWORK}"

  # This code does not work unless Wi-Fi is connected.
  # ```
  # (
  #   set -o pipefail
  #   h_networksetup -getairportnetwork "$network" | awk '{ print $NF }'
  # )
  # ```

  # NOTE: `networksetup -getairportnetwork` no longer works on recent versions of macOS (e.g. Tahoe).
  local output
  output="$(h_networksetup -getairportnetwork "$network")"
  if [[ "$output" == 'Current Wi-Fi Network: '* ]]; then
    h_echo "${output#Current Wi-Fi Network: }"
  else
    h_error -t "$output"
    return 1
  fi
}
