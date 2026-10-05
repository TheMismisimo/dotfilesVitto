{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.local.machine;

  execOnce =
    [ "mako" ]
    ++ cfg.execOnce;

  luaStr = s: ''"${lib.escapeShellArg s}"'';

  # "<mods>, <key>, <dispatcher>, <args>" -> hl.bind("mods + key", hl.dsp.<ns>.<fn>(...))
  #
  # Other modules still contribute binds in hyprlang syntax. Rather than
  # duplicating each of those bindings here, translate the ones we know about.
  # Anything unrecognised is dropped with a warning instead of being emitted as
  # invalid Lua, which would take the whole compositor config down with it.
  bindToLua =
    line:
    let
      # Values may contain commas (shell commands), so split on the first three
      # separators only and keep the remainder as the argument string.
      parts = lib.splitString "," line;
      mods = lib.head parts;
      key = lib.elemAt parts 1;
      dispatcher = lib.removePrefix " " (lib.elemAt parts 2);
      args = lib.drop 3 parts;
      argStr = lib.concatStringsSep ", " args;
      keyExpr = if mods == "" then luaStr key else ''mod .. " + ${key}"'';
    in
    if dispatcher == "exec" then
      ''hl.bind(${keyExpr}, hl.dsp.exec_cmd(${luaStr argStr}))''
    else if dispatcher == "killactive" then
      ''hl.bind(${keyExpr}, hl.dsp.window.kill())''
    else if dispatcher == "workspace" then
      ''hl.bind(${keyExpr}, hl.dsp.focus({ workspace = ${luaStr argStr} }))''
    else if dispatcher == "movetoworkspace" then
      ''hl.bind(${keyExpr}, hl.dsp.window.move({ workspace = ${luaStr argStr} }))''
    else if dispatcher == "togglefloating" then
      ''hl.bind(${keyExpr}, hl.dsp.window.float({ action = "toggle" }))''
    else if dispatcher == "pseudo" then
      ''hl.bind(${keyExpr}, hl.dsp.window.pseudo())''
    else if dispatcher == "movefocus" then
      let
        dirs = {
          l = "left";
          r = "right";
          u = "up";
          d = "down";
        };
      in
      ''hl.bind(${keyExpr}, hl.dsp.focus({ direction = "${dirs.${argStr} or argStr}" }))''
    else if dispatcher == "movewindow" then
      ''hl.bind(${keyExpr}, hl.dsp.window.drag(), { mouse = true })''
    else if dispatcher == "resizewindow" then
      ''hl.bind(${keyExpr}, hl.dsp.window.resize(), { mouse = true })''
    else if dispatcher == "exit" then
      ''hl.bind(${keyExpr}, hl.dsp.exit())''
    else
      lib.warn "hyprland: unsupported bind dispatcher '${dispatcher}', skipping: ${line}" ""
    ;

  # Join every token but the first, so values containing spaces survive.
  restOf = toks: lib.concatStringsSep " " (lib.filter (s: s != "") (lib.drop 1 toks));

  # Split "match:namespace eww-overlay" into ("namespace", "eww-overlay").
  matchToField =
    m:
    let
      kv = lib.filter (s: s != "") (lib.splitString " " m);
    in
    if kv == [ ] then "" else ''${lib.head kv} = ${luaStr (restOf kv)}'';

  # Parse a hyprlang rule body into a list of key/value Lua fields.
  # Bool-ish values become true/false; everything else becomes a string.
  effectsToFields =
    effects:
    let
      tokenStr = if builtins.isString effects then effects else lib.concatStringsSep " " effects;
      tokens = lib.filter (s: s != "") (lib.splitString " " tokenStr);
    in
    lib.concatStringsSep ", " (
      lib.filter (s: s != "") (
        lib.mapAttrsToList (
          n: v: if v == "on" || v == "yes" || v == "true" then "true" else if v == "off" || v == "no" || v == "false" then "false" else luaStr v
        ) (lib.listToAttrs (
          lib.filter (p: p != null) (
            lib.map (t: let toks = lib.filter (x: x != "") (lib.splitString " " t); in if toks == [ ] then null else { name = lib.head toks; value = restOf toks; }) tokens
          )
        ))
      )
    );

  # "<effect>, match:<criterion> <value>" -> hl.layer_rule({ ... })
  layerRuleToLua =
    line:
    let
      parts = lib.splitString "," line;
      headPart = lib.head parts;
      effectTokens = builtins.filter (s: !(lib.hasPrefix "match:" s)) (lib.concatMap (p: lib.splitString " " p) parts);
      effectFields = if effectTokens == [ ] then "" else effectsToFields (lib.concatStringsSep " " effectTokens);
      matchTokens = builtins.filter (x: lib.hasPrefix "match:" x) (lib.concatMap (p: lib.splitString " " (lib.concatStringsSep " " (lib.splitString "," p))) parts);
      matchFields = lib.concatStringsSep ", " (
        lib.filter (s: s != "") (
          lib.map (t: matchToField (lib.removePrefix "match:" t)) matchTokens
        )
      );
    in
    if matchFields == "" then
      lib.warn "hyprland: window rule without a match criterion, skipping: ${line}" ""
    else
      ''hl.window_rule({ ${effectFields}${if effectFields != "" && matchFields != "" then ", " else ""}${matchFields} })''
    ;

  # "<effect> <value>, match:<criterion> <regex>" -> hl.window_rule({ ... })
  windowRuleToLua =
    line:
    let
      parts = lib.splitString "," line;
      # Rule criteria can appear in any comma-separated field, so scan them all.
      allTokens = lib.concatMap (t: lib.filter (s: s != "") (lib.splitString " " t)) parts;
      effectTokens = builtins.filter (s: !(lib.hasPrefix "match:" s)) allTokens;
      effectFields = if effectTokens == [ ] then "" else effectsToFields (lib.concatStringsSep " " effectTokens);
      matchTokens = builtins.filter (s: lib.hasPrefix "match:" s) allTokens;
      matchFields = lib.concatStringsSep ", " (
        lib.filter (s: s != "") (
          lib.map (t: matchToField (lib.removePrefix "match:" t)) matchTokens
        )
      );
    in
    if matchFields == "" then
      lib.warn "hyprland: window rule without a match criterion, skipping: ${line}" ""
    else
      let
        eff = effectFields;
        m = matchFields;
        args = if eff == "" then m else if m == "" then eff else "${eff}, ${m}";
      in
      ''hl.window_rule({ ${args} })''
    ;
in
{
  options.local.machine = {
    tabletOutput = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Hyprland output name to bind drawing tablet input to.";
    };

    bindF4MicMute = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Bind plain F4 to mic mute for firmware that does not emit XF86AudioMicMute.";
    };

    execOnce = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra commands to run once when the Hyprland session starts.";
    };

    hyprlandBinds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Extra binds contributed by other modules, in hyprlang syntax
        ("<mods>, <key>, <dispatcher>, <args>"). Converted to Lua by this
        module so that configType can stay "lua".
      '';
    };

    hyprlandLayerRules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Extra layer rules contributed by other modules, in hyprlang syntax
        ("<effects>, match:namespace <name>"). Converted to Lua by this module.
      '';
    };

    hyprlandWindowRules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Extra window rules contributed by other modules, in hyprlang syntax
        ("<effects>, match:<criterion> <regex>"). Converted to Lua by this
        module.
      '';
    };
  };

  config.wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      systemd.enable = true;

      extraConfig = ''
        local terminal = "alacritty"
        local mod     = "SUPER"
        local menu    = "rofi -show drun"

        -- Wallpaper-derived border colors. Static fallbacks are used until the
        -- wallpaper picker has run at least once, so a fresh activation still
        -- gets a themed (if not yet matched) border.
        local colors = {
          active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
          inactive_border = "rgba(595959aa)",
        }

        local colorsPath = (os.getenv("HOME") or "") .. "/.cache/matugen/hyprland-colors.lua"
        local loaded, generated = pcall(dofile, colorsPath)
        if loaded and type(generated) == "table" and generated.active_border then
          colors = generated
        end

        hl.monitor({
          output   = "eDP-1",
          mode     = "1920x1080@144",
          position = "0x0",
          scale    = 1.0,
        })

        hl.env("XCURSOR_SIZE", "24")
        hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
        hl.env("NIXOS_OZONE_WL", "1")

        hl.config({
          input = {
            kb_layout    = "latam",
            follow_mouse = 1,
            sensitivity  = 0,
            touchpad = {
              natural_scroll = true,
            },
          }${lib.optionalString (cfg.tabletOutput != null) ''

          tablet = {
            output = "${cfg.tabletOutput}",
          },''},
        })

        hl.config({
          general = {
            gaps_in       = 5,
            gaps_out      = { top = 50, right = 8, bottom = 8, left = 8 },
            border_size   = 2,
            layout        = "dwindle",
            allow_tearing = false,
            col = {
              active_border   = colors.active_border,
              inactive_border = colors.inactive_border,
            },
          },
        })

        hl.config({
          decoration = {
            rounding = 10,
            blur = {
              enabled           = true,
              size              = 8,
              passes            = 3,
              new_optimizations = true,
            },
            shadow = {
              enabled      = true,
              range        = 4,
              render_power = 3,
              color        = "rgba(1a1a1aee)",
            },
          },
        })

        hl.config({
          animations = { enabled = true },
          dwindle    = { preserve_split = true },
          misc       = { force_default_wallpaper = 0 },
        })

        hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

        hl.animation({ leaf = "windows",     enabled = true, speed = 1, bezier = "myBezier" })
        hl.animation({ leaf = "windowsOut",  enabled = true, speed = 1, bezier = "default", style = "popin 80%" })
        hl.animation({ leaf = "border",      enabled = true, speed = 1, bezier = "default" })
        hl.animation({ leaf = "borderangle", enabled = true, speed = 1, bezier = "default" })
        hl.animation({ leaf = "fade",        enabled = true, speed = 1, bezier = "default" })
        hl.animation({ leaf = "workspaces",  enabled = true, speed = 1, bezier = "default" })

        hl.layer_rule({
          name  = "eww-overlay-blur",
          match = { namespace = "^eww-overlay$" },
          blur  = true,
        })

        hl.layer_rule({
          name      = "rofi-fade",
          match     = { namespace = "^rofi$" },
          animation = "fade",
        })

${lib.optionalString (cfg.hyprlandLayerRules != [ ]) ''
        -- Layer rules contributed by other modules
        ${lib.concatMapStrings (r: "  ${layerRuleToLua r}\n") cfg.hyprlandLayerRules}''}

${lib.optionalString (cfg.hyprlandWindowRules != [ ]) ''
        -- Window rules contributed by other modules
        ${lib.concatMapStrings (r: "  ${windowRuleToLua r}\n") cfg.hyprlandWindowRules}''}

        -- Apps
        hl.bind(mod .. " + Q", hl.dsp.exec_cmd(terminal))
        hl.bind(mod .. " + R", hl.dsp.exec_cmd(menu))
        hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("rofi-powermenu"))
        hl.bind(mod .. " + F", hl.dsp.exec_cmd("alacritty -e yazi"))

        -- Window management
        hl.bind(mod .. " + C", hl.dsp.window.kill())
        hl.bind(mod .. " + M", hl.dsp.exit())
        hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
        hl.bind(mod .. " + P", hl.dsp.window.pseudo())
        hl.bind(mod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))

        -- Focus, arrow keys
        hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
        hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
        hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
        hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

        -- Focus, vim keys
        hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
        hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
        hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
        hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))

        -- Switch workspaces
        for i = 1, 9 do
          hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
        end

        -- Move window to workspace
        for i = 1, 9 do
          hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
        end

        -- Scroll through workspaces
        hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
        hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

        -- Move and resize with the mouse
        hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
        hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

        -- Media and Fn keys, fire even when the screen is locked
        hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("toggle-mute"),  { locked = true })
        hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("toggle-mic"),   { locked = true })
        hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true })
        hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true })
        ${lib.optionalString cfg.bindF4MicMute ''
        hl.bind("F4", hl.dsp.exec_cmd("toggle-mic"), { locked = true })
        ''}

        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })

        ${lib.optionalString (cfg.hyprlandBinds != [ ]) ''
        -- Binds contributed by other modules
        ${lib.concatMapStrings (b: "  ${bindToLua b}\n") cfg.hyprlandBinds}''}

        hl.on("hyprland.start", function()
        ${lib.concatMapStrings (cmd: "  hl.exec_cmd(${luaStr cmd})\n") execOnce}end)
      '';
  };

}