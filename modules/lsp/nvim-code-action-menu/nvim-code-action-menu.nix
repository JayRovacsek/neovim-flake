{lib, ...}:
with lib; {
  options.vim.lsp = {
    nvimCodeActionMenu = {
      enable = mkEnableOption "Enable nvim code action menu";

      show = {
        details = mkEnableOption "Show details" // {default = true;};
        diff = mkEnableOption "Show diff" // {default = true;};
        actionKind = mkEnableOption "Show action kind" // {default = true;};
      };

      mappings = {
        open = mkMappingOption "Open code action menu [nvim-code-action-menu]" "<leader>ca";
      };
    };
  };
}
