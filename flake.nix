{
  description = "A personal Neovim wrapper built with Nix.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system: let
    pkgs = inputs.nixpkgs.legacyPackages.${system};
  in {
    packages = let
      luarcSchema = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/LuaLS/vscode-lua/refs/tags/v3.18.2/setting/schema.json";
        sha256 = "sha256-9iIVguhV85jc7sESYwEnkxEH849HFEtv/SaXwLQBH4Q=";
      };

      runtimePrograms = [
        pkgs.fd                   pkgs.nodejs_24
        pkgs.gcc                  pkgs.ripgrep
        pkgs.gitMinimal           pkgs.tree-sitter
        pkgs.gnumake              pkgs.vscode-langservers-extracted
        pkgs.lemminx              pkgs.vscode-js-debug
        pkgs.lua-language-server  pkgs.yaml-language-server
        pkgs.nil
      ];

      wrappedNeovim = pkgs.wrapNeovim pkgs.neovim-unwrapped {
        extraName = "-hvim";
        wrapperArgs = [
          "--set"  "NVIM_APPNAME"  "hvim"
          "--suffix"  "PATH"  ":"  (pkgs.lib.makeBinPath runtimePrograms)
        ];
      };

      hvim = pkgs.runCommand "hvim-${pkgs.lib.getVersion pkgs.neovim-unwrapped}" {
        meta = wrappedNeovim.meta // {
          description = "A personal Neovim wrapper built with Nix.";
          mainProgram = "hvim";
        };
        nativeBuildInputs = [ pkgs.makeWrapper ];
      } ''
        mkdir -p "$out/bin"
        mkdir -p "$out/share"
        cp "${luarcSchema}" "$out/share/luarc-schema.json"
        cat > "$out/share/luarc.hvim-config.json" <<EOF
        {
          "\''$schema": "file://$out/share/luarc-schema.json",
          "runtime": {
            "version": "LuaJIT"
          },
          "workspace": {
            "library": [
              "${pkgs.neovim-unwrapped}/share/nvim/runtime/lua",
              "${pkgs.neovim-unwrapped}/share/nvim/runtime/lua/vim/lsp"
            ]
          }
        }
        EOF
        makeWrapper "${wrappedNeovim}/bin/nvim" "$out/bin/hvim" --prefix PATH : "$out/bin"
        cat > "$out/bin/hvim-luarc" <<EOF
        #!${pkgs.runtimeShell}
        exec ${pkgs.coreutils}/bin/cat "$out/share/luarc.hvim-config.json"
        EOF
        chmod +x "$out/bin/hvim-luarc"
      '';
    in {
      inherit hvim;
      default = hvim;
    };

    apps = {
      hvim = {
        type = "app";
        program = "${inputs.self.packages.${system}.hvim}/bin/hvim";
      };
      default = inputs.self.apps.${system}.hvim;
    };
  });
}
