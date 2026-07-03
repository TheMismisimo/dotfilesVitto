{ ... }:

{
  programs.btop = {
    enable = true;

    settings = {
      color_theme = "Default";
      theme_background = false;

      update_ms = 1000;
      graph_symbol = "braille";
      rounded_corners = true;
      vim_keys = true;

      shown_boxes = "cpu mem net proc";
      proc_sorting = "cpu lazy";
      proc_colors = true;
      proc_gradient = true;
      proc_per_core = false;
      show_coretemp = true;
      show_cpu_freq = true;
      show_battery = true;
      show_disks = true;
      show_io_stat = true;
    };
  };

  programs.alacritty = {
    enable = true;

    settings = {
      general.import = [ "~/.cache/matugen/alacritty-colors.toml" ];

      window = {
        opacity = 0.85;
        decorations = "None";
        padding = {
          x = 8;
          y = 8;
        };
      };

      font = {
        normal.family = "JetBrainsMono Nerd Font";
        size = 12.0;
      };

      terminal.shell.program = "zsh";
    };
  };
}
