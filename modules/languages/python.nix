{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with builtins; let
  cfg = config.vim.languages.python;

  defaultServer = "pyright";
  servers = {
    pyright = {
      package = pkgs.nodePackages.pyright;
      lspConfig = ''
        lspconfig.pyright.setup{
          capabilities = capabilities;
          on_attach = default_on_attach;
          cmd = {"${cfg.lsp.package}/bin/pyright-langserver", "--stdio"}
        }
      '';
    };
  };

  defaultFormat = "black";
  formats = {
    black = {
      package = pkgs.black;
      nullConfig = ''
        table.insert(
          ls_sources,
          null_ls.builtins.formatting.black.with({
            command = "${cfg.format.package}/bin/black",
          })
        )
      '';
    };
  };

  defaultDebugger = "debugpy";
  debuggers = {
    debugpy = {
      # idk if this is the best way to install/run debugpy
      package = pkgs.python3.withPackages (ps: with ps; [debugpy]);
      dapConfig = ''
        dap.adapters.python = function(cb, config)
          if config.request == 'attach' then
            ---@diagnostic disable-next-line: undefined-field
            local port = (config.connect or config).port
            ---@diagnostic disable-next-line: undefined-field
            local host = (config.connect or config).host or '127.0.0.1'
            cb({
              type = 'server',
              port = assert(port, '`connect.port` is required for a python `attach` configuration'),
              host = host,
              options = {
                source_filetype = 'python',
              },
            })
          else
            cb({
              type = 'executable',
              command = '${getExe cfg.dap.package}',
              args = { '-m', 'debugpy.adapter' },
              options = {
                source_filetype = 'python',
              },
            })
          end
        end

        dap.configurations.python = {
          {
            -- The first three options are required by nvim-dap
            type = 'python'; -- the type here established the link to the adapter definition: `dap.adapters.python`
            request = 'launch';
            name = "Launch file";

            -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

            program = "''${file}"; -- This configuration will launch the current file if used.
            pythonPath = function()
              -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
              -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
              -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
              local cwd = vim.fn.getcwd()
              if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                return cwd .. '/venv/bin/python'
              elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                return cwd .. '/.venv/bin/python'
              elseif vim.fn.executable("python") == 1 then
                return vim.fn.exepath("python")
              else -- WARNING cfg.dap.package probably has NO libraries other than builtins and debugpy
                return '${getExe cfg.dap.package}'
              end
            end;
          },
        }
      '';
    };
  };
in {
  options.vim.languages.python = {
    enable = mkEnableOption "Python language support";

    treesitter = {
      enable = mkEnableOption "Enable Python treesitter" // {default = config.vim.languages.enableTreesitter;};
      package = mkOption {
        description = "Python treesitter grammar to use";
        type = types.package;
        default = pkgs.vimPlugins.nvim-treesitter.builtGrammars.python;
      };
    };

    lsp = {
      enable = mkEnableOption "Enable Python LSP support" // {default = config.vim.languages.enableLSP;};

      server = mkOption {
        description = "Python LSP server to use";
        type = with types; enum (attrNames servers);
        default = defaultServer;
      };

      package = mkOption {
        description = "python LSP server package";
        type = types.package;
        default = servers.${cfg.lsp.server}.package;
      };
    };

    format = {
      enable = mkEnableOption "Enable Python formatting" // {default = config.vim.languages.enableFormat;};

      type = mkOption {
        description = "Python formatter to use";
        type = with types; enum (attrNames formats);
        default = defaultFormat;
      };

      package = mkOption {
        description = "Python formatter package";
        type = types.package;
        default = formats.${cfg.format.type}.package;
      };
    };

    # TODO this implementation is very bare bones, I don't know enough python to implement everything
    dap = {
      enable = mkOption {
        description = "Enable Python Debug Adapter";
        type = types.bool;
        default = config.vim.languages.enableDAP;
      };
      debugger = mkOption {
        description = "Python debugger to use";
        type = with types; enum (attrNames debuggers);
        default = defaultDebugger;
      };
      package = mkOption {
        description = ''
          Python debugger package.
          This is a python package with debugpy installed, see https://nixos.wiki/wiki/Python#Install_Python_Packages.
        '';
        example = literalExpression "with pkgs; python39.withPackages (ps: with ps; [debugpy])";
        type = types.package;
        default = debuggers.${cfg.dap.debugger}.package;
      };
    };
  };
  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.treesitter.enable {
      vim.treesitter.enable = true;
      vim.treesitter.grammars = [cfg.treesitter.package];
    })

    (mkIf cfg.lsp.enable {
      vim.lsp.lspconfig.enable = true;
      vim.lsp.lspconfig.sources.python-lsp = servers.${cfg.lsp.server}.lspConfig;
    })

    (mkIf cfg.format.enable {
      vim.lsp.null-ls.enable = true;
      vim.lsp.null-ls.sources.python-format = formats.${cfg.format.type}.nullConfig;
    })

    (mkIf cfg.dap.enable {
      vim.debugger.nvim-dap.enable = true;
      vim.debugger.nvim-dap.sources.python-debugger = debuggers.${cfg.dap.debugger}.dapConfig;
    })
  ]);
}
