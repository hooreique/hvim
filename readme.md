```plaintext
h       i
hhh v v i mmm
h h  v  i mmm
```

# hvim

Personal Nix wrapper for running my Neovim as `NVIM_APPNAME=hvim`.

- Default package/app is `hvim`; LuaLS config helper is `nix run .#hvim-luarc`.
- Config/data/state/cache use `hvim`, not `nvim`.
- Tools visible inside Neovim live in `runtimePrograms` in `package.nix`.
- `neovim-unwrapped` is only patched for the start screen banner and version string.
