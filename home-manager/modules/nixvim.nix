{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    colorscheme = "iceberg";
    globals = {
      mapleader = " ";
    };
    opts = {
      number = true;
      relativenumber = true;
      autoindent = true;
      smartindent = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
    };
    plugins = {
      nvim-tree = {
        enable = true;
        settings = {
          actions = {
            open_file = {
              quit_on_open = true; # Close the explorer on file open
            };
          };
        };
      };
      flash = {
        enable = true;
      };
      treesitter = {
        enable = true;
        settings = {
          highlight = {
            enable = true;
          };
          indent = {
            enable = true;
          };
          ensure_installed = [
            "bash"
            "c"
            "c_sharp"
            "cpp"
            "css"
            "html"
            "javascript"
            "json"
            "lua"
            "markdown"
            "markdown_inline"
            "nix"
            "python"
            "rust"
            "toml"
            "typescript"
            "vim"
            "vimdoc"
            "yaml"
          ];
        };
      };
      nvim-autopairs = {
       enable = true;
      };
      airline = {
        enable = true;
        settings = {
          theme = "iceberg";
        };
      };
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
          bashls.enable = true;
          clangd.enable = true;
          cssls.enable = true;
          html.enable = true;
          jsonls.enable = true;
          lua_ls.enable = true;
          pyright.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };
          taplo.enable = true;
          ts_ls.enable = true;
          yamlls.enable = true;
        };
        keymaps = {
          lspBuf = {
            gd = "definition";
            gr = "references";
            K = "hover";
            gi = "implementation";
            gt = "type_definition";
          };
        };
      };
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
        };
      };
      inc-rename = {
        enable = true;
      };
      toggleterm = {
        enable = true;
        settings = {
          direction = "float";
          float_opts = {
            border = "curved";
          };
        };
      };
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
        };
      };
      which-key = {
        enable = true;
      };
      luasnip = {
        enable = true;
      };
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "buffer"; }
            { name = "luasnip"; }
          ];
          mapping = {
            "<C-n>" = "cmp.mapping.select_next_item()";
            "<C-p>" = "cmp.mapping.select_prev_item()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<C-S-Space>" = "cmp.mapping.complete()";
          };
          snippet = {
             expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          };
        };
      };

      # Declare plugins below explicitly because they are depended on by other plugins
      # by nvim-tree
      web-devicons = {
        enable = true;
      };
    };
    extraPlugins = with pkgs; [
      vimPlugins.iceberg-vim
    ];
    keymaps = [
      {
        mode = "n";
        key = "<Esc><Esc>";
        action = "<cmd>noh<CR>";
        options.desc = "Clear search highlights";
      }
      {
        key = "<leader>e";
        action = "<cmd>NvimTreeToggle<CR>";
      }
      {
        mode = "n";
        key = "gl";
        action = ":lua vim.diagnostic.open_float()<CR>";
        options.desc = "Show hover information";
      }
      {
        mode = "n";
        key = "<leader>rn";
        action = ":IncRename ";
        options.desc = "Incremental rename";
      }
      {
        mode = [ "n" "t" ];
        key = "<leader>t";
        action = "<cmd>ToggleTerm direction=float<CR>";
        options.desc = "Toggle floating terminal";
      }
      # flash.nvim
      {
        mode = [ "n" "x" "o" ];
        key = "s";
        action = "<cmd>lua require('flash').jump()<CR>";
        options.desc = "Flash";
      }
      {
        mode = [ "n" "x" "o" ];
        key = "S";
        action = "<cmd>lua require('flash').treesitter()<CR>";
        options.desc = "Flash Treesitter";
      }
    ];
    extraConfigLua = ''
      -- Enable transparency
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })

      -- Flash to line
      local function flash_to_line()
        require("flash").jump({
          search = { mode = "search", max_length = 0 },
          label = { after = { 0, 0 } },
          pattern = "^\\s*\\zs\\S\\|^\\s*$",
        })
      end

      vim.keymap.set({'n', 'x', 'o'}, '<leader>l', flash_to_line, { desc = "Flash to line" })

      -- Close nvim-tree when quitting nvim
      vim.api.nvim_create_autocmd({"QuitPre"}, {
        callback = function() vim.cmd("NvimTreeClose") end,
      })

      -- Close nvim-tree automatically on focus lost
      vim.api.nvim_create_autocmd("WinEnter", {
        callback = function()
          local nvim_tree_utils = require("nvim-tree.utils")
          if nvim_tree_utils.is_nvim_tree_buf(vim.api.nvim_get_current_buf()) then
            -- Do nothing when focusing nvim-tree buffer
            return
          end

          for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if nvim_tree_utils.is_nvim_tree_buf(vim.api.nvim_win_get_buf(winid)) then
              vim.api.nvim_win_close(winid, true)
              return
            end
          end
        end,
      })
    '';
  };
}

