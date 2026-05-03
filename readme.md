# hvim

Personal Neovim wrapper.

This flake builds `hvim`, a wrapped `neovim-unwrapped` for my own Neovim profile.

## Purpose

`hvim` is not a general Neovim distribution.

It is a small wrapper for running a separate personal Neovim environment with a pinned Nix toolchain.

## Usage

```sh
nix run
# or
nix run .#hvim
````

Build:

```sh
nix build
./result/bin/hvim
```

## NVIM_APPNAME

The wrapper sets:

```sh
NVIM_APPNAME=hvim
```

So Neovim uses `hvim`-specific paths instead of the default `nvim` ones:

```text
~/.config/hvim
~/.local/share/hvim
~/.local/state/hvim
~/.cache/hvim
```

This keeps `hvim` isolated from normal `nvim`.

## PATH

The wrapper appends runtime tools to `PATH` so they are available inside Neovim.

Current examples include language servers, debuggers, and common editor tools such as:

```text
ripgrep
fd
tree-sitter
lua-language-server
nil
vscode-langservers-extracted
yaml-language-server
lemminx
vscode-js-debug
```

Add tools to `runtimePrograms` in `flake.nix` when they should be visible from inside `hvim`.

## hvim-luarc

The package also provides:

```sh
hvim-luarc
```

It prints the generated LuaLS config for this wrapper.

After building:

```sh
./result/bin/hvim-luarc
```

This is mainly for reusing the generated LuaLS settings from editor config or for debugging.
