{
  description = "Tests for Seeed Studio XIAO ESP32C3";
  inputs = {
    # Moving to release-23.11 causes errors:
    #   >   = note: x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '-flavor'
    #   >           x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '--as-needed'; did you mean '-mno-needed'?
    #   >           x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '--gc-sections'; did you mean '--data-sections'?
    #   >
    nixpkgs.url = "github:nixos/nixpkgs";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay }: let
    inherit (nixpkgs) lib;
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    systemClosure = attrs:
      builtins.foldl' (acc: system:
        lib.recursiveUpdate acc (attrs system)) {}
      systems;
  in
    systemClosure (
      system: let
        inherit ((builtins.fromTOML (builtins.readFile ./Cargo.toml)).package) name;

        nixpkgs-patched = (import nixpkgs { inherit system; }).applyPatches {
          name = "cargo-linker-fix";
          src = nixpkgs;
          patches = [ ./cargo-linker-fix.patch ];
        };

        pkgs = import nixpkgs-patched {
          inherit system;
          overlays = [(import rust-overlay)];
        };

        toolchain = (
          pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml
        );
        rustPlatform = let
          pkgsCross = import nixpkgs-patched {
            inherit system;
            crossSystem = {
              inherit system;
              rustc.config = "riscv32imc-unknown-none-elf";
            };
          };
        in
          pkgsCross.makeRustPlatform
          {
            rustc = toolchain;
            cargo = toolchain;
          };
      in {
        packages.${system}.default = pkgs.callPackage ./. {
          inherit name rustPlatform;
        };

        devShells.${system}.default = pkgs.mkShell ({
          name = "${name}-dev";
          buildInputs = [
            pkgs.cargo-espflash
            pkgs.cargo-generate
            toolchain
          ];
        } // (import ./wifi-settings.nix));

        apps.${system} = {
          default = let
            flash = pkgs.writeShellApplication {
              name = "flash-${name}";
              runtimeInputs = [ pkgs.cargo-espflash ];
              text = ''
                espflash --monitor ${self.packages.${system}.default}/bin/${name}
              '';
            };
          in {
            type = "app";
            program = "${pkgs.lib.getExe flash}";
          };
        };
      }
    );
}
