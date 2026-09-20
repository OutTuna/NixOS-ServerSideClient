# Neovim config, split out of configuration.nix just to keep that file readable.
# Plugins are managed by lazy.nvim, but every plugin still comes from the Nix
# store (pkgs.vimPlugins.*) via `dir = ...`, so nothing needs internet access -
# lazy.nvim just gives you real lazy-loading (events/filetypes/keys/commands)
# and the usual :Lazy UI on top of a fully reproducible plugin set.

{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    configure = {
      packages.myPlugins = {
        start = [ pkgs.vimPlugins.lazy-nvim ];
      };

      customRC = ''
        syntax on
        set t_u7=
        set completeopt=menu,menuone,noselect
        set number
        set relativenumber
        set signcolumn=yes

        lua << EOF
        vim.g.mapleader = " "
        vim.g.maplocalleader = " "

        vim.opt.termguicolors = true
        vim.o.background = "dark"

        ------------------------------------------------------------------
        -- lazy.nvim setup
        ------------------------------------------------------------------
        require("lazy").setup({
          spec = {

            -- theme ------------------------------------------------------
            {
              "gruvbox-nvim",
              dir = "${pkgs.vimPlugins.gruvbox-nvim}",
              lazy = false,
              priority = 1000,
              config = function()
                require("gruvbox").setup({ transparent_mode = false })
                vim.cmd.colorscheme("gruvbox")
              end,
            },

            -- statusline ---------------------------------------------------
            {
              "lualine-nvim",
              dir = "${pkgs.vimPlugins.lualine-nvim}",
              event = "VeryLazy",
              config = function()
                require("lualine").setup({
                  options = {
                    theme = "gruvbox",
                    icons_enabled = false,
                    component_separators = "|",
                    section_separators = "",
                  },
                })
              end,
            },

            -- editing QoL --------------------------------------------------
            {
              "nvim-autopairs",
              dir = "${pkgs.vimPlugins.nvim-autopairs}",
              event = "InsertEnter",
              config = function()
                require("nvim-autopairs").setup({})
              end,
            },
            {
              "comment-nvim",
              dir = "${pkgs.vimPlugins.comment-nvim}",
              keys = { "gc", "gcc", "gb", "gbc" },
              config = function()
                require("Comment").setup()
              end,
            },
            {
              "gitsigns-nvim",
              dir = "${pkgs.vimPlugins.gitsigns-nvim}",
              event = { "BufReadPre", "BufNewFile" },
              config = function()
                require("gitsigns").setup({
                  on_attach = function(bufnr)
                    local gs = require("gitsigns")
                    local map = function(mode, l, r, desc)
                      vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
                    end
                    map("n", "]c", gs.next_hunk, "Next git hunk")
                    map("n", "[c", gs.prev_hunk, "Previous git hunk")
                    map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
                    map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
                    map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
                    map("n", "<leader>hb", gs.blame_line, "Blame line")
                  end,
                })
              end,
            },
            {
              "which-key-nvim",
              dir = "${pkgs.vimPlugins.which-key-nvim}",
              event = "VeryLazy",
              config = function()
                require("which-key").setup({})
              end,
            },

            -- fuzzy finder ---------------------------------------------------
            {
              "plenary-nvim",
              dir = "${pkgs.vimPlugins.plenary-nvim}",
              lazy = true,
            },
            {
              "telescope-nvim",
              dir = "${pkgs.vimPlugins.telescope-nvim}",
              dependencies = { "plenary-nvim" },
              cmd = "Telescope",
              keys = {
                "<leader>ff",
                "<leader>fg",
                "<leader>fb",
              },
              config = function()
                local builtin = require("telescope.builtin")
                vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
                vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
                vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
              end,
            },

            -- treesitter -----------------------------------------------------
            {
              "nvim-treesitter",
              dir = "${pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
                p.dockerfile
                p.yaml
                p.bash
                p.lua
                p.nix
                p.markdown
                p.markdown_inline
                p.json
              ])}",
              event = { "BufReadPost", "BufNewFile" },
              config = function()

                -- nvim-treesitter's 2025 rewrite dropped the old

                -- require("nvim-treesitter.configs").setup() API. Grammars

                -- are pre-built by Nix, so all that's left to do is attach

                -- native treesitter highlighting per filetype.

                vim.api.nvim_create_autocmd("FileType", {

                  pattern = { "lua", "nix", "bash", "markdown", "json" },

                  callback = function(args)

                    pcall(vim.treesitter.start, args.buf)

                  end,

                })
              end,

            },

            -- completion / snippets -------------------------------------------
            { "luasnip", dir = "${pkgs.vimPlugins.luasnip}", lazy = true },
            { "cmp_luasnip", dir = "${pkgs.vimPlugins.cmp_luasnip}", lazy = true },
            { "cmp-nvim-lsp", dir = "${pkgs.vimPlugins.cmp-nvim-lsp}", lazy = true },
            { "cmp-buffer", dir = "${pkgs.vimPlugins.cmp-buffer}", lazy = true },
            { "cmp-path", dir = "${pkgs.vimPlugins.cmp-path}", lazy = true },
            {
              "nvim-cmp",
              dir = "${pkgs.vimPlugins.nvim-cmp}",
              event = "InsertEnter",
              dependencies = {
                "luasnip", "cmp_luasnip", "cmp-nvim-lsp", "cmp-buffer", "cmp-path",
              },
              config = function()
                local cmp = require("cmp")
                local luasnip = require("luasnip")
                cmp.setup({
                  snippet = {
                    expand = function(args) luasnip.lsp_expand(args.body) end,
                  },
                  mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                      if cmp.visible() then
                        cmp.select_next_item()
                      elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                      else
                        fallback()
                      end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                      if cmp.visible() then
                        cmp.select_prev_item()
                      elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                      else
                        fallback()
                      end
                    end, { "i", "s" }),
                  }),
                  sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path" },
                  }),
                })
              end,
            },

            -- LSP --------------------------------------------------------------
            {
              "nvim-lspconfig",
              dir = "${pkgs.vimPlugins.nvim-lspconfig}",
              event = { "BufReadPre", "BufNewFile" },
            },
          },

          -- everything is sourced from the Nix store, so never let lazy.nvim
          -- try to install/update anything itself
          install = { missing = false },
          checker = { enabled = false },
          change_detection = { notify = false },
        })

        ------------------------------------------------------------------
        -- LSP: shared on_attach + keymaps
        ------------------------------------------------------------------
        local function on_attach(_, bufnr)
          local map = function(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
          end
          map("n", "K", vim.lsp.buf.hover, "LSP Hover documentation")
          map("n", "gd", vim.lsp.buf.definition, "Goto definition")
          map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
          map("n", "gr", vim.lsp.buf.references, "Goto references")
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>e", vim.diagnostic.open_float, "Show line diagnostics")
          map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
          map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
          map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format buffer")
        end

        vim.api.nvim_create_user_command("LspInfo", function()
          local clients = vim.lsp.get_clients and vim.lsp.get_clients() or vim.lsp.get_active_clients()
          if #clients == 0 then
            print("No active LSP clients attached to buffer.")
          else
            for _, client in ipairs(clients) do
              print(string.format("Client: %s (id: %d)", client.name, client.id))
            end
          end
        end, {})

        ------------------------------------------------------------------
        -- LSP: dockerfile + docker-compose (yaml) servers
        ------------------------------------------------------------------
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "dockerfile",
          callback = function(args)
            pcall(vim.treesitter.start, args.buf, "dockerfile")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            vim.lsp.start({
              name = "dockerls",
              cmd = { "docker-langserver", "--stdio" },
              capabilities = capabilities,
              on_attach = on_attach,
              root_dir = vim.fs.root(args.buf, { "Dockerfile", ".git" }) or vim.fn.getcwd(),
            })
          end,
        })

        vim.api.nvim_create_autocmd("FileType", {
          pattern = "yaml",
          callback = function(args)
            pcall(vim.treesitter.start, args.buf, "yaml")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            vim.lsp.start({
              name = "docker_compose",
              cmd = { "docker-compose-langserver", "--stdio" },
              capabilities = capabilities,
              on_attach = on_attach,
              root_dir = vim.fs.root(args.buf, { "docker-compose.yml", "docker-compose.yaml", ".git" }) or vim.fn.getcwd(),
            })
          end,
        })
        EOF
      '';
    };
  };
}
