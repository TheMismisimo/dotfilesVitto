{ homeDirectory, ... }:

{
  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      source = ~/.cache/matugen/hyprlock-colors.conf

      general {
        disable_loading_bar = true
        grace               = 5
        hide_cursor         = true
      }

      background {
        path        = ${homeDirectory}/.cache/current-wallpaper.img
        blur_passes = 3
        blur_size   = 8
        brightness  = 0.6
      }

      label {
        text        = cmd[update:1000] echo "$(date +"%H:%M")"
        color       = $on_surface
        font_size   = 72
        font_family = JetBrainsMono Nerd Font
        position    = 0, 80
        halign      = center
        valign      = center
      }

      label {
        text        = cmd[update:60000] echo "$(LC_TIME=en_US.UTF-8 date +"%A, %d %B")"
        color       = $on_surface
        font_size   = 18
        font_family = JetBrainsMono Nerd Font
        position    = 0, 10
        halign      = center
        valign      = center
      }

      input-field {
        size              = 280, 50
        position          = 0, -80
        halign            = center
        valign            = center
        outline_thickness = 2
        dots_size         = 0.3
        dots_spacing      = 0.2
        outer_color       = $primary
        inner_color       = $surface
        font_color        = $on_surface
        fade_on_empty     = true
        placeholder_text  = <i>password</i>
        check_color       = $primary
        fail_color        = $error
        fail_text         = <i>incorrect</i>
        capslock_color    = $error
      }
    '';
  };
}
