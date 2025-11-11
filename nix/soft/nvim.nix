{pkgs, ...}:
# let
#   treesitterWithGrammars = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
#     p.bash
#     p.comment
#     p.css
#     p.dockerfile
#     p.fish
#     p.gitattributes
#     p.gitignore
#     p.go
#     p.gomod
#     p.gowork
#     p.javascript
#     p.jq
#     p.json
#     p.json5
#     p.lua
#     p.make
#     p.markdown
#     p.markdown_inline
#     p.diff
#     p.zig
#     p.sql
#     p.nix
#     p.proto
#     p.pug
#     p.python
#     p.rust
#     p.svelte
#     p.toml
#     p.typescript
#     p.vue
#     p.yaml
#   ]);
#
#   treesitter-parsers = pkgs.symlinkJoin {
#     name = "treesitter-parsers";
#     paths = treesitterWithGrammars.dependencies;
#   };
# in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
  home-manager.sharedModules = [
    {
      programs.neovim = {
        enable = true;
        package = pkgs.neovim-unwrapped;
        withNodeJs = true;
        coc.enable = false;
        plugins = [
          # treesitterWithGrammars
        ];
      };
    }
  ];
  # system.activationScripts.writeNeovim = ''
  #   if [ ! -d "/opt/nvim" ]; then
  #     mkdir -p /opt/nvim
  #     cd /opt/nvim
  #     ${pkgs.git}/bin/git clone -b dev --depth=1 https://github.com/i18n-site/lazyvim.git config
  #     mkdir -p /root
  #     # cd config/lua/config
  #     # echo '
  #     # vim.opt.runtimepath:append("${treesitter-parsers}")
  #     # require("lazy").setup("plugins", {
  #     #   spec = {
  #     #     { "nvim-treesitter/nvim-treesitter", dev = true },
  #     #   },
  #     #   dev = {
  #     #     path = "${treesitterWithGrammars}",
  #     #     patterns = { "nvim-treesitter" },
  #     #     fallback = false,
  #     #   }
  #     # })' > treesitter.lua
  #     # grep -qF "config.treesitter" options.lua || echo "require('config.treesitter')" >> options.lua
  #     # cd /opt/nvim
  #     # mkdir -p plugin
  #     # cd plugin
  #     # ${pkgs.rsync}/bin/rsync -av ${treesitterWithGrammars} nvim-treesitter
  #   fi
  # '';
}
