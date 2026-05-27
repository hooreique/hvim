{
  fd,       lemminx,     makeWrapper,
  gcc,      ripgrep,     tree-sitter,
  lib,      fetchurl,    runtimeShell,
  nil,      coreutils,   vscode-js-debug,
  curl,     gitMinimal,  neovim-unwrapped,
  gnutar,   runCommand,  lua-language-server,
  gnumake,  wrapNeovim,  yaml-language-server,
  vscode-langservers-extracted,
}:

let
  luarcSchemaVersion = "v3.18.2";
  luaLSVscodeLuaBaseUrl = "https://raw.githubusercontent.com/LuaLS/vscode-lua/refs/tags/${luarcSchemaVersion}";
  luarcSchema = fetchurl {
    url = "${luaLSVscodeLuaBaseUrl}/setting/schema.json";
    sha256 = "sha256-9iIVguhV85jc7sESYwEnkxEH849HFEtv/SaXwLQBH4Q=";
  };
  luarcSchemaLicense = fetchurl {
    url = "${luaLSVscodeLuaBaseUrl}/LICENSE";
    sha256 = "sha256-cHSCTv/fzh1DUBOflSpHBnFhB+ImldbVEyeCzeG40SY=";
  };

  runtimePrograms = [
    fd    gnutar   gitMinimal
    gcc   gnumake  tree-sitter
    nil   lemminx  vscode-js-debug
    curl  ripgrep  lua-language-server
    yaml-language-server
    vscode-langservers-extracted
  ];

  patchedNeovim = neovim-unwrapped.overrideAttrs (old: {
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

  wrappedNeovim = wrapNeovim patchedNeovim {
    extraName = "-hvim";
    wrapperArgs = [
      "--set"     "NVIM_APPNAME"  "hvim"
      "--suffix"  "PATH"  ":"  (lib.makeBinPath runtimePrograms)
    ];
  };
in

runCommand "hvim-${lib.getVersion neovim-unwrapped}"
  {
    meta = {
      mainProgram = "hvim";
      description = "A personal Neovim wrapper built with Nix.";
      homepage = "https://github.com/hooreique/hvim";
      license = lib.licenses.mit;
    };
    nativeBuildInputs = [ makeWrapper ];
  }
  ''
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
          "${patchedNeovim}/share/nvim/runtime/lua",
          "${patchedNeovim}/share/nvim/runtime/lua/vim/lsp"
        ]
      }
    }
    EOF
    makeWrapper "${wrappedNeovim}/bin/nvim" "$out/bin/hvim" --prefix PATH : "$out/bin"
    cat > "$out/bin/hvim-luarc" <<EOF
    #!${runtimeShell}
    exec ${coreutils}/bin/cat "$out/share/luarc.hvim-config.json"
    EOF
    chmod +x "$out/bin/hvim-luarc"
  ''
