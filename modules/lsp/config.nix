{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with builtins; let
  cfg = config.vim.lsp;
  usingNvimCmp = config.vim.autocomplete.enable && config.vim.autocomplete.type == "nvim-cmp";
in {
  config = mkIf cfg.enable {
    vim.startPlugins = optional usingNvimCmp "cmp-nvim-lsp";

    vim.autocomplete.sources = {"nvim_lsp" = "[LSP]";};

    vim.luaConfigRC.lsp-setup = ''
      vim.g.formatsave = ${boolToString cfg.formatOnSave};

      local attach_keymaps = function(client, bufnr)
        local opts = { noremap=true, silent=true }

        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lgD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lgd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lgt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lgn', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lgp', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)

        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lwa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lwr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lwl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)

        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lh', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ls', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ln', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
      end

      -- Enable formatting
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

      format_callback = function(client, bufnr)
        if vim.g.formatsave then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              ${
        if config.vim.lsp.null-ls.enable
        then ''
          local function is_null_ls_formatting_enabled(bufnr)
              local file_type = vim.api.nvim_buf_get_option(bufnr, "filetype")
              local generators = require("null-ls.generators").get_available(
                  file_type,
                  require("null-ls.methods").internal.FORMATTING
              )
              return #generators > 0
          end

          if is_null_ls_formatting_enabled(bufnr) then
             vim.lsp.buf.format({
                bufnr = bufnr,
                filter = function(client)
                  return client.name == "null-ls"
                end
              })
          else
              vim.lsp.buf.format({
                bufnr = bufnr,
              })
          end
        ''
        else "
              vim.lsp.buf.format({
                bufnr = bufnr,
              })
        "
      }
            end,
          })
        end
      end

      ${optionalString (config.vim.ui.breadcrumbs.enable) ''local navic = require("nvim-navic")''}
      default_on_attach = function(client, bufnr)
        attach_keymaps(client, bufnr)
        format_callback(client, bufnr)
        ${optionalString (config.vim.ui.breadcrumbs.enable) ''
        -- let navic attach to buffers
        if client.server_capabilities.documentSymbolProvider then
          navic.attach(client, bufnr)
        end
      ''}
      end

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      ${optionalString usingNvimCmp "capabilities = require('cmp_nvim_lsp').default_capabilities()"}
    '';
  };
}
