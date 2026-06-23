{
  config,
  lib,
  pkgs,
  kimi-code,
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
  home.enableNixpkgsReleaseCheck = false;

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

  programs.kitty = {
    enable = true;
    theme = "Galaxy";
    settings = {
      touch_scroll_multiplier = "6.0";
      wheel_scroll_multiplier = "6.0";
      hide_window_decorations = true;
      progress_bar = "hidden";
    };
    keybindings = {
      "alt+left" = "neighboring_window left";
      "alt+right" = "neighboring_window right";
      "alt+up" = "neighboring_window up";
      "alt+down" = "neighboring_window down";
      "ctrl+shift+enter" = "new_window_with_cwd";
      # New tab is created next to the current one instead of at the end.
      "ctrl+shift+t" = "launch --type=tab --location=after --cwd=current";
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
    TERMINAL = "kitty";
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    PYCHARM_VM_OPTIONS = "${config.home.homeDirectory}/.config/JetBrains/pycharm64.vmoptions";
  };

  home.sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];

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

  # Plasma: Ctrl+Alt+T запускает Kitty.
  qt.kde.settings = {
    kglobalshortcutsrc."services"."kitty.desktop"._launch = "Ctrl+Alt+T";
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
    nodejs_24
    opencode
    unzip
    jetbrains.pycharm
    temporal-cli
    obs-studio
    mpv
    toggleBluetoothDevice
    kimi-code
    gh
    happ-desktop
  ];
}
