{ pkgs, ... }:
{
  # GNOME Keyring for secrets/pkcs11 — auto-unlocked by SDDM via PAM on login
  wayland.windowManager.hyprland.settings."exec-once" = [
    "gnome-keyring-daemon --start --components=secrets,pkcs11"
  ];

  # gcr-ssh-agent handles SSH keys — gnome-keyring 42+ dropped its built-in SSH component
  systemd.user.sockets.gcr-ssh-agent = {
    Unit.Description = "GCR SSH Agent Socket";
    Socket = {
      ListenStream = "%t/gcr/ssh";
      DirectoryMode = "0700";
    };
    Install.WantedBy = [ "sockets.target" ];
  };

  systemd.user.services.gcr-ssh-agent = {
    Unit = {
      Description = "GCR SSH Agent";
      Requires = [ "gcr-ssh-agent.socket" ];
    };
    Service = {
      ExecStart = "${pkgs.gcr_4}/libexec/gcr-ssh-agent";
      Type = "simple";
    };
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK         = "$XDG_RUNTIME_DIR/gcr/ssh";
    GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";
  };
}
