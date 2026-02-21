{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    my-home.url = "path:../home-manager";
  };

  outputs =
    {
      home-manager,
      darwin,
      my-home,
      ...
    }:
    {
      darwinConfigurations = {
        "greygoose" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          # specialArgs = { inherit inputs; };
          modules = [
            ./hosts/common.nix
            ./hosts/greygoose/default.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
            }
            my-home.darwinModules.default
          ];
        };
        
        "work" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./hosts/common.nix
            ./hosts/work/default.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
            }
            my-home.darwinModules.work
          ];
        };
      };
    };
}
