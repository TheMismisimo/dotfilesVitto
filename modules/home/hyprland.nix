{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.local.machine;
in
{
  options.local.machine = {
    tabletOutput = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Hyprland output name to bind drawing tablet input to.";
    };

    bindF4MicMute = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Bind plain F4 to mic mute for firmware that does not emit XF86AudioMicMute.";
    };
  };

  config.wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      systemd.enable = true;
      extraConfig = ''
        source = ~/.cache/matugen/hyprland-colors.conf
        general {
          col.active_border = $col_active_border
          col.inactive_border = $col_inactive_border
        }
      '';

    settings = {
      monitor = ",preferred,auto,auto";

      "$terminal" = "alacritty";
      "$mod" = "SUPER";
      "$menu" = "rofi -show drun";

      env = [
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Classic"
      ];

      input = {
        kb_layout = "latam";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
        };
      } // lib.optionalAttrs (cfg.tabletOutput != null) {
        tablet.output = cfg.tabletOutput;
      };

      general = {
        gaps_in = 5;
        gaps_out = "50, 8, 8, 8";
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";   # fallback until matugen runs
        "col.inactive_border" = "rgba(595959aa)";                       # fallback until matugen runs
        layout = "dwindle";
        allow_tearing = false;
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          new_optimizations = true;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };


      dwindle = {
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
      };

      exec-once = [
        "mako"
      ];

      layerrule = [
        "blur on, match:namespace eww-overlay"
        "animation fade, match:namespace rofi"
      ];


      bind = [
        # Apps
        "$mod, Q, exec, $terminal"
        "$mod, R, exec, $menu"
        "$mod SHIFT, P, exec, rofi-powermenu"
        "$mod, F, exec, alacritty -e yazi"

        # Window management
        "$mod, C, killactive"
        "$mod, M, exit"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, L, exec, loginctl lock-session"

        # Focus — arrow keys
        "$mod, left,  movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up,    movefocus, u"
        "$mod, down,  movefocus, d"

        # Focus — vim keys
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # Switch workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"

        # Scroll through workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up,   workspace, e-1"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Media / Fn keys — fire even when screen is locked
      bindl = [
        ", XF86AudioMute,        exec, toggle-mute"
        ", XF86AudioMicMute,     exec, toggle-mic"
        ", XF86MonBrightnessUp,  exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown,exec, brightnessctl set 5%-"
      ] ++ lib.optionals cfg.bindF4MicMute [
        ", F4,                   exec, toggle-mic"
      ];

      bindle = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ];
    };

};
}
