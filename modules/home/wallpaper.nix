{ lib, pkgs, ... }:

let
  wallpaperPickerPython = pkgs.python3.withPackages (pythonPackages: with pythonPackages; [
    pygobject3
  ]);

  wallpaperPickerTypelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.gtk3
    pkgs.gdk-pixbuf
    pkgs.pango.out
    pkgs.harfbuzz.out
    pkgs.glib.out
    pkgs.at-spi2-core
    pkgs.gobject-introspection
  ];

  wallpaperPickerDataDirs = pkgs.lib.makeSearchPath "share" [
    pkgs.gtk3
    pkgs.gsettings-desktop-schemas
    pkgs.hicolor-icon-theme
    pkgs.glib
    pkgs.webp-pixbuf-loader
  ];

  wallpaperPickerScript = pkgs.writeText "gtk-wallpaper-picker.py" ''
import os
import subprocess
import sys
from hashlib import sha1
from math import ceil
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GdkPixbuf, Gtk, Pango


WALLPAPER_DIR = Path(os.environ.get("XDG_PICTURES_DIR", Path.home() / "Pictures")) / "wallpapers"
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "gtk-wallpaper-picker"
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
THUMB_WIDTH = 280
THUMB_HEIGHT = 158
CARD_BORDER = 2
CARD_WIDTH = THUMB_WIDTH + CARD_BORDER * 2
CARD_HEIGHT = THUMB_HEIGHT + CARD_BORDER * 2
GRID_COLUMNS = 3
GRID_GAP = 18
GRID_PADDING = 12
MAX_VISIBLE_ROWS = 3
PAGE_SIZE = GRID_COLUMNS * MAX_VISIBLE_ROWS
STATUS_HEIGHT = 34


def cache_path_for(path):
    key = sha1(str(path).encode()).hexdigest()
    return CACHE_DIR / f"{key}-{THUMB_WIDTH}x{THUMB_HEIGHT}.png"


def cover_pixbuf(path):
    cache_path = cache_path_for(path)

    try:
        if cache_path.exists() and cache_path.stat().st_mtime >= path.stat().st_mtime:
            return GdkPixbuf.Pixbuf.new_from_file(str(cache_path))
    except OSError:
        pass

    pixbuf = GdkPixbuf.Pixbuf.new_from_file(str(path))
    width = pixbuf.get_width()
    height = pixbuf.get_height()
    scale = max(THUMB_WIDTH / width, THUMB_HEIGHT / height)
    scaled_width = max(1, int(width * scale))
    scaled_height = max(1, int(height * scale))
    scaled = pixbuf.scale_simple(scaled_width, scaled_height, GdkPixbuf.InterpType.BILINEAR)
    crop_x = max(0, (scaled_width - THUMB_WIDTH) // 2)
    crop_y = max(0, (scaled_height - THUMB_HEIGHT) // 2)
    thumb = GdkPixbuf.Pixbuf.new_subpixbuf(scaled, crop_x, crop_y, THUMB_WIDTH, THUMB_HEIGHT)

    try:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        thumb.savev(str(cache_path), "png", [], [])
    except Exception as error:
        print(f"Could not cache thumbnail for {path}: {error}", file=sys.stderr)

    return thumb


class WallpaperPicker(Gtk.Window):
    def __init__(self):
        super().__init__(title="Wallpaper Picker")
        minimum_width, minimum_height = self.window_size(1)
        self.set_default_size(minimum_width, minimum_height)
        self.set_size_request(minimum_width, minimum_height)
        self.connect("destroy", Gtk.main_quit)
        self.connect("key-press-event", self.on_key_press)

        css = b"""
        window {
          background-color: rgba(17, 17, 27, 0.94);
          color: #cdd6f4;
        }

        grid {
          padding: 12px;
        }

        .header-label {
          padding: 8px 12px 0 12px;
          color: #cdd6f4;
          font-weight: 700;
        }

        .wallpaper-card {
          padding: 2px;
          margin: 0;
          min-width: 284px;
          min-height: 162px;
          border-radius: 0;
          background-color: transparent;
          background-image: none;
          border: none;
          box-shadow: none;
          outline: none;
          outline-offset: 0;
        }

        .wallpaper-card:hover,
        .wallpaper-card:focus {
          background-color: transparent;
          background-image: none;
          box-shadow: none;
          outline: none;
        }

        .wallpaper-card.current-wallpaper-card {
          background-color: #b4befe;
          background-image: none;
          box-shadow: none;
        }

        scrolledwindow {
          border: none;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(main_box)

        header = Gtk.Grid()
        header.set_column_homogeneous(True)
        header.set_hexpand(True)
        main_box.pack_start(header, False, False, 0)

        header_spacer = Gtk.Label(label="")
        header_spacer.set_hexpand(True)
        header_spacer.get_style_context().add_class("header-label")
        header.attach(header_spacer, 0, 0, 1, 1)

        self.name_label = Gtk.Label(label="")
        self.name_label.set_hexpand(True)
        self.name_label.set_xalign(0.5)
        self.name_label.set_ellipsize(Pango.EllipsizeMode.END)
        self.name_label.get_style_context().add_class("header-label")
        header.attach(self.name_label, 1, 0, 1, 1)

        self.page_label = Gtk.Label(label="")
        self.page_label.set_hexpand(True)
        self.page_label.set_xalign(1.0)
        self.page_label.get_style_context().add_class("header-label")
        header.attach(self.page_label, 2, 0, 1, 1)

        self.grid = Gtk.Grid()
        self.grid.set_valign(Gtk.Align.START)
        self.grid.set_halign(Gtk.Align.CENTER)
        self.grid.set_margin_top(0)
        self.grid.set_margin_bottom(GRID_PADDING)
        self.grid.set_margin_start(GRID_PADDING)
        self.grid.set_margin_end(GRID_PADDING)
        self.grid.set_column_spacing(GRID_GAP)
        self.grid.set_row_spacing(GRID_GAP)

        self.buttons = []
        self.paths = []
        self.page = 0
        self.selected_index = 0

        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER)
        scroller.add(self.grid)
        main_box.pack_start(scroller, True, True, 0)

        self.load_wallpapers()

    def load_wallpapers(self):
        if not WALLPAPER_DIR.is_dir():
            self.show_empty("Wallpaper directory not found")
            return

        self.paths = sorted(
            path for path in WALLPAPER_DIR.iterdir()
            if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS
        )

        if not self.paths:
            self.show_empty("No wallpapers found")
            return

        self.set_default_size(*self.window_size(min(len(self.paths), PAGE_SIZE)))
        self.render_page(0)

    def render_page(self, selected_index=0):
        for child in self.grid.get_children():
            self.grid.remove(child)

        self.buttons = []
        page_paths = self.visible_paths()

        for path in page_paths:
            try:
                image = Gtk.Image.new_from_pixbuf(cover_pixbuf(path))
            except Exception as error:
                print(f"Skipping {path}: {error}", file=sys.stderr)
                continue

            card = Gtk.EventBox()
            card.set_visible_window(True)
            card.set_can_focus(False)
            card.set_size_request(CARD_WIDTH, CARD_HEIGHT)
            card.get_style_context().add_class("wallpaper-card")
            card.set_tooltip_text(str(path))
            card.add(image)
            card.connect("button-press-event", self.on_wallpaper_clicked, path)
            index = len(self.buttons)
            self.grid.attach(card, index % GRID_COLUMNS, index // GRID_COLUMNS, 1, 1)
            self.buttons.append(card)

        if self.buttons:
            self.select_index(selected_index)

        self.grid.show_all()

    def visible_paths(self):
        start = self.page * PAGE_SIZE
        return self.paths[start:start + PAGE_SIZE]

    def total_pages(self):
        return max(1, ceil(len(self.paths) / PAGE_SIZE))

    def change_page(self, delta):
        if self.total_pages() == 1:
            return False

        next_page = self.page + delta
        if next_page < 0 or next_page >= self.total_pages():
            return False

        self.page = next_page
        self.render_page(0 if delta > 0 else len(self.visible_paths()) - 1)
        return True

    def window_size(self, count):
        columns = min(GRID_COLUMNS, max(1, count))
        rows = min(MAX_VISIBLE_ROWS, ceil(count / columns))
        width = columns * CARD_WIDTH + (columns - 1) * GRID_GAP + GRID_PADDING * 2
        height = STATUS_HEIGHT + rows * CARD_HEIGHT + (rows - 1) * GRID_GAP + GRID_PADDING * 2
        return width, height

    def columns(self):
        return max(1, min(len(self.buttons), GRID_COLUMNS))

    def select_index(self, index):
        if not self.buttons:
            return

        if 0 <= self.selected_index < len(self.buttons):
            old_context = self.buttons[self.selected_index].get_style_context()
            old_context.remove_class("current-wallpaper-card")

        self.selected_index = max(0, min(index, len(self.buttons) - 1))

        button = self.buttons[self.selected_index]
        button.get_style_context().add_class("current-wallpaper-card")
        self.update_status()

    def update_status(self):
        self.page_label.set_text(f"Page {self.page + 1}/{self.total_pages()}")

        if not self.buttons:
            self.name_label.set_text("")
            return

        path = Path(self.buttons[self.selected_index].get_tooltip_text())
        self.name_label.set_text(path.stem)

    def show_empty(self, message):
        label = Gtk.Label(label=message)
        label.set_margin_top(48)
        label.set_margin_bottom(48)
        label.set_margin_start(48)
        label.set_margin_end(48)
        self.grid.attach(label, 0, 0, 1, 1)

    def on_wallpaper_clicked(self, _card, _event, path):
        subprocess.Popen(["set-wallpaper", str(path)])
        Gtk.main_quit()

    def on_key_press(self, _widget, event):
        key = Gdk.keyval_name(event.keyval)
        if key in {"Escape", "q"}:
            Gtk.main_quit()
            return True

        columns = self.columns()

        if key == "Left":
            if self.selected_index == 0 and self.change_page(-1):
                return True
            self.select_index(self.selected_index - 1)
            return True
        if key == "Right":
            if self.selected_index == len(self.buttons) - 1 and self.change_page(1):
                return True
            self.select_index(self.selected_index + 1)
            return True
        if key == "Up":
            if self.selected_index < columns and self.change_page(-1):
                return True
            self.select_index(self.selected_index - columns)
            return True
        if key == "Down":
            if self.selected_index + columns >= len(self.buttons) and self.change_page(1):
                return True
            self.select_index(self.selected_index + columns)
            return True
        if key in {"Page_Up", "bracketleft"}:
            self.change_page(-1)
            return True
        if key in {"Page_Down", "bracketright"}:
            self.change_page(1)
            return True
        if key == "Home":
            self.page = 0
            self.render_page(0)
            self.select_index(0)
            return True
        if key == "End":
            self.page = self.total_pages() - 1
            self.render_page(len(self.visible_paths()) - 1)
            return True
        if key in {"Return", "KP_Enter", "space"} and self.buttons:
            path = Path(self.buttons[self.selected_index].get_tooltip_text())
            subprocess.Popen(["set-wallpaper", str(path)])
            Gtk.main_quit()
            return True

        return False


window = WallpaperPicker()
window.show_all()
window.present()
Gtk.main()
  '';
in

{
  home.packages = with pkgs; [
    awww
    matugen
    imagemagick

    (writeShellScriptBin "gtk-wallpaper-picker" ''
      export GI_TYPELIB_PATH="${wallpaperPickerTypelibPath}''${GI_TYPELIB_PATH:+:}$GI_TYPELIB_PATH"
      export XDG_DATA_DIRS="${wallpaperPickerDataDirs}''${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS"

      exec ${wallpaperPickerPython}/bin/python3 ${wallpaperPickerScript} "$@"
    '')

    (writeShellScriptBin "set-wallpaper" ''
      WALLPAPER="$1"
      TRANSITION="''${2:-grow}"
      DEFAULT_WALLPAPER="${../../assets/avatar.png}"

      # If no argument given, restore last used wallpaper or fall back to redforest.
      if [ -z "$WALLPAPER" ]; then
        WALLPAPER=$(cat ~/.cache/current-wallpaper 2>/dev/null)
        if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
          WALLPAPER="$DEFAULT_WALLPAPER"
        fi
      fi

      if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
        echo "Usage: set-wallpaper <path> [transition]"
        echo "Transitions: wipe fade slide wave grow outer random"
        echo "Fallback wallpaper not found: $DEFAULT_WALLPAPER"
        exit 1
      fi

      mkdir -p ~/.cache

      COLOR_CACHE_VERSION=1
      CACHE_KEY=$(
        printf '%s:%s:%s:%s' "$COLOR_CACHE_VERSION" "$WALLPAPER" "$(stat -c '%s' "$WALLPAPER")" "$(stat -c '%Y' "$WALLPAPER")" \
          | sha1sum \
          | cut -d ' ' -f1
      )
      COLOR_CACHE_DIR="$HOME/.cache/wallpaper-colors/$CACHE_KEY"

      restore_color_cache() {
        [ -f "$COLOR_CACHE_DIR/.complete" ] || return 1
        mkdir -p "$HOME/.cache/matugen" "$HOME/.config/mako" "$HOME/.config/yazi"

        cp "$COLOR_CACHE_DIR/alacritty-colors.toml" "$HOME/.cache/matugen/alacritty-colors.toml" || return 1
        cp "$COLOR_CACHE_DIR/waybar.css" "$HOME/.cache/matugen/waybar.css" || return 1
        cp "$COLOR_CACHE_DIR/hyprlock-colors.conf" "$HOME/.cache/matugen/hyprlock-colors.conf" || return 1
        cp "$COLOR_CACHE_DIR/rofi-colors.rasi" "$HOME/.cache/matugen/rofi-colors.rasi" || return 1
        cp "$COLOR_CACHE_DIR/hyprland-colors.conf" "$HOME/.cache/matugen/hyprland-colors.conf" || return 1
        cp "$COLOR_CACHE_DIR/gtk-colors.css" "$HOME/.cache/matugen/gtk-colors.css" || return 1
        cp "$COLOR_CACHE_DIR/mako.conf" "$HOME/.config/mako/config" || return 1
        cp "$COLOR_CACHE_DIR/yazi-theme.toml" "$HOME/.config/yazi/theme.toml" || return 1
      }

      save_color_cache() {
        mkdir -p "$COLOR_CACHE_DIR"
        rm -f "$COLOR_CACHE_DIR/.complete"

        cp "$HOME/.cache/matugen/alacritty-colors.toml" "$COLOR_CACHE_DIR/alacritty-colors.toml" || return 1
        cp "$HOME/.cache/matugen/waybar.css" "$COLOR_CACHE_DIR/waybar.css" || return 1
        cp "$HOME/.cache/matugen/hyprlock-colors.conf" "$COLOR_CACHE_DIR/hyprlock-colors.conf" || return 1
        cp "$HOME/.cache/matugen/rofi-colors.rasi" "$COLOR_CACHE_DIR/rofi-colors.rasi" || return 1
        cp "$HOME/.cache/matugen/hyprland-colors.conf" "$COLOR_CACHE_DIR/hyprland-colors.conf" || return 1
        cp "$HOME/.cache/matugen/gtk-colors.css" "$COLOR_CACHE_DIR/gtk-colors.css" || return 1
        cp "$HOME/.config/mako/config" "$COLOR_CACHE_DIR/mako.conf" || return 1
        cp "$HOME/.config/yazi/theme.toml" "$COLOR_CACHE_DIR/yazi-theme.toml" || return 1

        touch "$COLOR_CACHE_DIR/.complete"
      }

      # Set wallpaper
      awww img "$WALLPAPER" \
        --transition-type "$TRANSITION" \
        --transition-duration 1

      # Remember for next login
      echo "$WALLPAPER" > ~/.cache/current-wallpaper
      ln -sf "$WALLPAPER" ~/.cache/current-wallpaper.img

      # Generate or restore color palette (pick most prominent color automatically)
      if ! restore_color_cache; then
        if matugen image "$WALLPAPER" --source-color-index 0; then
          save_color_cache || true
        fi
      fi

      # Reload waybar CSS
      pkill -SIGUSR2 waybar

      # Reload mako with new colors
      makoctl reload 2>/dev/null || true

      # Reload Hyprland config to pick up new border colors
      hyprctl reload 2>/dev/null || true

      # Reload GTK theme so running apps pick up new colors
      gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true

      # Generate resized copy for rofi card (fast load, no decode lag)
      magick "$WALLPAPER" -resize 600x ~/.cache/rofi-wallpaper.jpg 2>/dev/null || true
    '')
  ];

  # Ensure wallpapers directory exists
  home.file."Pictures/wallpapers/.keep".text = "";

  home.activation.bootstrapWallpaperState = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    fallback_wallpaper="${../../assets/avatar.png}"

    $DRY_RUN_CMD mkdir -p "$HOME/.cache"

    if [ ! -f "$HOME/.cache/current-wallpaper" ]; then
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c 'printf "%s\n" "$1" > "$2"' _ "$fallback_wallpaper" "$HOME/.cache/current-wallpaper"
    fi

    if [ ! -e "$HOME/.cache/current-wallpaper.img" ]; then
      $DRY_RUN_CMD ln -sfn "$fallback_wallpaper" "$HOME/.cache/current-wallpaper.img"
    fi
  '';

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "awww-daemon"
    ];

    windowrule = [
      "float true, match:title ^(Wallpaper Picker)$"
      "center true, match:title ^(Wallpaper Picker)$"
    ];

    bind = [
      "$mod CTRL, W, exec, gtk-wallpaper-picker"
    ];
  };
}
