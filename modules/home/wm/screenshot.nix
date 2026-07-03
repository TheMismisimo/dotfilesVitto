{ pkgs, ... }:

{
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
  ];

  # Screenshots directory
  home.file."Pictures/screenshots/.keep".text = "";

  wayland.windowManager.hyprland.settings.bind = [
    # Full screenshot → save to file + notify
    ", Print, exec, FILE=~/Pictures/screenshots/$(date +%Y%m%d_%H%M%S).png && grim $FILE && notify-send -i $FILE '󰹑 Screenshot' 'Saved to Pictures/screenshots'"

    # Region selection → save to file + copy to clipboard + notify
    "$mod SHIFT, S, exec, FILE=~/Pictures/screenshots/$(date +%Y%m%d_%H%M%S).png && slurp | grim -g - - | tee $FILE | wl-copy && notify-send -i $FILE '󰹑 Screenshot' 'Saved and copied to clipboard'"
  ];
}
