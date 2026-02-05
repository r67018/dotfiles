{ pkgs, ... }: {
  # Determine Installer との衝突を避けるための設定
  nix.enable = false;
  # 実験的機能の有効化
  nix.settings.experimental-features = "nix-command flakes";

  # システムパッケージ
  environment.systemPackages = [ pkgs.vim pkgs.git ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    newcomputermodern
  ];

  # システム設定
  system.primaryUser = "ryosei";
  system.defaults = {
    # ファインダーのタイトルにPOSIXパスを表示
    finder._FXShowPosixPathInTitle = true;
    # 拡張子を表示する
    finder.AppleShowAllExtensions = true;
    # ドックを爆速で隠し、画面を広く使う
    dock.autohide = true;
    dock.autohide-delay = 0.0;
    dock.autohide-time-modifier = 0.6;
    # タップでクリック
    trackpad.Clicking = true;
    # キーリピートを最速にする
    NSGlobalDomain.InitialKeyRepeat = 15; # 15が標準の最小値
    NSGlobalDomain.KeyRepeat = 2; # 2が標準の最小値
    # ファンクションキーを標準のファンクションキーとして使用
    NSGlobalDomain."com.apple.keyboard.fnState" = true;
  };

  # キーボード設定
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  system.keyboard.userKeyMapping = [
    {
      # Left Control -> Left Option
      HIDKeyboardModifierMappingSrc = 30064771296;
      HIDKeyboardModifierMappingDst = 30064771298;
    }
  ];

  # ホスト名・コンピュータ名
  networking.hostName = "greygoose";
  networking.computerName = "greygoose";

  # ユーザー設定
  users.users."ryosei".home = "/Users/ryosei";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  system.stateVersion = 5; 

  homebrew = {
    enable = true;
    casks = [
      "1password"
      "zen"
      "thunderbird"
      "slack"
      "discord"
      "microsoft-teams"
      "jetbrains-toolbox"
      "alacritty"
    ];

    brews = [
      "mas" # App Store アプリを管理するためのツール
    ];

    masApps = {
      "LINE" = 539883307; # LINEのアプリID
    };
  };

  services.aerospace = {
    enable = true;
    settings = {
      gaps = {
        inner = { horizontal = 0; vertical = 0; };
        outer = { left = 0; bottom = 0; top = 0; right = 0; };
      };
      on-window-detected = [
        { "if".app-id = "com.microsoft.teams"; run = "move-node-to-workspace 1"; }
        { "if".app-id = "com.hnc.Discord"; run = "move-node-to-workspace 1"; }
        { "if".app-id = "com.tinyspeck.slackmacgap"; run = "move-node-to-workspace 1"; }
        { "if".app-id = "org.mozilla.thunderbird"; run = "move-node-to-workspace 8"; }
        { "if".app-id = "com.1password.1password"; run = "layout floating"; }
      ];
      mode.main.binding = {
        "alt-enter" = "exec-and-forget open -n -a Alacritty";
        "alt-d" = "exec-and-forget /bin/bash -c 'sleep 0.1 && osascript -e \"tell application \\\"System Events\\\" to keystroke space using command down\"'";
        "alt-q" = "close";
        "alt-h" = "focus left";
        "alt-j" = "focus down";
        "alt-k" = "focus up";
        "alt-l" = "focus right";
        "alt-shift-h" = "move left";
        "alt-shift-j" = "move down";
        "alt-shift-k" = "move up";
        "alt-shift-l" = "move right";
        "alt-1" = "workspace 1";
        "alt-2" = "workspace 2";
        "alt-3" = "workspace 3";
        "alt-4" = "workspace 4";
        "alt-5" = "workspace 5";
        "alt-6" = "workspace 6";
        "alt-7" = "workspace 7";
        "alt-8" = "workspace 8";
        "alt-9" = "workspace 9";
        "alt-shift-1" = "move-node-to-workspace 1";
        "alt-shift-2" = "move-node-to-workspace 2";
        "alt-shift-3" = "move-node-to-workspace 3";
        "alt-shift-4" = "move-node-to-workspace 4";
        "alt-shift-5" = "move-node-to-workspace 5";
        "alt-shift-6" = "move-node-to-workspace 6";
        "alt-shift-7" = "move-node-to-workspace 7";
        "alt-shift-8" = "move-node-to-workspace 8";
        "alt-shift-9" = "move-node-to-workspace 9";
        "alt-f" = "fullscreen";
        "alt-s" = "layout v_accordion"; # mimic stacking
        "alt-w" = "layout h_accordion"; # mimic tabbed
        "alt-e" = "layout tiles horizontal vertical"; # toggle split
        "alt-b" = "layout tiles horizontal"; # split horizontal (sway style)
        "alt-v" = "layout tiles vertical"; # split vertical (sway style)
        "alt-shift-space" = "layout floating tiling";
        "alt-r" = "mode resize";
      };
      mode.resize.binding = {
        "h" = "resize width -50";
        "j" = "resize height +50";
        "k" = "resize height -50";
        "l" = "resize width +50";
        "enter" = "mode main";
        "esc" = "mode main";
      };
    };
  };
}

