{ config, lib, ... }:

{
  options.local.features = {
    networkManager.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable NetworkManager and related integration.";
    };

    tailscale.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Tailscale.";
    };

    docker.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Docker and add the primary user to the docker group.";
    };

    audio.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable PipeWire audio services.";
    };

    desktop.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the shared system desktop stack.";
    };

    sddm.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.local.features.desktop.enable;
      description = "Enable SDDM display manager.";
    };

    keyring.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.local.features.desktop.enable;
      description = "Enable GNOME Keyring and SDDM PAM unlock integration.";
    };

    steam.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Steam and extra Proton compatibility tools.";
    };
  };
}
