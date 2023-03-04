{
  description = "My Rust Project";

  inputs = {
    nixpkgs = {url = "github:NixOS/nixpkgs/nixpkgs-unstable";};

    flake-utils = {url = "github:numtide/flake-utils";};

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
    };

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    crane,
    flake-utils,
    advisory-db,
    rust-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay)];
      };

      librusty_v8 = pkgs.callPackage ./librusty_v8.nix {};

      rustStable =
        pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      craneLib = (crane.mkLib pkgs).overrideToolchain rustStable;
      src = ./.;
      cargoArtifacts = craneLib.buildDepsOnly {
        inherit src buildInputs;
        RUSTY_V8_ARCHIVE = librusty_v8;
      };
      buildInputs = [];

      my-rust-package = craneLib.buildPackage {
        inherit src cargoArtifacts;
        doCheck = false;
        RUSTY_V8_ARCHIVE = librusty_v8;
      };
      my-rust-package-clippy = craneLib.cargoClippy {
        inherit cargoArtifacts src buildInputs;
        cargoClippyExtraArgs = "--all-targets -- --deny warnings";
        RUSTY_V8_ARCHIVE = librusty_v8;
      };
      my-rust-package-fmt = craneLib.cargoFmt {
        inherit src cargoArtifacts;
        RUSTY_V8_ARCHIVE = librusty_v8;
      };
      my-rust-package-audit = craneLib.cargoAudit {
        inherit src cargoArtifacts advisory-db;
        RUSTY_V8_ARCHIVE = librusty_v8;
      };
      my-rust-package-nextest = craneLib.cargoNextest {
        inherit cargoArtifacts src buildInputs;
        partitions = 1;
        partitionType = "count";
        RUSTY_V8_ARCHIVE = librusty_v8;
      };
    in {
      checks = {
        inherit my-rust-package my-rust-package-audit my-rust-package-clippy my-rust-package-fmt my-rust-package-nextest;
      };

      packages.default = my-rust-package;

      apps.default = flake-utils.lib.mkApp {drv = my-rust-package;};

      devShells.default = pkgs.mkShell {
        inputsFrom = builtins.attrValues self.checks;

        nativeBuildInputs = with pkgs; [
          cargo-edit
          cargo-nextest
          cargo-release
          rustStable
        ];
      };
    });
}
