{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.username = "artem";
  home.homeDirectory = "/home/artem";
  home.stateVersion = "26.05";

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
    plugins = [
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
    ];
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.onlyoffice.enable = true;

  programs.bottom.enable = true;

  programs.alacritty = {
    enable = true;
    # theme = "xterm";
    theme = "blood_moon";
    settings = {
      window.startup_mode = "Maximized";
      env.TERM = "xterm-256color";
      font.size = 11;
    };
  };

  programs.git = {
    enable = true;
    settings = {
      core = {
        editor = "vim";
        pager = "delta";
      };
      interactive = {
        diffFilter = "delta --color-only";
      };
    };
  };

  programs.vim = {
    enable = true;
    extraConfig = ''
      syntax on
    '';
  };

  programs.zellij = {
    enable = true;
    settings = {
      show_startup_tips = false;
      copy_on_select = false;
    };
    extraConfig = ''
      keybinds {
        normal {
          bind "Alt c" { Copy; }
        }
      }
    '';
  };

  home.file.".config/zed/settings.json".text = builtins.readFile ./zed/settings.json;

  home.sessionVariables = {
    TERMINAL = "alacritty";
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
  };

  home.sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];

  home.activation.installCodexFromNpm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CODEX_NPM_PREFIX="${config.home.homeDirectory}/.npm-global"
    CODEX_BIN="$CODEX_NPM_PREFIX/bin/codex"
    NPM="${pkgs.nodejs_25}/bin/npm"
    TIMEOUT="${pkgs.coreutils}/bin/timeout"

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$CODEX_NPM_PREFIX"

    # Не делаем npm install на каждом boot: ставим Codex только если бинарник отсутствует.
    if [ ! -x "$CODEX_BIN" ]; then
      echo "codex not found, installing @openai/codex into $CODEX_NPM_PREFIX"
      if ! $DRY_RUN_CMD "$TIMEOUT" 45s "$NPM" install \
        --prefix "$CODEX_NPM_PREFIX" \
        --global \
        --no-audit \
        --no-fund \
        @openai/codex; then
        echo "warning: codex install timed out or failed; skipping for this activation"
      fi
    fi
  '';

  # Plasma: Ctrl+Alt+T запускает Alacritty.
  qt.kde.settings = {
    kglobalshortcutsrc."services"."Alacritty.desktop"._launch = "Ctrl+Alt+T";
  };

  home.packages = with pkgs; [
    delta
    neovim
    code-cursor
    telegram-desktop
    google-chrome
    zed-editor
    bat
    dua
    jq
    neofetch
    uv
    ty
    mongodb-compass
    gnumake
    glow # Markdown terminal reader
    yazi
    nodejs_25
  ];
}
