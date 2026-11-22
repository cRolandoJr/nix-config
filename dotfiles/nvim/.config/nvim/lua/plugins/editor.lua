return {
    -- which-key: ayuda contextual de keymaps
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "modern",
            delay = 300,
            spec = {
                { "<leader>b", group = "Buffers" },
                { "<leader>c", group = "Código / LSP" },
                { "<leader>d", group = "Debug (DAP)" },
                { "<leader>f", group = "Buscar (Picker)" },
                { "<leader>g", group = "Git" },
                { "<leader>h", group = "Git Hunks" },
                { "<leader>n", group = "Notificaciones" },
                { "<leader>r", group = "HTTP / Rename" },
                { "<leader>s", group = "Search & Replace" },
                { "<leader>t", group = "Tests / Terminal" },
                { "<leader>u", group = "UI / Toggles" },
                { "<leader>x", group = "Diagnósticos (Trouble)" },
            },
        },
    },

    -- flash.nvim: saltos rápidos (reemplazo moderno de easymotion/leap)
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {},
        keys = {
            { "s", function() require("flash").jump() end,       mode = { "n", "x", "o" }, desc = "Flash" },
            { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter" },
            { "r", function() require("flash").remote() end,     mode = "o",               desc = "Remote flash" },
        },
    },

    -- Surround: ysiw"  cs'"  ds"
    {
        "kylechui/nvim-surround",
        event = "VeryLazy",
        opts = {},
    },

    -- Pares automáticos
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = { check_ts = true },
    },

    -- TODO / FIXME / HACK highlights
    {
        "folke/todo-comments.nvim",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {},
        keys = {
            { "]t",         function() require("todo-comments").jump_next() end, desc = "TODO siguiente" },
            { "[t",         function() require("todo-comments").jump_prev() end, desc = "TODO anterior" },
            { "<leader>ft", function() Snacks.picker.todo_comments() end,        desc = "Buscar TODOs" },
        },
    },

    -- oil.nvim: editás el filesystem como un buffer
    {
        "stevearc/oil.nvim",
        cmd = "Oil",
        keys = {
            { "-", "<cmd>Oil<cr>", desc = "Oil (filesystem buffer)" },
        },
        opts = {
            view_options = { show_hidden = true },
            keymaps = {
                ["q"] = "actions.close",
            },
        },
    },

    -- Search & Replace en todo el proyecto (ripgrep interactivo)
    {
        "MagicDuck/grug-far.nvim",
        cmd = "GrugFar",
        keys = {
            {
                "<leader>sr",
                function()
                    local grug = require("grug-far")
                    local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
                    grug.open({
                        transient = true,
                        prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil },
                    })
                end,
                mode = { "n", "v" },
                desc = "Search & Replace (GrugFar)",
            },
            {
                "<leader>sR",
                function() require("grug-far").open({ transient = true }) end,
                desc = "Search & Replace (todo el repo)",
            },
        },
        opts = { headerMaxWidth = 80 },
    },

    -- Textobjects inteligentes (vaq, cib, daf, etc.)
    {
        "echasnovski/mini.ai",
        event = "VeryLazy",
        opts = { n_lines = 500 },
    },
}
