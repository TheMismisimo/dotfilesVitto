{ config, lib, pkgs, ... }:

let
  username = config.local.user.name;
in
{
  config = lib.mkIf config.local.features.sddm.enable {
    services.accounts-daemon.enable = true;
    systemd.tmpfiles.rules = [
      "L+ /var/lib/AccountsService/icons/${username} - - - - ${../../assets/katakuri_avatar.png}"
    ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "silent";
      extraPackages = with pkgs.kdePackages; [
        qtmultimedia
        qtsvg
        qtvirtualkeyboard
        layer-shell-qt
        pkgs.qt6.qtwayland
      ];
      settings = {
        Wayland.EnableHiDPI = true;
      };
    };
  };
}
