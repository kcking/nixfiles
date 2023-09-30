{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, home-manager, ... }: {

    nixosConfigurations.sentrynixos = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [ 
        ./configuration.nix 
        home-manager.nixosModules.home-manager
        {
		home-manager.useGlobalPkgs = true;
		home-manager.useUserPackages = true;
        }
      ];
    };
  };
}
