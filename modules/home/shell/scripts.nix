{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (writeShellScriptBin "toggle-mic" ''
      wpctl set-source-mute @DEFAULT_SOURCE@ toggle
      if brightnessctl --device='platform::micmute' info >/dev/null 2>&1; then
        led=$(brightnessctl --device='platform::micmute' get)
        brightnessctl --device='platform::micmute' set $((1 - led))
      fi
    '')

    (writeShellScriptBin "toggle-mute" ''
      wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      if brightnessctl --device='platform::mute' info >/dev/null 2>&1; then
        led=$(brightnessctl --device='platform::mute' get)
        brightnessctl --device='platform::mute' set $((1 - led))
      fi
    '')
  ];
}
