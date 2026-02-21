{
  description = "Home Manager configuration of ryosei";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, home-manager, zen-browser, nixvim, ... } @ inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Export modules for reuse
      homeManagerModules = {
        common = import ./hosts/common.nix;
        personal = import ./hosts/personal/default.nix;
        work = import ./hosts/work/default.nix;
        linux-desktop = import ./hosts/linux-desktop/default.nix;
      };

      homeConfigurations."ryosei" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./home.nix
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = { inherit inputs; };
      };

      darwinModules = {
        # Default (Personal Mac)
        default = {
          home-manager.users.ryosei = {
             home.username = "ryosei";
             home.homeDirectory = "/Users/ryosei";
             imports = [
               self.homeManagerModules.common
               self.homeManagerModules.personal
             ];
          };
          home-manager.extraSpecialArgs = { inherit inputs; };
        };

        # Work Mac
        work = {
          home-manager.users.r_goto = {
             home.username = "r_goto";
             home.homeDirectory = "/Users/r_goto";
             imports = [
               self.homeManagerModules.common
               self.homeManagerModules.work
             ];
          };
          home-manager.extraSpecialArgs = { inherit inputs; };
        };
      };
    };
}
