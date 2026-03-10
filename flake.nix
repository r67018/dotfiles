{
  description = "Unified NixOS, nix-darwin and Home Manager configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # nix-darwin
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixVim
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen Browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }@inputs:
    let
      # Shared Home Manager modules from the old home-manager/flake.nix
      homeManagerModules = {
        common = import ./home-manager/hosts/common.nix;
        personal = import ./home-manager/hosts/personal/default.nix;
        work = import ./home-manager/hosts/work/default.nix;
        linux-desktop = import ./home-manager/hosts/linux-desktop/default.nix;
      };
    in
    {
      # macOS (nix-darwin) configurations
      darwinConfigurations = {
        "greygoose" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; };
          modules = [
            ./nix-darwin/hosts/common.nix
            ./nix-darwin/hosts/greygoose/default.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.ryosei = {
                home.username = "ryosei";
                home.homeDirectory = "/Users/ryosei";
                imports = [
                  homeManagerModules.common
                  homeManagerModules.personal
                ];
              };
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };

        "work" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; };
          modules = [
            ./nix-darwin/hosts/common.nix
            ./nix-darwin/hosts/work/default.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.r_goto = {
                home.username = "r_goto";
                home.homeDirectory = "/Users/r_goto";
                imports = [
                  homeManagerModules.common
                  homeManagerModules.work
                ];
              };
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };
      };

      # Linux / Home Manager only configurations
      homeConfigurations = {
        "ryosei" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home-manager/home.nix
          ];
        };
      };
    };
}
