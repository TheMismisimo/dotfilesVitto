{ pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        (pkgs.fetchurl {
          name = "bluez-a2dp-connect-source-after-sink.patch";
          url = "https://github.com/bluez/bluez/commit/066a164a524e4983b850f5659b921cb42f84a0e0.patch";
          hash = "sha256-iitdib8VxPWaBUXrxAJ4/YHdBUDMGiDDSEBK+c4aPoE=";
        })
      ];
    });
    powerOnBoot = true;
  };

  services.blueman = {
    enable = true;
  };
}
