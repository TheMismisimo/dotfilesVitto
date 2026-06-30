{ ... }:

{
  imports = [
    ./kanshi.nix
  ];

  local.machine = {
    tabletOutput = "DP-10";
    bindF4MicMute = true;
  };

  wayland.windowManager.hyprland.settings.exec-once = [
    "blueman-applet"
  ];
}
