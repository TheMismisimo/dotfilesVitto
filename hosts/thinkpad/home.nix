{ ... }:

{
  imports = [
    ./kanshi.nix
  ];

  local.machine = {
    tabletOutput = "DP-10";
    bindF4MicMute = true;
    execOnce = [ "blueman-applet" ];
  };
}
