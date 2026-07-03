{ pkgs, ... }:

{
  home.packages = with pkgs; [
    rofi
    (writeShellScriptBin "rofi-powermenu" ''
      lastlogin="$(last $USER | head -n1 | tr -s ' ' | cut -d' ' -f5,6,7)"
      uptime="$(uptime -p | sed 's/up //')"
      host="$(hostname)"

      shutdown='󰐥'
      reboot='󰑙'
      suspend=''
      logout='󰍃'
      lock='󰌾'

      eww-overlay-open

      # Pre-warm image cache so rofi loads it from RAM, if a wallpaper has been set.
      [ -f ~/.cache/rofi-wallpaper.jpg ] && cat ~/.cache/rofi-wallpaper.jpg > /dev/null

      chosen="$(printf '%s\n' "$shutdown" "$reboot" "$suspend" "$logout" "$lock" \
        | rofi -dmenu \
            -p " $USER@$host" \
            -mesg " Last Login: $lastlogin |  Uptime: $uptime" \
            -theme "$HOME/.config/rofi/powermenu.rasi")"

      eww-overlay-close

      case "$chosen" in
        "$shutdown") systemctl poweroff ;;
        "$reboot")   systemctl reboot ;;
        "$suspend")  systemctl suspend ;;
        "$logout")   hyprctl dispatch exit ;;
        "$lock")     loginctl lock-session ;;
      esac
    '')
  ];

  # Main rofi config
  home.file.".config/rofi/config.rasi".text = ''
    configuration {
      modi:                "drun,run";
      show-icons:          true;
      icon-theme:          "Papirus";
      drun-display-format: "{name}";
      display-drun:        "";
      font:                "JetBrainsMono Nerd Font 13";
    }

    @theme "~/.config/rofi/theme.rasi"
  '';

  # App launcher theme — imports matugen colors at runtime
  home.file.".config/rofi/theme.rasi".text = ''
    @import "~/.cache/matugen/rofi-colors.rasi"

    * {
      background-color: transparent;
      text-color:       @fg;
    }

    window {
      background-color: @bg;
      border:           2px solid;
      border-color:     @border;
      border-radius:    14px;
      width:            520px;
      padding:          12px;
    }

    mainbox {
      background-color: transparent;
      spacing:          8px;
    }

    inputbar {
      background-color: @bg-alt;
      border-radius:    8px;
      padding:          10px 14px;
      children:         [prompt, entry];
    }

    prompt {
      enabled: false;
    }

    entry {
      text-color:        @fg;
      placeholder-color: @fg-alt;
      placeholder:       "Search apps...";
    }

    listview {
      lines:   8;
      spacing: 4px;
    }

    element {
      border-radius: 8px;
      padding:       8px 12px;
      spacing:       10px;
      children:      [element-icon, element-text];
    }

    element normal.normal {
      background-color: transparent;
      text-color:       @fg;
    }

    element alternate.normal {
      background-color: transparent;
      text-color:       @fg;
    }

    element selected.normal {
      background-color: @primary;
      text-color:       @on-primary;
    }

    element-icon {
      size:           22px;
      vertical-align: 0.5;
    }

    element-text {
      vertical-align: 0.5;
      text-color:     inherit;
    }
  '';

  # Clipboard picker theme — dmenu style, no icons, monospace entries
  home.file.".config/rofi/clipboard.rasi".text = ''
    @import "~/.cache/matugen/rofi-colors.rasi"

    configuration {
      show-icons: true;
      font:       "JetBrainsMono Nerd Font 12";
    }

    * {
      background-color: transparent;
      text-color:       @fg;
    }

    window {
      transparency:     "real";
      background-color: @bg-alpha;
      border:           2px solid;
      border-color:     @border;
      border-radius:    14px;
      width:            680px;
      padding:          12px;
    }

    mainbox {
      background-color: transparent;
      spacing:          8px;
      children:         [listview];
    }

    listview {
      lines:   10;
      spacing: 4px;
    }

    element {
      border-radius: 8px;
      padding:       8px 12px;
      children:      [element-text];
    }

    element normal.normal {
      background-color: transparent;
      text-color:       @fg;
    }

    element alternate.normal {
      background-color: transparent;
      text-color:       @fg;
    }

    element selected.normal {
      background-color: @primary;
      text-color:       @on-primary;
    }

    element-text {
      vertical-align: 0.5;
      text-color:     inherit;
    }
  '';

  # Power menu rasi theme — type-5 style-2 adapted with matugen colors + current wallpaper
  home.file.".config/rofi/powermenu.rasi".text = ''
    @import "~/.cache/matugen/rofi-colors.rasi"

    configuration {
      show-icons: false;
    }

    * {
      font: "JetBrainsMono Nerd Font 10";
    }

    window {
      transparency:     "real";
      location:         center;
      anchor:           center;
      width:            600px;
      border-radius:    20px;
      border:           0px solid;
      background-color: @bg;
    }

    mainbox {
      spacing:          0px;
      background-color: transparent;
      children:         [ "inputbar", "listview", "message" ];
    }

    inputbar {
      padding:          65px 50px;
      background-color: @bg;
      background-image: url("~/.cache/rofi-wallpaper.jpg", width);
      children:         [ "textbox-prompt-colon", "dummy", "prompt" ];
    }

    textbox-prompt-colon {
      expand:           false;
      str:              "󰐥 System";
      padding:          12px;
      border-radius:    100%;
      background-color: @primary;
      text-color:       @on-primary;
    }

    dummy {
      background-color: transparent;
    }

    prompt {
      padding:          12px;
      border-radius:    100%;
      background-color: @bg-alt;
      text-color:       @fg;
    }

    listview {
      columns:          5;
      lines:            1;
      cycle:            true;
      dynamic:          true;
      scrollbar:        false;
      spacing:          15px;
      margin:           15px;
      background-color: transparent;
    }

    element {
      padding:          18px 8px;
      border-radius:    100%;
      background-color: @bg-alt;
      text-color:       @fg;
      cursor:           pointer;
    }

    element-text {
      font:             "JetBrainsMono Nerd Font 24";
      background-color: transparent;
      text-color:       inherit;
      cursor:           inherit;
      vertical-align:   0.5;
      horizontal-align: 0.5;
    }

    element selected.normal {
      background-color: @primary;
      text-color:       @on-primary;
    }

    message {
      margin:           0px 15px 15px 15px;
      padding:          15px;
      border-radius:    100%;
      background-color: @bg-alt;
      text-color:       @fg;
    }

    textbox {
      background-color: inherit;
      text-color:       inherit;
      vertical-align:   0.5;
      horizontal-align: 0.5;
    }
  '';

}
