{ homeDirectory, ... }:

{
  programs.waybar = {
    enable = true;

    settings = [{
      layer     = "top";
      position  = "top";
      exclusive = false;
      margin-top   = 8;
      margin-left  = 8;
      margin-right = 8;

      modules-left   = [ "custom/nixos" "cpu" "memory" "temperature" "hyprland/window" ];
      modules-center = [ "hyprland/workspaces" ];
      modules-right  = [ "custom/opencode" "custom/network" "backlight" "pulseaudio" "battery" "clock" ];

      "custom/nixos" = {
        format   = "󱄅";
        tooltip  = false;
      };

      "custom/swatch1" = { format = " "; tooltip = false; };
      "custom/swatch2" = { format = " "; tooltip = false; };
      "custom/swatch3" = { format = " "; tooltip = false; };
      "custom/swatch4" = { format = " "; tooltip = false; };

      "cpu" = {
        format   = " {usage}%";
        interval = 2;
        tooltip  = false;
      };

      "memory" = {
        format   = " {used:0.1f}G";
        interval = 2;
        tooltip  = false;
      };

      "temperature" = {
        format             = "󰔏 {temperatureC}°C";
        critical-threshold = 80;
        format-critical    = "󰔏 {temperatureC}°C";
        tooltip            = false;
      };

      "hyprland/workspaces" = {
        format   = "{id}";
        on-click = "activate";
      };

      "hyprland/window" = {
        max-length       = 50;
        separate-outputs = true;
      };

      "pulseaudio" = {
        format         = "{icon} {volume}%";
        format-muted   = "󰝟 muted";
        format-icons   = { default = [ "󰕿" "󰖀" "󰕾" ]; };
        tooltip-format = "{desc}";
        on-click       = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };

      "backlight" = {
        format       = "{icon} {percent}%";
        format-icons = [ "󰃚" "󰃛" "󰃜" "󰃝" "󰃟" "󰃠"];
        tooltip      = false;
      };

      "custom/network" = {
        exec        = "waybar-network";
        return-type = "json";
        signal      = 8;
        interval    = 5;
        tooltip     = true;
      };

      "custom/opencode" = {
        exec        = "waybar-opencode";
        return-type = "json";
        signal      = 9;
        interval    = 2;
        tooltip     = true;
      };

      "battery" = {
        format          = "{icon} {capacity}%";
        format-charging = "{icon}󱐋 {capacity}%";
        format-icons    = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        tooltip-format  = "{timeTo}";
        states = { warning = 30; critical = 15; };
      };

      "clock" = {
        format         = " {:%H:%M:%S}";
        format-alt     = " {:%A, %d %B}";
        interval       = 1;
        tooltip-format = "<tt>{calendar}</tt>";
        locale = "en_US.UTF-8";
        calendar = {
          mode = "month";
          format = {
            today = "<span background='#ffffff' color='#1a1a1a'><b>{}</b></span>";
          };
        };
      };
    }];

    style = ''
      @import url("${homeDirectory}/.cache/matugen/waybar.css");

      * {
        border:        none;
        border-radius: 0;
        font-family:   "JetBrainsMono Nerd Font";
        font-size:     15px;
        min-height:    0;
      }

      window#waybar {
        background-color: #1a1a1a;
        color:            #e0e0e0;
        min-height:       42px;
        border-radius:    14px;
      }

      /* Left */
      #custom-nixos {
        color:     @primary;
        font-size: 22px;
        padding:   0 14px;
      }

      #cpu {
        color:   @secondary;
        padding: 0 14px;
      }

      #memory {
        color:   @tertiary;
        padding: 0 14px;
      }

      #temperature {
        color:   @on_primary_container;
        padding: 0 14px;
      }

      #temperature.critical {
        color: @error;
      }

      /* Center */
      #workspaces button {
        color:            #808080;
        padding:          0 8px;
        border-radius:    8px;
        background:       transparent;
        box-shadow:       none;
        border:           none;
      }

      #workspaces button.active {
        background-color: @primary;
        color:            @on_primary;
      }

      #workspaces button:hover,
      #workspaces button.active:hover {
        background:  inherit;
        box-shadow:  none;
        border:      none;
        color:       inherit;
      }

      #window {
        padding:    0 10px;
        color:      #808080;
        font-style: italic;
      }

      #window.empty {
        padding: 0;
        margin:  0;
      }

      /* Right */
      #custom-opencode {
        color:         @primary;
        padding:       0 10px;
        border-radius: 8px;
      }

      #custom-opencode.busy {
        background-color: @primary;
        color:            @on_primary;
        font-weight:      bold;
      }

      #custom-opencode.idle {
        color: @primary;
      }

      #custom-opencode.empty {
        padding: 0;
        margin:  0;
      }

      #custom-network {
        color:   @tertiary;
        padding: 0 14px;
      }

      #backlight {
        color:   @secondary;
        padding: 0 14px;
      }

      #pulseaudio {
        color:   @on_primary_container;
        padding: 0 14px;
      }

      #battery {
        color:   @secondary;
        padding: 0 14px;
      }

      #battery.warning {
        color: @tertiary;
      }

      #battery.critical {
        color: @error;
      }

      #clock {
        color:       @primary;
        font-weight: bold;
        padding:     0 14px;
      }

      /* Calendar tooltip */
      tooltip {
        background-color: #1a1a1a;
        border:           1px solid @primary;
        border-radius:    10px;
        padding:          4px;
      }

      tooltip label {
        color:     @foreground;
        font-size: 13px;
      }
    '';
  };

  # Launch waybar with Hyprland
  wayland.windowManager.hyprland.settings = {
    exec-once = [ "waybar" ];
  };

}
