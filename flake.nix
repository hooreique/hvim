{
  description = "A personal Neovim wrapper built with Nix.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "aarch64-darwin"  "aarch64-linux"  "x86_64-linux" ];
    perSystem = { pkgs, ... }: let
      hvim = pkgs.callPackage ./package.nix { };
    in {
      packages.hvim = hvim;
      packages.default = hvim;
      apps.hvim-luarc.program = "${hvim}/bin/hvim-luarc";
    };
  };
}
