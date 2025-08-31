{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    xremap.url = "github:xremap/nix-flake"; # Tool for remapping key binding
  };

  outputs = inputs: {
    nixosConfigurations = {
      desktop = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
	  ./hosts/desktop/hardware-configuration.nix
        ];
        specialArgs = {
            inherit inputs;
        };
      };
      laptop = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./hosts/laptop/hardware-configuration.nix
        ];
        specialArgs = {
            inherit inputs;
        };
      };
    };
  };
}
