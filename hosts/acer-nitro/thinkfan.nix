{ ... }:

{
  # Allow thinkpad_acpi to control the fan.
  boot.extraModprobeConfig = "options thinkpad_acpi fan_control=1";

  services.thinkfan = {
    enable = true;

    # Use the ThinkPad hwmon sensor and k10temp as a secondary source.
    sensors = [
      {
        type = "hwmon";
        query = "/sys/class/hwmon";
        name = "thinkpad";
        indices = [ 1 ];
      }
      {
        type = "hwmon";
        query = "/sys/class/hwmon";
        name = "k10temp";
        indices = [ 1 ];
      }
    ];

    levels = [
      [ 0   0  42 ]
      [ 1  40  48 ]
      [ 2  46  54 ]
      [ 3  52  60 ]
      [ 4  58  65 ]
      [ 5  63  70 ]
      [ 7  68  90 ]
      [ "level disengaged"  85  100 ]
    ];
  };
}
