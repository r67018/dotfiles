{ pkgs, inputs, lib, config, ... }:

{
  # Core settings
  home.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;

  imports = [
    inputs.nixvim.homeModules.nixvim
    inputs.sops-nix.homeManagerModules.sops

    ../modules/git.nix
    ../modules/ssh.nix
    ../modules/zsh.nix
    ../modules/direnv.nix
    ../modules/bat.nix
    ../modules/nixvim.nix
    ../modules/vscode.nix
    ../modules/alacritty.nix
  ];

  # Common packages
  home.packages = with pkgs; [
    # CLI tools
    ripgrep
    jq
    sops
    gemini-cli

    # Dev tools
    python3
    dotnet-sdk_10
    nil # Nix language server
    typst
    tinymist # Typst
  ];

  # Common environment variables
  home.sessionVariables = {
    TERMINAL = "alacritty";
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    extensions = with pkgs; [
      github-copilot-cli
    ];
  };

  # Secret files
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets = {
      "ssh/private-servers" = {
        path = "${config.home.homeDirectory}/.ssh/config.d/private-servers";
        mode = "0600";
      };
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
  home.file.".ideavimrc".source = ../../.ideavimrc;
}
