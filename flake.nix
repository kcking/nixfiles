{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    xremap-flake.url = "github:xremap/nix-flake";
  };
  outputs = { self, nixpkgs, home-manager, xremap-flake, ... }: {

    nixosConfigurations.sentrynixos = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [ 
        ./configuration.nix 
        home-manager.nixosModules.home-manager
        {
		home-manager.useGlobalPkgs = true;
		home-manager.useUserPackages = true;
        }
	# TODO: use home-manager setup for xremap
	# https://github.com/xremap/nix-flake/#using-home-manager-on-non-nixos-system
	xremap-flake.nixosModules.default
        {
          services.xremap = {
            userName = "kevin";  # run as a systemd service in kevin
            serviceMode = "user";  # run xremap as user
            config = {
	      withSway = true;
              modmap = [
	        {
                name = "Global";
                remap = {
                  # TODO: this doesn't actually work, followed https://www.reddit.com/r/AsahiLinux/comments/zmuz5l/is_there_a_way_to_remap_fn_to_ctrl/j0ey4ev/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button instead
                  "XF86Fn" = "Control_L"; 
                   "Control_L" = "XF86Fn";
                };
		}
              ];
            };
          };
        }
      ];
    };
  };
}
