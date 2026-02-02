{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    my-home.url = "../home-manager";
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
            ./configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # home-manager.users.ryosei = ../home-manager/home.nix;

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
	      # home-manager.extraSpecialArgs = { inherit inputs; };
            }
            my-home.darwinModules.default
          ];
        };
      };
    };
}
