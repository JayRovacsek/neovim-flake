{lib}:
with lib; let
  # Plugin must be same as input name from flake.nix
  availablePlugins = [
    # TODO: sort by category
    "nvim-treesitter-context"
    "gitsigns-nvim"
    "plenary-nvim"
    "nvim-lspconfig"
    "nvim-treesitter"
    "lspsaga"
    "lspkind"
    "nvim-lightbulb"
    "lsp-signature"
    "nvim-tree-lua"
    "nvim-bufferline-lua"
    "lualine"
    "nvim-compe"
    "nvim-autopairs"
    "nvim-ts-autotag"
    "nvim-web-devicons"
    "tokyonight"
    "bufdelete-nvim"
    "nvim-cmp"
    "cmp-nvim-lsp"
    "cmp-buffer"
    "cmp-vsnip"
    "cmp-path"
    "cmp-treesitter"
    "crates-nvim"
    "vim-vsnip"
    "nvim-code-action-menu"
    "trouble"
    "null-ls"
    "which-key"
    "indent-blankline"
    "nvim-cursorline"
    "sqls-nvim"
    "glow-nvim"
    "telescope"
    "rust-tools"
    "onedark"
    "catppuccin"
    "dracula"
    "minimap-vim"
    "dashboard-nvim"
    "alpha-nvim"
    "scrollbar-nvim"
    "codewindow-nvim"
    "nvim-notify"
    "cinnamon-nvim"
    "cheatsheet-nvim"
    "ccc"
    "cellular-automaton"
    "presence-nvim"
    "icon-picker-nvim"
    "dressing-nvim"
    "orgmode-nvim"
    "obsidian-nvim"
    "vim-markdown"
    "tabular"
    "toggleterm-nvim"
    "noice-nvim"
    "nui-nvim"
    "copilot-lua"
    "tabnine-nvim"
    "nvim-session-manager"
    "gesture-nvim"
    "comment-nvim"
    "kommentary"
    "mind-nvim"
    "fidget-nvim"
    "diffview-nvim"
    "todo-comments"
    "flutter-tools"
    "flutter-tools-patched"
    "hop-nvim"
    "leap-nvim"
    "modes-nvim"
    "vim-repeat"
    "smartcolumn"
    "project-nvim"
    "elixir-ls"
    "elixir-tools"
    "nvim-colorizer-lua"
    "vim-illuminate"
    "nvim-surround"
    "nvim-dap"
    "nvim-dap-ui"
    "nvim-navic"
    "nvim-navbuddy"
    "copilot-cmp"
    "lsp-lines"
  ];
  # You can either use the name of the plugin or a package.
  pluginType = with types;
    nullOr (
      either
      package
      (enum availablePlugins)
    );

  pluginsType = types.listOf pluginType;

  extraPluginType = with types;
    submodule {
      options = {
        package = mkOption {
          type = pluginType;
        };
        after = mkOption {
          type = listOf str;
          default = [];
          description = "Setup this plugin after the following ones.";
        };
        setup = mkOption {
          type = lines;
          default = "";
          description = "Lua code to run during setup.";
          example = "require('aerial').setup {}";
        };
      };
    };
in {
  inherit extraPluginType;

  pluginsOpt = {
    description,
    default ? [],
  }:
    mkOption {
      inherit description default;
      type = pluginsType;
    };
}
