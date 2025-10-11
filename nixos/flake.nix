{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    xremap.url = "github:xremap/nix-flake"; # Tool for remapping key binding
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    nixosConfigurations = {
      desktop = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./hosts/desktop/hardware-configuration.nix
          inputs.sops-nix.nixosModules.sops
        ];
        specialArgs = {
            inherit inputs;
        };
      };
      laptop = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./hosts/laptop/configuration.nix
          ./hosts/laptop/hardware-configuration.nix
          inputs.sops-nix.nixosModules.sops
        ];
        specialArgs = {
            inherit inputs;
        };
      };
    };
  };
}
