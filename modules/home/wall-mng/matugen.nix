{ lib, pkgs, ... }:

{
  # matugen config — points to templates and their output paths
  home.file.".config/matugen/config.toml".text = ''
    [config]
    reload_gtk_theme = false

    [templates.alacritty]
    input_path  = "~/.config/matugen/templates/alacritty-colors.toml"
    output_path = "~/.cache/matugen/alacritty-colors.toml"

    [templates.waybar]
    input_path  = "~/.config/matugen/templates/waybar.css"
    output_path = "~/.cache/matugen/waybar.css"

    [templates.hyprlock]
    input_path  = "~/.config/matugen/templates/hyprlock-colors.conf"
    output_path = "~/.cache/matugen/hyprlock-colors.conf"

    [templates.rofi]
    input_path  = "~/.config/matugen/templates/rofi-colors.rasi"
    output_path = "~/.cache/matugen/rofi-colors.rasi"

    [templates.mako]
    input_path  = "~/.config/matugen/templates/mako.conf"
    output_path = "~/.config/mako/config"

    [templates.hyprland]
    input_path  = "~/.config/matugen/templates/hyprland-colors.conf"
    output_path = "~/.cache/matugen/hyprland-colors.conf"

    [templates.gtk]
    input_path  = "~/.config/matugen/templates/gtk-colors.css"
    output_path = "~/.cache/matugen/gtk-colors.css"

    [templates.yazi]
    input_path  = "~/.config/matugen/templates/yazi-theme.toml"
    output_path = "~/.config/yazi/theme.toml"

  '';

  home.activation.bootstrapMatugenColors = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    fallback_wallpaper="${../../../assets/avatar.png}"
    missing_matugen_output=0

    for output in \
      "$HOME/.cache/matugen/alacritty-colors.toml" \
      "$HOME/.cache/matugen/waybar.css" \
      "$HOME/.cache/matugen/hyprlock-colors.conf" \
      "$HOME/.cache/matugen/rofi-colors.rasi" \
      "$HOME/.cache/matugen/hyprland-colors.conf" \
      "$HOME/.cache/matugen/gtk-colors.css" \
      "$HOME/.config/mako/config" \
      "$HOME/.config/yazi/theme.toml"; do
      if [ ! -f "$output" ]; then
        missing_matugen_output=1
        break
      fi
    done

    if [ "$missing_matugen_output" -eq 1 ]; then
      if [ -f "$fallback_wallpaper" ]; then
        $DRY_RUN_CMD mkdir -p "$HOME/.cache/matugen" "$HOME/.config/mako" "$HOME/.config/yazi"
        $DRY_RUN_CMD ${pkgs.matugen}/bin/matugen image "$fallback_wallpaper" --source-color-index 0 --quiet
      else
        echo "Skipping matugen color bootstrap; fallback wallpaper not found: $fallback_wallpaper"
      fi
    fi
  '';

  # Alacritty color template using Material You palette
  home.file.".config/matugen/templates/alacritty-colors.toml".text = ''
    [colors.primary]
    background = "{{colors.surface.default.hex}}"
    foreground = "{{colors.on_surface.default.hex}}"

    [colors.cursor]
    text = "{{colors.on_primary.default.hex}}"
    cursor = "{{colors.primary.default.hex}}"

    [colors.selection]
    text = "{{colors.on_primary_container.default.hex}}"
    background = "{{colors.primary_container.default.hex}}"

    [colors.normal]
    black = "{{colors.surface_variant.default.hex}}"
    red = "{{colors.error.default.hex}}"
    green = "{{colors.tertiary.default.hex}}"
    yellow = "{{colors.secondary.default.hex}}"
    blue = "{{colors.primary.default.hex}}"
    magenta = "{{colors.tertiary_container.default.hex}}"
    cyan = "{{colors.secondary_container.default.hex}}"
    white = "{{colors.on_surface.default.hex}}"

    [colors.bright]
    black = "{{colors.outline.default.hex}}"
    red = "{{colors.error_container.default.hex}}"
    green = "{{colors.on_tertiary.default.hex}}"
    yellow = "{{colors.on_secondary.default.hex}}"
    blue = "{{colors.on_primary.default.hex}}"
    magenta = "{{colors.on_tertiary_container.default.hex}}"
    cyan = "{{colors.on_secondary_container.default.hex}}"
    white = "{{colors.on_background.default.hex}}"
  '';

  # Hyprlock color template
  home.file.".config/matugen/templates/hyprlock-colors.conf".text = ''
    $primary          = rgb({{colors.primary.default.hex_stripped}})
    $on_primary       = rgb({{colors.on_primary.default.hex_stripped}})
    $surface          = rgb({{colors.surface.default.hex_stripped}})
    $on_surface       = rgb({{colors.on_surface.default.hex_stripped}})
    $surface_variant  = rgb({{colors.surface_variant.default.hex_stripped}})
    $error            = rgb({{colors.error.default.hex_stripped}})
  '';

  # Waybar color template
  home.file.".config/matugen/templates/waybar.css".text = ''
    @define-color background     {{colors.surface.default.hex}};
    @define-color foreground     {{colors.on_surface.default.hex}};

    @define-color primary              {{colors.primary.default.hex}};
    @define-color on_primary           {{colors.on_primary.default.hex}};
    @define-color primary_container    {{colors.primary_container.default.hex}};
    @define-color on_primary_container {{colors.on_primary_container.default.hex}};

    @define-color secondary              {{colors.secondary.default.hex}};
    @define-color on_secondary_container {{colors.on_secondary_container.default.hex}};

    @define-color tertiary              {{colors.tertiary.default.hex}};
    @define-color on_tertiary_container {{colors.on_tertiary_container.default.hex}};

    @define-color error              {{colors.error.default.hex}};
    @define-color on_error_container {{colors.on_error_container.default.hex}};

    @define-color surface_variant    {{colors.surface_variant.default.hex}};
    @define-color on_surface_variant {{colors.on_surface_variant.default.hex}};
  '';

  # Mako notification config template
  home.file.".config/matugen/templates/mako.conf".text = ''
    font=JetBrainsMono Nerd Font 13
    width=380
    height=120
    margin=12
    padding=14

    background-color={{colors.surface.default.hex}}e6
    text-color={{colors.on_surface.default.hex}}
    border-color={{colors.primary.default.hex}}
    border-size=2
    border-radius=12

    icons=1
    max-icon-size=32
    default-timeout=5000
    layer=overlay
    anchor=top-right
  '';

  # Hyprland border color template
  home.file.".config/matugen/templates/hyprland-colors.conf".text = ''
    $col_active_border   = rgba({{colors.primary.default.hex_stripped}}ee) rgba({{colors.tertiary.default.hex_stripped}}ee) 45deg
    $col_inactive_border = rgba({{colors.outline.default.hex_stripped}}aa)
  '';

  # GTK color template (imported by gtk.css for both GTK3 and GTK4)
  home.file.".config/matugen/templates/gtk-colors.css".text = ''
    @define-color accent_color          {{colors.primary.default.hex}};
    @define-color accent_bg_color       {{colors.primary.default.hex}};
    @define-color accent_fg_color       {{colors.on_primary.default.hex}};

    @define-color window_bg_color       {{colors.surface.default.hex}};
    @define-color window_fg_color       {{colors.on_surface.default.hex}};
    @define-color view_bg_color         {{colors.surface.default.hex}};
    @define-color view_fg_color         {{colors.on_surface.default.hex}};

    @define-color headerbar_bg_color    {{colors.surface_variant.default.hex}};
    @define-color headerbar_fg_color    {{colors.on_surface_variant.default.hex}};
    @define-color headerbar_border_color {{colors.outline.default.hex}};

    @define-color card_bg_color         {{colors.surface_variant.default.hex}};
    @define-color card_fg_color         {{colors.on_surface_variant.default.hex}};

    @define-color popover_bg_color      {{colors.surface_variant.default.hex}};
    @define-color popover_fg_color      {{colors.on_surface_variant.default.hex}};

    @define-color sidebar_bg_color      {{colors.surface.default.hex}};
    @define-color sidebar_fg_color      {{colors.on_surface.default.hex}};

    @define-color error_color           {{colors.error.default.hex}};
    @define-color error_bg_color        {{colors.error_container.default.hex}};
    @define-color error_fg_color        {{colors.on_error_container.default.hex}};
  '';

  # Yazi theme template
  home.file.".config/matugen/templates/yazi-theme.toml".text = ''
    [manager]
    cwd             = { fg = "{{colors.primary.default.hex}}" }
    hovered         = { fg = "{{colors.on_primary_container.default.hex}}", bg = "{{colors.primary_container.default.hex}}" }
    preview_hovered = { underline = true }

    find_keyword  = { fg = "{{colors.tertiary.default.hex}}", bold = true, italic = true }
    find_position = { fg = "{{colors.secondary.default.hex}}", bold = true }

    marker_copied   = { fg = "{{colors.tertiary_container.default.hex}}",  bg = "{{colors.tertiary_container.default.hex}}" }
    marker_cut      = { fg = "{{colors.error_container.default.hex}}",     bg = "{{colors.error_container.default.hex}}" }
    marker_selected = { fg = "{{colors.primary_container.default.hex}}",   bg = "{{colors.primary_container.default.hex}}" }

    tab_active   = { fg = "{{colors.on_primary.default.hex}}", bg = "{{colors.primary.default.hex}}" }
    tab_inactive = { fg = "{{colors.on_surface_variant.default.hex}}" }
    tab_width    = 1

    count_copied   = { fg = "{{colors.tertiary.default.hex}}",  bg = "{{colors.surface_variant.default.hex}}" }
    count_cut      = { fg = "{{colors.error.default.hex}}",    bg = "{{colors.surface_variant.default.hex}}" }
    count_selected = { fg = "{{colors.primary.default.hex}}", bg = "{{colors.surface_variant.default.hex}}" }

    border_symbol = "│"
    border_style  = { fg = "{{colors.outline.default.hex}}" }

    [status]
    separator_open  = ""
    separator_close = ""
    separator_style = { fg = "{{colors.surface.default.hex}}", bg = "{{colors.surface.default.hex}}" }

    mode_normal = { fg = "{{colors.on_primary.default.hex}}",   bg = "{{colors.primary.default.hex}}",   bold = true }
    mode_select = { fg = "{{colors.on_secondary.default.hex}}", bg = "{{colors.secondary.default.hex}}", bold = true }
    mode_unset  = { fg = "{{colors.on_tertiary.default.hex}}",  bg = "{{colors.tertiary.default.hex}}",  bold = true }

    progress_label  = { fg = "{{colors.on_surface_variant.default.hex}}", bg = "{{colors.surface_variant.default.hex}}", bold = true }
    progress_normal = { fg = "{{colors.primary.default.hex}}",            bg = "{{colors.surface_variant.default.hex}}" }
    progress_error  = { fg = "{{colors.error.default.hex}}",              bg = "{{colors.surface_variant.default.hex}}" }

    perm_type  = { fg = "{{colors.secondary.default.hex}}",          bg = "{{colors.surface_variant.default.hex}}" }
    perm_read  = { fg = "{{colors.tertiary.default.hex}}",           bg = "{{colors.surface_variant.default.hex}}" }
    perm_write = { fg = "{{colors.error.default.hex}}",              bg = "{{colors.surface_variant.default.hex}}" }
    perm_exec  = { fg = "{{colors.primary.default.hex}}",            bg = "{{colors.surface_variant.default.hex}}" }
    perm_sep   = { fg = "{{colors.outline.default.hex}}",            bg = "{{colors.surface_variant.default.hex}}" }

    [input]
    border   = { fg = "{{colors.primary.default.hex}}" }
    title    = { fg = "{{colors.on_surface.default.hex}}" }
    value    = { fg = "{{colors.on_surface.default.hex}}" }
    selected = { reversed = true }

    [completion]
    border   = { fg = "{{colors.outline.default.hex}}" }
    active   = { fg = "{{colors.on_primary_container.default.hex}}", bg = "{{colors.primary_container.default.hex}}" }
    inactive = { fg = "{{colors.on_surface_variant.default.hex}}" }

    [tasks]
    border  = { fg = "{{colors.outline.default.hex}}" }
    title   = { fg = "{{colors.on_surface.default.hex}}" }
    hovered = { underline = true }

    [which]
    mask            = { bg = "{{colors.surface_variant.default.hex}}" }
    cand            = { fg = "{{colors.primary.default.hex}}" }
    rest            = { fg = "{{colors.on_surface_variant.default.hex}}" }
    desc            = { fg = "{{colors.secondary.default.hex}}" }
    separator       = "  "
    separator_style = { fg = "{{colors.outline.default.hex}}" }

    [help]
    on      = { fg = "{{colors.primary.default.hex}}" }
    exec    = { fg = "{{colors.tertiary.default.hex}}" }
    desc    = { fg = "{{colors.on_surface_variant.default.hex}}" }
    hovered = { bg = "{{colors.primary_container.default.hex}}", bold = true }
    footer  = { fg = "{{colors.on_surface.default.hex}}", bg = "{{colors.surface_variant.default.hex}}" }

    [filetype]
    rules = [
      { mime = "image/*", fg = "{{colors.tertiary.default.hex}}" },
      { mime = "video/*", fg = "{{colors.primary.default.hex}}" },
      { mime = "audio/*", fg = "{{colors.secondary.default.hex}}" },
      { name = "*.nix",   fg = "{{colors.tertiary.default.hex}}" },
      { name = "*.toml",  fg = "{{colors.secondary.default.hex}}" },
      { name = "*.json",  fg = "{{colors.secondary.default.hex}}" },
      { name = "*.yaml",  fg = "{{colors.secondary.default.hex}}" },
      { name = "*.yml",   fg = "{{colors.secondary.default.hex}}" },
      { mime = "inode/x-empty", fg = "{{colors.outline.default.hex}}" },
    ]
  '';

  # Rofi color template
  home.file.".config/matugen/templates/rofi-colors.rasi".text = ''
    * {
      bg:         {{colors.surface.default.hex}};
      bg-alt:     {{colors.surface_variant.default.hex}};
      bg-alpha:   {{colors.surface.default.hex}}cc;
      fg:         {{colors.on_surface.default.hex}};
      fg-alt:     {{colors.on_surface_variant.default.hex}};
      primary:    {{colors.primary.default.hex}};
      on-primary: {{colors.on_primary.default.hex}};
      border:     {{colors.outline.default.hex}};
    }
  '';
}
