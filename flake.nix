{
  description = "Tests for Seeed Studio XIAO ESP32C3";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (system:
      let
        inherit (nixpkgs) lib;
        inherit ((builtins.fromTOML (builtins.readFile ./Cargo.toml)).package) name;

        nixpkgs-patched = (import nixpkgs { inherit system; }).applyPatches {
          name = "cargo-linker-fix";
          src = nixpkgs;
          # Fix:
          #   >   = note: x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '-flavor'
          #   >           x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '--as-needed'; did you mean '-mno-needed'?
          #   >           x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '--gc-sections'; did you mean '--data-sections'?
          #   >
          # by forcing LLD as a linker
          # Also make things more verbose.
          patches = [ ./cargo-linker-fix.patch ];
        };

        pkgs = import nixpkgs-patched {
          inherit system;
          overlays = [
            (import rust-overlay)
          ];
        };

        pkgsCross = import nixpkgs-patched {
          inherit system;
          crossSystem = {
            inherit system;
            rustc.config = "riscv32imc-unknown-none-elf";
          };
        };

        toolchain = (
          pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml
        );

        rustPlatform = pkgsCross.makeRustPlatform {
          rustc = toolchain;
          cargo = toolchain;
        };

      in
        {
          packages.default = pkgs.callPackage ./. {
            inherit name rustPlatform;
          };

          devShells.default = pkgs.mkShell ({
            name = "${name}-dev";
            buildInputs = [
              pkgs.cargo-espflash
              pkgs.cargo-generate
              toolchain
            ];
          } // (import ./wifi-settings.nix));

          apps = rec {
            default = flash;

            flash = let
              flashScript = pkgs.writeShellApplication {
                name = "flash-${name}";
                runtimeInputs = [
                  pkgs.cargo-espflash
                ];
                text = ''
                  espflash --monitor ${self.packages.${system}.default}/bin/${name}
                '';
              };
            in {
              type = "app";
              program = "${lib.getExe flashScript}";
            };
          };
        }
    );
}
