{ pkgs, ... }:

let
  opencodeWaybarDaemon = pkgs.writeShellScriptBin "opencode-waybar-daemon" ''
    set -uo pipefail

    log_dir="''${OPENCODE_LOG_DIR:-$HOME/.local/share/opencode/log}"
    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/opencode"
    state_file="$state_dir/waybar-status.json"

    mkdir -p "$state_dir"

    declare -A seen
    declare -A client_state
    declare -A client_session
    declare -A client_step

    write_state() {
      local open=0
      local busy=0
      local idle=0
      local tooltip=""
      local line=""

      for client in "''${!client_state[@]}"; do
        case "''${client_state[$client]}" in
          busy)
            open=$((open + 1))
            busy=$((busy + 1))
            line="$client  busy"
            if [ -n "''${client_step[$client]:-}" ]; then
              line="$line step ''${client_step[$client]}"
            fi
            ;;
          idle)
            open=$((open + 1))
            idle=$((idle + 1))
            line="$client  idle"
            ;;
          *)
            continue
            ;;
        esac

        if [ -n "''${client_session[$client]:-}" ]; then
          line="$line  ''${client_session[$client]}"
        fi

        if [ -n "$tooltip" ]; then
          tooltip="$tooltip"$'\n'"$line"
        else
          tooltip="$line"
        fi
      done

      local text=""
      local class="empty"
      local summary="opencode: no clients"

      if [ "$open" -gt 0 ]; then
        summary="opencode: $open client"
        [ "$open" -eq 1 ] || summary="$summary"s
        summary="$summary, $busy busy, $idle idle"

        if [ "$busy" -gt 0 ]; then
          text="OC $busy/$open"
          class="busy"
        else
          text="OC $open"
          class="idle"
        fi

        tooltip="$summary"$'\n'"$tooltip"
      else
        tooltip="$summary"
      fi

      ${pkgs.jq}/bin/jq -cn \
        --arg text "$text" \
        --arg tooltip "$tooltip" \
        --arg class "$class" \
        '{text: $text, tooltip: $tooltip, class: $class}' \
        > "$state_file.tmp"
      mv "$state_file.tmp" "$state_file"
    }

    close_client() {
      local client="$1"
      unset "client_state[$client]"
      unset "client_session[$client]"
      unset "client_step[$client]"
    }

    handle_line() {
      local client="$1"
      local line="$2"

      if [[ "$line" == *"session.updated subscribing"* ]]; then
        client_state[$client]="idle"
      elif [[ "$line" == *"worker shutting down"* ]]; then
        close_client "$client"
      elif [[ "$line" == *"session.updated unsubscribing"* ]]; then
        close_client "$client"
      elif [[ "$line" == *"service=session.prompt"* && "$line" == *"exiting loop"* ]]; then
        :
      elif [[ "$line" == *"session.idle publishing"* ]]; then
        if [ -n "''${client_state[$client]:-}" ]; then
          client_state[$client]="idle"
          unset "client_step[$client]"
        fi
      elif [[ "$line" == *"service=session.prompt"* && "$line" == *"step="* && "$line" == *" loop"* ]]; then
        local sid="''${line#*session.id=}"
        sid="''${sid%% *}"
        local step="''${line#*step=}"
        step="''${step%% *}"

        client_state[$client]="busy"
        client_session[$client]="$sid"
        client_step[$client]="$step"
      fi
    }

    process_file() {
      local file="$1"
      local current="$2"
      local last="''${seen[$file]:-0}"
      local client="''${file##*/}"
      client="''${client%.log}"

      if [ "$current" -le "$last" ]; then
        return
      fi

      while IFS= read -r line; do
        handle_line "$client" "$line"
      done < <(${pkgs.gnused}/bin/sed -n "$((last + 1)),''${current}p" "$file")

      seen[$file]="$current"
    }

    shopt -s nullglob
    for file in "$log_dir"/*.log; do
      [ -f "$file" ] || continue
      seen[$file]=$(${pkgs.coreutils}/bin/wc -l < "$file")
    done
    shopt -u nullglob

    write_state

    while true; do
      changed=0

      shopt -s nullglob
      for file in "$log_dir"/*.log; do
        [ -f "$file" ] || continue
        current=$(${pkgs.coreutils}/bin/wc -l < "$file")
        old="''${seen[$file]:-0}"
        process_file "$file" "$current"
        if [ "$current" -ne "$old" ]; then
          changed=1
        fi
      done
      shopt -u nullglob

      for file in "''${!seen[@]}"; do
        if [ ! -e "$file" ]; then
          client="''${file##*/}"
          client="''${client%.log}"
          close_client "$client"
          unset "seen[$file]"
          changed=1
        fi
      done

      if [ "$changed" -eq 1 ]; then
        write_state
        ${pkgs.procps}/bin/pkill -x -RTMIN+9 waybar >/dev/null 2>&1 || true
      fi

      sleep 0.2
    done
  '';

  waybarOpencode = pkgs.writeShellScriptBin "waybar-opencode" ''
    state_file="''${XDG_STATE_HOME:-$HOME/.local/state}/opencode/waybar-status.json"

    if [ -s "$state_file" ]; then
      ${pkgs.jq}/bin/jq -c '
        if type == "object" and has("text") and has("class") then
          .
        else
          {text: "", tooltip: "opencode: no clients", class: "empty"}
        end
      ' "$state_file" 2>/dev/null || ${pkgs.jq}/bin/jq -cn '{text: "", tooltip: "opencode: no clients", class: "empty"}'
    else
      ${pkgs.jq}/bin/jq -cn '{text: "", tooltip: "opencode: no clients", class: "empty"}'
    fi
  '';
in

{
  home.packages = [
    opencodeWaybarDaemon
    waybarOpencode
  ];

  systemd.user.services.opencode-waybar = {
    Unit = {
      Description = "opencode Waybar status daemon";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };

    Service = {
      ExecStart = "${opencodeWaybarDaemon}/bin/opencode-waybar-daemon";
      Restart = "always";
      RestartSec = 1;
    };

    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
