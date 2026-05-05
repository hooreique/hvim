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
      luarcSchemaVersion = "v3.18.2";
      luaLSVscodeLuaBaseUrl = "https://raw.githubusercontent.com/LuaLS/vscode-lua/refs/tags/${luarcSchemaVersion}";
      luarcSchema = pkgs.fetchurl {
        url = "${luaLSVscodeLuaBaseUrl}/setting/schema.json";
        sha256 = "sha256-9iIVguhV85jc7sESYwEnkxEH849HFEtv/SaXwLQBH4Q=";
      };
      luarcSchemaLicense = pkgs.fetchurl {
        url = "${luaLSVscodeLuaBaseUrl}/LICENSE";
        sha256 = "sha256-cHSCTv/fzh1DUBOflSpHBnFhB+ImldbVEyeCzeG40SY=";
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

      patchedNeovim = pkgs.neovim-unwrapped.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/nvim/version.c \
            --replace-fail '"│ ╲ ││",' '"h       i    ",' \
            --replace-fail '"││╲╲││",' '"hhh v v i mmm",' \
            --replace-fail '"││ ╲ │",' '"h h  v  i mmm",' \
            --replace-fail 'N_(NVIM_VERSION_LONG),' '"hvim " NVIM_VERSION_MEDIUM,'
          substituteInPlace src/nvim/version.c \
            --replace-fail "      int attr = 0;" "      int attr = *p == 'h' ? string_attr : (*p == ' ' ? 0 : special_attr);"
        '';
      });

      wrappedNeovim = pkgs.wrapNeovim patchedNeovim {
        extraName = "-hvim";
        wrapperArgs = [
          "--set"  "NVIM_APPNAME"  "hvim"
          "--suffix"  "PATH"  ":"  (pkgs.lib.makeBinPath runtimePrograms)
        ];
      };

      hvim = pkgs.runCommand "hvim-${pkgs.lib.getVersion pkgs.neovim-unwrapped}" {
        meta = wrappedNeovim.meta // {
          mainProgram = "hvim";
          description = "A personal Neovim wrapper built with Nix.";
          homepage = "https://github.com/hooreique/hvim";
          license = pkgs.lib.unique ([ pkgs.lib.licenses.mit ] ++ (pkgs.lib.toList wrappedNeovim.meta.license));
        };
        nativeBuildInputs = [ pkgs.makeWrapper ];
      } ''
        mkdir -p "$out/bin"
        mkdir -p "$out/share"
        mkdir -p "$out/share/licenses/hvim"
        cp "${./LICENSE}" "$out/share/licenses/hvim/LICENSE"
        cp "${luarcSchemaLicense}" "$out/share/licenses/hvim/LuaLS-vscode-lua-LICENSE"
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
  });
}
