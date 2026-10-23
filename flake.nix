{
  description = "Tundra — a minimal NixOS desktop with Niri and Dux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dux-shell = {
      url = "github:duxlabs-dev/dux-shell/v2.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-greeter = {
      url = "github:duxlabs-dev/dux-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-calendar = {
      url = "github:duxlabs-dev/dux-calendar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-files = {
      url = "github:duxlabs-dev/dux-files";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosModules.default = {
        imports = [
          inputs.dux-shell.nixosModules.default
          inputs.dux-greeter.nixosModules.default
          inputs.dux-calendar.nixosModules.default
          inputs.dux-files.nixosModules.default
          ./modules/desktop.nix
          ./modules/apps.nix
        ];
      };
      nixosConfigurations.tundra-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.default
          ./hosts/vm
        ];
      };
      nixosConfigurations.tundra-test = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.default
          ./hosts/test-machine
        ];
      };
      packages.${system} = {
        vm = self.nixosConfigurations.tundra-vm.config.system.build.vm;
        vm-greeter-test =
          (import ./tests/vm.nix {
            inherit pkgs;
            tundraModule = self.nixosModules.default;
            graphical = true;
          }).driver;
      };
      checks.${system}.vm-smoke = import ./tests/vm.nix {
        inherit pkgs;
        tundraModule = self.nixosModules.default;
      };
      formatter.${system} = pkgs.nixfmt;
    };
}
