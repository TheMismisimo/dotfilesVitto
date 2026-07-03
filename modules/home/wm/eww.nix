{ pkgs, ... }:

{
  home.packages = with pkgs; [
    eww

    (writeShellScriptBin "eww-overlay-open" ''
      monitor_count=$(hyprctl monitors -j | jq 'length')
      for i in $(seq 0 $((monitor_count - 1))); do
        eww open overlay-$i
      done
    '')

    (writeShellScriptBin "eww-overlay-close" ''
      monitor_count=$(hyprctl monitors -j | jq 'length')
      for i in $(seq 0 $((monitor_count - 1))); do
        eww close overlay-$i
      done
    '')
  ];

  xdg.configFile."eww/eww.yuck".text = ''
    (defwindow overlay-0
      :monitor 0
      :geometry (geometry :x "0" :y "0" :width "100%" :height "100%")
      :stacking "overlay"
      :exclusive false
      :focusable false
      :namespace "eww-overlay"
      (box :class "overlay"))

    (defwindow overlay-1
      :monitor 1
      :geometry (geometry :x "0" :y "0" :width "100%" :height "100%")
      :stacking "overlay"
      :exclusive false
      :focusable false
      :namespace "eww-overlay"
      (box :class "overlay"))

    (defwindow overlay-2
      :monitor 2
      :geometry (geometry :x "0" :y "0" :width "100%" :height "100%")
      :stacking "overlay"
      :exclusive false
      :focusable false
      :namespace "eww-overlay"
      (box :class "overlay"))
  '';

  xdg.configFile."eww/eww.scss".text = ''
    window {
      background: transparent;
    }

    .overlay {
      background: transparent;
    }
  '';
}
