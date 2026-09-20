{
  description = "A personal Neovim wrapper built with Nix.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSys =
        perSys:
        nixpkgs.lib.genAttrs [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ] (
          system:
          let
            hvim = nixpkgs.legacyPackages.${system}.callPackage ./package.nix { };
          in
          perSys hvim
        );
    in
    {
      overlays.default = final: prev: {
        hvim = final.callPackage ./package.nix { };
      };

      overlays.pinned = final: prev: {
        hvim = self.packages.${final.stdenv.hostPlatform.system}.default;
      };

      packages = forAllSys (hvim: {
        hvim = hvim;
        default = hvim;
      });
      apps = forAllSys (hvim: {
        hvim-luarc = {
          type = "app";
          program = "${hvim}/bin/hvim-luarc";
        };
      });
    };
}
