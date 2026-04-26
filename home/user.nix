{
  config,
  lib,
  pkgs,
  ...
}:

let
  toggleBluetoothDevice = pkgs.writeShellScriptBin "toggle-bt-ac800a87d652" ''
    #!/bin/sh
    set -eu

    device='AC:80:0A:87:D6:52'
    bluetoothctl='${pkgs.bluez}/bin/bluetoothctl'

    if "$bluetoothctl" info "$device" | ${pkgs.gnugrep}/bin/grep -q '^[[:space:]]*Connected: yes$'; then
      exec "$bluetoothctl" disconnect "$device"
    fi

    "$bluetoothctl" power on
    exec "$bluetoothctl" connect "$device"
  '';

  amneziaVpnSafeLauncher = pkgs.writeShellScriptBin "amnezia-vpn-safe-launcher" ''
    #!/bin/sh
    if [ -n "''${WAYLAND_DISPLAY-}" ]; then
      export QT_QPA_PLATFORM=wayland
    fi

    export QT_XCB_GL_INTEGRATION=none
    export QT_QUICK_BACKEND=software

    exec /run/current-system/sw/bin/AmneziaVPN "$@"
  '';
in
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

  programs.htop.enable = true;

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

  programs.yazi = {
    enable = true;
    settings = {
      mgr = {
        show_hidden = true;
      };
    };
  };

  home.file.".config/zed/settings.json".text = builtins.readFile ./zed/settings.json;

  home.file.".config/JetBrains/pycharm64.vmoptions".text = ''
    -Dawt.toolkit.name=WLToolkit
  '';

  home.sessionVariables = {
    TERMINAL = "alacritty";
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    PYCHARM_VM_OPTIONS = "${config.home.homeDirectory}/.config/JetBrains/pycharm64.vmoptions";
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

  xdg.desktopEntries.toggle-bluetooth-ac800a87d652 = {
    name = "Toggle Bluetooth Device";
    exec = "${toggleBluetoothDevice}/bin/toggle-bt-ac800a87d652";
    terminal = false;
    categories = [ "Utility" ];
  };

  home.file.".local/share/applications/AmneziaVPN.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=AmneziaVPN
      Version=4.8.6.0
      Comment=Client of your self-hosted VPN
      Exec=${amneziaVpnSafeLauncher}/bin/amnezia-vpn-safe-launcher
      Icon=/run/current-system/sw/share/pixmaps/AmneziaVPN.png
      Categories=Network;Qt;Security;
      Terminal=false
      StartupNotify=true
    '';
  };

  # Plasma: Ctrl+Alt+T запускает Alacritty.
  qt.kde.settings = {
    kglobalshortcutsrc."services"."Alacritty.desktop"._launch = "Ctrl+Alt+T";
    kglobalshortcutsrc."services"."toggle-bluetooth-ac800a87d652.desktop"._launch = "Ctrl+B";
  };

  home.packages = with pkgs; [
    delta
    neovim
    telegram-desktop
    google-chrome
    zed-editor
    bat
    dua
    jq
    fastfetch
    uv
    ty
    gnumake
    glow # Markdown terminal reader
    nodejs_25
    opencode
    unzip
    jetbrains.pycharm
    temporal-cli
    obs-studio
    mpv
    toggleBluetoothDevice
  ];
}
