{
  description = "CTDO Terminal Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nur.url = "github:nix-community/NUR";

    home-manager.url = "github:nix-community/home-manager/release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-generators, nur, home-manager, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          nixpkgs-cfg = {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };

          pkgs-unstable = import inputs.nixpkgs-unstable nixpkgs-cfg;
          pkgs = import inputs.nixpkgs (nixpkgs-cfg // {
            # Only add the overlay in normal nixpkgs
            overlays = [
              (self: super: {
                inherit (pkgs-unstable) google-chrome;
              })
            ];
          });

          lib = pkgs.lib;
        in
        rec {
          devShell = pkgs.mkShell {
            buildInputs = [ pkgs.go pkgs.cue pkgs.nixpkgs-fmt pkgs.kubectl ] ++
              lib.optionals (pkgs.system == "aarch64-darwin") [ pkgs-unstable.lima ];
          };

          packages = flake-utils.lib.flattenTree {
            vm_image = nixos-generators.nixosGenerate {
              inherit (systemConfiguration) pkgs system specialArgs;
              modules = systemConfiguration.modules ++ [
                { virtualisation.qemu.options = [ "-vga virtio" ]; }
                ({ config, pkgs, lib, modulesPath, ... }: {
                  system.stateVersion = config.system.nixos.release;
                })
              ];
              format = "vm";
            };

            run-pixiecore =
              let
                build = netboot.config.system.build;
              in
              pkgs.writers.writeBash "run-pixiecore" ''
                exec ${pkgs.pixiecore}/bin/pixiecore \
                  boot ${build.kernel}/bzImage ${build.netbootRamdisk}/initrd \
                  --cmdline "init=${build.toplevel}/init loglevel=4" \
                  --debug --dhcp-no-bind \
                  --port 64172 --status-port 64172 "$@"
              '';
          };

          apps = rec {
            # Allow repl inside this flake by using `nix run`
            vm = flake-utils.lib.mkApp {
              drv = packages.vm_image;
              exePath = "/bin/run-nixos-vm";
            };

            run-pixiecore = flake-utils.lib.mkApp {
              drv = packages.run-pixiecore;
              exePath = "";
            };

            default = vm;
          };


          netboot = nixpkgs.lib.nixosSystem {
            inherit (systemConfiguration) pkgs system specialArgs;
            modules = [
              ({ config, pkgs, lib, modulesPath, ... }: {
                imports = [
                  (modulesPath + "/installer/netboot/netboot-minimal.nix")
                ];
                system.stateVersion = config.system.nixos.release;
              })
            ] ++ systemConfiguration.modules;
          };

          systemConfiguration = {
            inherit pkgs system;
            modules = [
              ./modules/default.nix
            ];
            specialArgs = {
              inherit nixpkgs-unstable inputs;
            };
          };
        }
      );
}
