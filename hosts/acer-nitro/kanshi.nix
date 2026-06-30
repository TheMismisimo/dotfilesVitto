{ ... }:

{
  systemd.user.services.kanshi = {
    Unit.StartLimitIntervalSec = 60;
    Unit.StartLimitBurst = 10;
    Service.RestartSec = 5;
  };

  services.kanshi = {
    enable = true;
    systemdTarget = "hyprland-session.target";
    settings = [
      {
        profile = {
          name = "laptop-only";
          exec = [ "set-wallpaper" ];
          outputs = [
            # Configuración de pantalla para el Nitro V 15
            { criteria = "eDP-1"; mode = "1920x1080@144"; position = "0,0"; scale = 0.5; }
          ];
        };
      }
    ];
  };
}
