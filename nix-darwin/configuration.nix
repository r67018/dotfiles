{ pkgs, ... }: {
  # Determine Installer との衝突を避けるための設定
  nix.enable = false;
  # 実験的機能の有効化
  nix.settings.experimental-features = "nix-command flakes";

  # システムパッケージ
  environment.systemPackages = [ pkgs.vim pkgs.git ];

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
  };

  # キーボード設定
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;

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
    ];
  };
}

