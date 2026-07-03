{ config, lib, pkgs, inputs, ... }:

let
  features = config.local.features;
  user = config.local.user;
in
{
  imports = [
    ./features.nix
    ./user.nix
    ./audio.nix
    ./sddm.nix
  ];

  # Boot splash
  boot.plymouth = {
    enable = true;
    theme = "nixos-bgrt";
    themePackages = [ pkgs.nixos-bgrt-plymouth ];
  };
  boot.kernelParams = [ "quiet" "splash" ];
  boot.initrd.systemd.enable = true;

  # Nix store hygiene
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.settings.auto-optimise-store = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.tailscale = lib.mkIf features.tailscale.enable {
    enable = true;
    openFirewall = true;
  };

  networking.networkmanager = lib.mkIf features.networkManager.enable {
    enable = true;
    dispatcherScripts = [{
      source = pkgs.writeShellScript "waybar-network-dispatch" ''
        ${pkgs.procps}/bin/pkill -u ${user.name} -RTMIN+8 waybar || true
      '';
      type = "basic";
    }];
  };

  virtualisation.docker = lib.mkIf features.docker.enable {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  time.timeZone = "America/Santiago";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "es_CL.UTF-8/UTF-8" ];
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "es_CL.UTF-8";
    LC_IDENTIFICATION = "es_CL.UTF-8";
    LC_MEASUREMENT    = "es_CL.UTF-8";
    LC_MONETARY       = "es_CL.UTF-8";
    LC_NAME           = "es_CL.UTF-8";
    LC_NUMERIC        = "es_CL.UTF-8";
    LC_PAPER          = "es_CL.UTF-8";
    LC_TELEPHONE      = "es_CL.UTF-8";
    LC_TIME           = "es_CL.UTF-8";
  };

  # Configure keymap in X11 / XWayland
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  users.users.${user.name} = {
    isNormalUser = true;
    description = user.fullName;
    extraGroups = [ "wheel" "video" ]
      ++ lib.optionals features.networkManager.enable [ "networkmanager" ]
      ++ lib.optionals features.docker.enable [ "docker" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  programs.xfconf.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libcap
      stdenv.cc.cc.lib
    ];
  };

  # Keyring auto-unlocked by SDDM on login via PAM.
  services.gnome.gnome-keyring.enable = lib.mkIf features.keyring.enable true;
  security.pam.services.sddm.enableGnomeKeyring = lib.mkIf (features.sddm.enable && features.keyring.enable) true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      username = user.name;
      homeDirectory = user.homeDirectory;
    };
    users.${user.name} = import ../../home.nix;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    jq
    libnotify
    brightnessctl
    ddcutil
    gnome-keyring
    libsecret
    gcr_4
    inputs.sddm-theme.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.hyprland = lib.mkIf features.desktop.enable {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
}
