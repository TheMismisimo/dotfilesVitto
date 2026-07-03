{ pkgs, ... }:

{
  home.packages = [ pkgs.fastfetch pkgs.prisma-engines pkgs.openssl ];

  home.file.".config/fastfetch/config.jsonc".text = ''
    {
      "logo": {
        "source": "nixos_old",
        "padding": { "top": 2 }
      },
      "display": {
        "separator": " : "
      },
      "modules": [
        { "type": "custom", "format": "╭──────────────── Hardware ────────────────╮" },
        { "type": "host",    "key": "│ 󰌢  Host" },
        { "type": "cpu",     "key": "│  CPU" },
        { "type": "gpu",     "key": "│ 󰍛  GPU" },
        { "type": "memory",  "key": "│  RAM" },
        { "type": "disk",    "key": "│ 󰋊  Disk", "folders": "/" },
        { "type": "battery", "key": "│ 󰁹  Battery" },
        { "type": "custom", "format": "╰──────────────────────────────────────────╯" },

        { "type": "break" },

        { "type": "custom",      "format": "╭──────────────── Software ────────────────╮" },
        { "type": "os",          "key": "│   OS" },
        { "type": "kernel",      "key": "│ 󰌽  Kernel" },
        { "type": "shell",       "key": "│  Shell" },
        { "type": "terminal",    "key": "│  Terminal" },
        { "type": "custom",      "format": "╰──────────────────────────────────────────╯" },

        { "type": "break" },

        { "type": "custom",   "format": "╭────────────── Uptime / Age ──────────────╮" },
        { "type": "uptime",   "key": "│   Uptime" },
        { "type": "datetime", "key": "│  󰃰 DateTime" },
        { "type": "custom",   "format": "╰──────────────────────────────────────────╯" }
      ]
    }
  '';

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = "printf '\\e[?25l'; fastfetch; printf '\\e[?25h'";
    sessionVariables = {
        PRISMA_SCHEMA_ENGINE_BINARY    = "${pkgs.prisma-engines}/bin/schema-engine";
        PRISMA_QUERY_ENGINE_BINARY     = "${pkgs.prisma-engines}/bin/query-engine";
        PRISMA_FMT_BINARY              = "${pkgs.prisma-engines}/bin/prisma-fmt";
        PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING = "1";
      };

    shellAliases = {
      zed = "zeditor";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "z"        # jump to frecent directories
        "sudo"
      ];
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      format = "\${custom.userhost}$directory$git_branch$git_status$nix_shell$character";

      custom.userhost = {
        command = ''echo "[''${USER}@$(hostname -s)]"'';
        when = "true";
        format = "[$output]($style) ";
        style = "bold cyan";
        shell = ["bash"];
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        read_only = " 󰌾";
        read_only_style = "red";
      };

      git_branch = {
        format = "[$symbol$branch]($style) ";
        symbol = " ";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
      };

      nix_shell = {
        format = "[$symbol$state]($style) ";
        symbol = " ";
      };

      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
      };
    };
  };
}
