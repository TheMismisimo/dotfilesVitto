{ config, lib, pkgs, ... }:

let
  features = config.local.features;
in
{
  config = lib.mkIf features.steam.enable {
    programs.steam = {
      enable = true;

      # Extra Proton builds exposed to Steam via STEAM_EXTRA_COMPAT_TOOLS_PATHS.
      # Note: nixpkgs has no top-level `proton` package, so this is the
      # maintained community build instead.
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
  };
}