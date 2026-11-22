-- folke/snacks.nvim: picker, explorer, terminal, dashboard, notifier, indent,
-- scope, bigfile, quickfile, statuscolumn, words, input, lazygit, zen, bufdelete.
return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            bigfile      = { enabled = true },
            quickfile    = { enabled = true },
            statuscolumn = { enabled = true },
            indent       = { enabled = true },
            scope        = { enabled = true },
            input        = { enabled = true },
            notifier     = { enabled = true, timeout = 3000 },
            scroll       = { enabled = true },
            words        = { enabled = true },
            explorer     = { enabled = true, replace_netrw = false },
            picker       = {
                enabled = true,
                sources = {
                    explorer = {
                        layout = { layout = { position = "left", width = 32 } },
                    },
                },
            },
            terminal     = { enabled = true },
            zen          = { enabled = true },
            dim          = { enabled = true },
            gitbrowse    = { enabled = true },
            dashboard    = {
                enabled = true,
                preset = {
                    keys = {
                        { icon = " ", key = "f", desc = "Buscar archivo", action = ":lua Snacks.dashboard.pick('files')" },
                        { icon = " ", key = "n", desc = "Nuevo archivo",  action = ":ene | startinsert" },
                        { icon = " ", key = "g", desc = "Grep texto",     action = ":lua Snacks.dashboard.pick('live_grep')" },
                        { icon = " ", key = "r", desc = "Recientes",      action = ":lua Snacks.dashboard.pick('oldfiles')" },
                        { icon = " ", key = "c", desc = "Config",         action = ":e $MYVIMRC" },
                        { icon = " ", key = "l", desc = "Lazy",           action = ":Lazy" },
                        { icon = " ", key = "q", desc = "Salir",          action = ":qa" },
                    },
                },
            },
        },
        keys = {
            -- Picker (reemplaza Telescope)
            { "<leader>ff", function() Snacks.picker.files() end,                 desc = "Buscar archivos" },
            { "<leader>fg", function() Snacks.picker.grep() end,                  desc = "Grep en el proyecto" },
            { "<leader>fb", function() Snacks.picker.buffers() end,               desc = "Buffers" },
            { "<leader>fh", function() Snacks.picker.help() end,                  desc = "Help tags" },
            { "<leader>fr", function() Snacks.picker.recent() end,                desc = "Recientes" },
            { "<leader>fk", function() Snacks.picker.keymaps() end,               desc = "Keymaps" },
            { "<leader>fd", function() Snacks.picker.diagnostics() end,           desc = "Diagnósticos" },
            { "<leader>fs", function() Snacks.picker.lsp_symbols() end,           desc = "Símbolos del archivo" },
            { "<leader>fS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Símbolos del workspace" },
            { "<leader>fw", function() Snacks.picker.grep_word() end,             mode = { "n", "x" }, desc = "Grep palabra/selección" },
            { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Buscar en config nvim" },
            { "<leader>/",  function() Snacks.picker.lines() end,                 desc = "Buscar en buffer" },

            -- Explorer (reemplaza nvim-tree)
            { "<F2>",       function() Snacks.explorer() end,                     desc = "Árbol de archivos" },
            { "<leader>e",  function() Snacks.explorer() end,                     desc = "Árbol de archivos" },

            -- Terminal (reemplaza toggleterm)
            { "<F4>",       function() Snacks.terminal() end,                     mode = { "n", "t" }, desc = "Terminal flotante" },
            { "<leader>tf", function() Snacks.terminal(nil, { win = { style = "float", border = "rounded" } }) end, desc = "Term flotante" },
            { "<leader>th", function() Snacks.terminal(nil, { win = { position = "bottom" } }) end, desc = "Term horizontal" },
            { "<leader>tv", function() Snacks.terminal(nil, { win = { position = "right" } }) end,  desc = "Term vertical" },

            -- Git / UI / Buffers
            { "<leader>gg", function() Snacks.lazygit() end,                      desc = "Lazygit" },
            { "<leader>gB", function() Snacks.gitbrowse() end,                    mode = { "n", "v" }, desc = "Abrir en GitHub/GitLab" },
            { "<leader>nh", function() Snacks.notifier.show_history() end,        desc = "Historial de notificaciones" },
            { "<leader>bD", function() Snacks.bufdelete() end,                    desc = "Cerrar buffer (smart)" },
            { "<leader>uz", function() Snacks.zen() end,                          desc = "Modo Zen" },
            { "<leader>uZ", function() Snacks.zen.zoom() end,                     desc = "Zoom ventana" },
        },
    },
}
