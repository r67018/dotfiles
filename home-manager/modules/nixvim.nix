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
      nvim-autopairs = {
       enable = true;
      };
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
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
        key = "<leader>e";
        action = "<cmd>NvimTreeToggle<CR>";
      }
      {
        mode = "n";
        key = "gl";
        action = ":lua vim.diagnostic.open_float()<CR>";
        options.desc = "Show hover information";
      }
    ];
    extraConfigLua = ''
      # Close nvim-tree when quitting nvim
      vim.api.nvim_create_autocmd({"QuitPre"}, {
        callback = function() vim.cmd("NvimTreeClose") end,
      })

      # Close nvim-tree automatically on focus lost
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

