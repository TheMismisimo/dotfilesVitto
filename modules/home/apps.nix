{ pkgs, ... }:

{
  home.packages = with pkgs; [
    firefox
    vscode
    thunar
    pgadmin4-desktopmode
    qalculate-gtk
    discord
    spotify
    #anydesk
    pavucontrol
    vivaldi
    vesktop

    (writeShellScriptBin "pgadmin4-launch" ''
      url="http://127.0.0.1:5050"
      log_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/pgadmin4"
      mkdir -p "$log_dir"

      if ! ${curl}/bin/curl -fsS "$url" >/dev/null 2>&1; then
        nohup ${pgadmin4-desktopmode}/bin/pgadmin4 > "$log_dir/pgadmin4.log" 2>&1 &

        for _ in $(seq 1 30); do
          ${curl}/bin/curl -fsS "$url" >/dev/null 2>&1 && break
          sleep 1
        done
      fi

      exec ${xdg-utils}/bin/xdg-open "$url"
    '')
  ];

  xfconf.settings.thunar = {
    "default-view" = "ThunarDetailsView";
    "misc-directory-specific-settings" = false;
  };

  home.file.".local/share/applications/pgadmin4.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=pgAdmin 4
    Comment=PostgreSQL administration and development platform
    Exec=pgadmin4-launch
    Icon=${../../assets/postgresql-elephant.png}
    Terminal=false
    Categories=Development;Database;
  '';
}
