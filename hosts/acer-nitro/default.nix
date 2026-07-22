{ config, pkgs, inputs, ... }:

let
  username = config.local.user.name;
in
{
  imports = [
    ./hardware-configuration.nix
    ./wireguard.nix
    ../../modules/system/common.nix
    ../../modules/system/bluetooth.nix
  ];

  networking.hostName = "acer-nitro";

  local.user = {
    name = "armando";
    fullName = "Armando";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 5;

  # Keep the kernel version where Bluetooth is known to work on this machine.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  home-manager.users.${username}.imports = [ ./home.nix ];
  # Habilitar CoreCtrl y dar permisos a tu usuario
  programs.corectrl.enable = true;
  users.users.${username}.extraGroups = [ "corectrl" ];
  # Optimizador automático de batería y rendimiento
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersave";
      turbo = "never";
    };
    charger = {
      governor = "performance";
      turbo = "auto";
    };
  };
  
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    # Obligatorio para que Hyprland funcione con Nvidia
    modesetting.enable = true;

    # Gestión de energía para que apague la Nvidia cuando no se usa
    powerManagement.enable = true;

    # Usar drivers privativos (cerrados) para mejor rendimiento
    open = false;

    # Habilita el panel de control de Nvidia
    nvidiaSettings = true;

    # Configuración PRIME Offload (Renderizado Híbrido)
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };


      amdgpuBusId = "PCI:75:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  system.stateVersion = "25.11";
}
