{ config, pkgs, inputs, ... }:

let
  username = config.local.user.name;
in
{
  imports = [
    ./hardware-configuration.nix
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

  system.stateVersion = "25.11";
}
