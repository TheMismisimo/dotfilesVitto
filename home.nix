{ username, homeDirectory, ... }:

{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "25.11"; # Please read the comment before changing.

  imports = [
    ./modules/home/profile.nix
    ./modules/home/apps.nix
    ./modules/home/development.nix
    ./modules/home/gtk.nix
    ./modules/home/ssh.nix

    ./modules/home/wall-mng/wallpaper.nix
    ./modules/home/wall-mng/matugen.nix

    ./modules/home/wm/hyprland.nix
    ./modules/home/wm/hyprlock.nix
    ./modules/home/wm/hypridle.nix
    ./modules/home/wm/waybar.nix
    ./modules/home/wm/eww.nix
    ./modules/home/wm/rofi.nix
    ./modules/home/wm/mako.nix
    ./modules/home/wm/screenshot.nix

    ./modules/home/shell/terminal.nix
    ./modules/home/shell/zsh.nix
    ./modules/home/shell/yazi.nix
    ./modules/home/shell/scripts.nix

    ./modules/home/services/cliphist.nix
    ./modules/home/services/keyring.nix
    ./modules/home/services/network.nix
    ./modules/home/services/opencode-waybar.nix
  ];
}
