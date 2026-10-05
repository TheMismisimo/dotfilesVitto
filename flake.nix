{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-bluetooth-kernel.url = "github:NixOS/nixpkgs/0726a0ecb6d4e08f6adced58726b95db924cef57";
    opencode-master.url = "github:NixOS/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland/v0.56.2";
    sddm-theme.url = "github:VittorioCancino/SDDM-config";
  };


  outputs = { self, nixpkgs, ... }@inputs:
  let
    lib = nixpkgs.lib;
    hostsDir = ./hosts;

    hostNames = builtins.attrNames (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir hostsDir)
    );
  in {
    nixosConfigurations = lib.genAttrs hostNames (hostName:
      lib.nixosSystem {
        specialArgs = { inherit inputs hostName; };
        modules = [
          (hostsDir + "/${hostName}")
          inputs.home-manager.nixosModules.default
        ];
      }
    );
  };
}
