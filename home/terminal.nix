# Ghostty terminal configuration
{ config, lib, pkgs, ... }:

let
  theme = import ./theme.nix;
  p = theme.palette;

  # Compiled into ~/.terminfo so mosh-server/ssh on Linux can resolve
  # TERM=xterm-ghostty and advertise 256 colors instead of falling back
  # to 8-color TERM=xterm.
  ghosttyTerminfo = pkgs.runCommand "xterm-ghostty-terminfo" {
    nativeBuildInputs = [ pkgs.ncurses ];
  } ''
    export TERMINFO="${pkgs.ncurses}/share/terminfo"
    mkdir -p "$out"
    tic -x -o "$out" ${./configs/xterm-ghostty.terminfo}

    # ncurses may hash names (78/) or use the first letter (x/). Install both
    # so macOS and Linux resolve TERM=xterm-ghostty.
    copy_both() {
      hashed="$1"
      letter="$2"
      name="$3"
      if [ -e "$out/$hashed/$name" ]; then
        mkdir -p "$out/$letter"
        cp "$out/$hashed/$name" "$out/$letter/$name"
      elif [ -e "$out/$letter/$name" ]; then
        mkdir -p "$out/$hashed"
        cp "$out/$letter/$name" "$out/$hashed/$name"
      fi
    }
    copy_both 78 x xterm-ghostty
    copy_both 67 g ghostty
    if [ ! -e "$out/78/xterm-ghostty" ] && [ ! -e "$out/x/xterm-ghostty" ]; then
      echo "tic did not produce xterm-ghostty" >&2
      find "$out" -type f >&2
      exit 1
    fi
  '';

  ghosttyConfig = ''
    theme = "${theme.ghosttyThemeName}"
    font-family = "PragmataPro Liga"
    cursor-style = block
    shell-integration-features = no-cursor,ssh-terminfo,ssh-env
    keybind = "ctrl+l=unbind"

    clipboard-read = "allow"
    clipboard-write = "allow"
    clipboard-paste-protection = false
    clipboard-paste-bracketed-safe = false
  '';

  # Generated from palette — single source of truth
  ghosttyOC1Theme = ''
    background = ${p.base}
    foreground = ${p.text}
    cursor-color = ${p.primary}
    selection-background = ${p.surface1}
    selection-foreground = ${p.subtext1}

    # Normal colors (0-7)
    palette = 0=#${p.base}
    palette = 1=#${p.red}
    palette = 2=#${p.green}
    palette = 3=#${p.yellow}
    palette = 4=#${p.blue}
    palette = 5=#${p.mauve}
    palette = 6=#${p.teal}
    palette = 7=#${p.text}

    # Bright colors (8-15)
    palette = 8=#${p.subtext0}
    palette = 9=#${p.maroon}
    palette = 10=#${p.bright_green}
    palette = 11=#${p.bright_yellow}
    palette = 12=#${p.bright_blue}
    palette = 13=#${p.bright_magenta}
    palette = 14=#${p.bright_cyan}
    palette = 15=#${p.subtext1}
  '';

in {
  home.file.".terminfo" = {
    source = ghosttyTerminfo;
    recursive = true;
  };

  xdg.configFile = {
    "ghostty/config".text = ghosttyConfig;
  } // lib.optionalAttrs (theme.themeFamily == "opencode") {
    "ghostty/themes/OpenCode-OC1-Dark".text = ghosttyOC1Theme;
  };
}
