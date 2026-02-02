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
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
  };

  # ユーザー設定
  users.users."ryosei".home = "/Users/ryosei";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  system.stateVersion = 5; 
}

