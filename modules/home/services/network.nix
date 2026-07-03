{ pkgs, ... }:

{
  home.packages = with pkgs; [
    iw

    (writeShellScriptBin "waybar-network" ''
      PRIMARY=""
      PHYSICAL=""
      VPN=""
      CONTAINERS=""
      OTHER=""

      WIRED_PRIMARY=""
      WIFI_PRIMARY=""
      VPN_PRIMARY=""

      append_line() {
        group="$1"
        line="$2"

        case "$group" in
          physical)
            [ -n "$PHYSICAL" ] && PHYSICAL="$PHYSICAL"$'\n'"$line" || PHYSICAL="$line"
            ;;
          vpn)
            [ -n "$VPN" ] && VPN="$VPN"$'\n'"$line" || VPN="$line"
            ;;
          containers)
            [ -n "$CONTAINERS" ] && CONTAINERS="$CONTAINERS"$'\n'"$line" || CONTAINERS="$line"
            ;;
          other)
            [ -n "$OTHER" ] && OTHER="$OTHER"$'\n'"$line" || OTHER="$line"
            ;;
        esac
      }

      append_group() {
        title="$1"
        body="$2"

        [ -z "$body" ] && return
        [ -n "$TOOLTIP" ] && TOOLTIP="$TOOLTIP"$'\n\n'
        TOOLTIP="$TOOLTIP$title"$'\n'"$body"
      }

      connection_detail() {
        if [ -n "$1" ]; then
          printf '%s' "$1"
        elif [ "$2" = "UP" ] || [ "$2" = "UNKNOWN" ]; then
          printf 'up'
        else
          printf 'down'
        fi
      }

      wifi_ssid() {
        ssid=""
        while IFS= read -r line; do
          case "$line" in
            *SSID:*)
              ssid="''${line#*SSID: }"
              break
              ;;
          esac
        done < <(${iw}/bin/iw dev "$1" link 2>/dev/null)
        printf '%s' "$ssid"
      }

      while IFS=$'\t' read -r iface state link_type ipv4; do
        [ -z "$iface" ] && continue

        case "$iface" in
          lo|p2p-dev-*)
            continue
            ;;
        esac

        detail=$(connection_detail "$ipv4" "$state")

        case "$iface" in
          wl*)
            ssid=$(wifi_ssid "$iface")
            label="''${ssid:-$iface}"
            append_line physical "󰤨 $iface  $label  $detail"
            if [ -z "$WIFI_PRIMARY" ] && [ "$state" != "DOWN" ] && [ -n "$ipv4" ]; then
              WIFI_PRIMARY="󰤨 $label"
            fi
            ;;
          eth*|en*)
            append_line physical "󰈀 $iface  $detail"
            if [ -z "$WIRED_PRIMARY" ] && [ "$state" != "DOWN" ] && [ -n "$ipv4" ]; then
              WIRED_PRIMARY="󰈀 $iface"
            fi
            ;;
          tailscale*|tun*|wg*)
            if [ "$iface" = "tailscale0" ] && [ -z "$ipv4" ] && command -v tailscale >/dev/null 2>&1; then
              IFS= read -r ipv4 < <(tailscale ip -4 2>/dev/null || true)
              detail=$(connection_detail "$ipv4" "$state")
            fi

            append_line vpn "󰱦 $iface  $detail"
            if [ -z "$VPN_PRIMARY" ] && [ "$state" != "DOWN" ]; then
              VPN_PRIMARY="󰱦 $iface"
            fi
            ;;
          docker*|br-*|veth*|virbr*|podman*|cni*)
            append_line containers "󰡨 $iface  $detail"
            ;;
          *)
            if [ -e "/sys/class/net/$iface/device" ] && [ "$link_type" = "ether" ]; then
              append_line physical "󰈀 $iface  $detail"
            else
              append_line other "󰛳 $iface  $detail"
            fi
            ;;
        esac
      done < <(
        ${iproute2}/bin/ip -j addr \
          | ${jq}/bin/jq -r '.[] | [.ifname, .operstate, .link_type, ([.addr_info[]? | select(.family == "inet" and .scope == "global") | .local] | join(","))] | @tsv'
      )

      if [ -n "$WIRED_PRIMARY" ]; then
        PRIMARY="$WIRED_PRIMARY"
      elif [ -n "$WIFI_PRIMARY" ]; then
        PRIMARY="$WIFI_PRIMARY"
      elif [ -n "$VPN_PRIMARY" ]; then
        PRIMARY="$VPN_PRIMARY"
      else
        PRIMARY="󰤭"
      fi

      TOOLTIP=""
      append_group "Physical" "$PHYSICAL"
      append_group "VPN" "$VPN"
      append_group "Containers" "$CONTAINERS"
      append_group "Other" "$OTHER"

      [ -n "$TOOLTIP" ] || TOOLTIP="disconnected"
      ${jq}/bin/jq -cn --arg text "$PRIMARY" --arg tooltip "$TOOLTIP" '{text: $text, tooltip: $tooltip}'
    '')
  ];
}
