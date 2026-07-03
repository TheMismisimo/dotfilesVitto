{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cliphist
    wl-clipboard

    (pkgs.writeShellScriptBin "rofi-cliphist" ''
      THUMB_DIR="/tmp/cliphist-thumbs"
      mkdir -p "$THUMB_DIR"

      mapfile -t lines < <(cliphist list)

      idx=$(
        for line in "''${lines[@]}"; do
          id=$(printf '%s' "$line" | cut -f1)
          content=$(printf '%s' "$line" | cut -f2-)

          if printf '%s' "$content" | grep -qE '^\[\[ binary data'; then
            info=$(printf '%s' "$content" | sed 's/\[\[ binary data \(.*\) \]\]/\1/')
            thumb="$THUMB_DIR/''${id}.png"

            if [ ! -f "$thumb" ]; then
              printf '%s\n' "$line" | cliphist decode \
                | magick - -thumbnail 64x64^ -gravity center -extent 64x64 PNG:"$thumb" 2>/dev/null
            fi

            if [ -f "$thumb" ]; then
              printf 'Image: %s\x00icon\x1f%s\n' "$info" "$thumb"
            else
              printf 'Image: %s\n' "$info"
            fi
          else
            printf '%s\n' "$content"
          fi
        done | rofi -dmenu \
            -theme ~/.config/rofi/clipboard.rasi \
            -show-icons \
            -icon-size 48 \
            -format i
      )

      [ -z "$idx" ] && exit 0
      printf '%s\n' "''${lines[$idx]}" | cliphist decode | wl-copy
    '')
  ];

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "wl-paste --type text  --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
    ];

    bind = [
      "$mod SHIFT, V, exec, rofi-cliphist"
    ];
  };
}
