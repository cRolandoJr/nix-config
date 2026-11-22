-- Test runner integrado (Go, Python, Rust)
return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "fredrikaverpil/neotest-golang",
            "nvim-neotest/neotest-python",
        },
        keys = {
            { "<leader>tt", function() require("neotest").run.run() end,                     desc = "Test: correr más cercano" },
            { "<leader>tT", function() require("neotest").run.run(vim.fn.expand("%")) end,   desc = "Test: correr archivo" },
            { "<leader>ts", function() require("neotest").summary.toggle() end,              desc = "Test: toggle summary" },
            { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test: ver output" },
            { "<leader>tO", function() require("neotest").output_panel.toggle() end,         desc = "Test: toggle panel" },
            { "<leader>tS", function() require("neotest").run.stop() end,                    desc = "Test: detener" },
        },
        config = function()
            local adapters = {
                require("neotest-golang")({}),
                require("neotest-python")({}),
            }
            local ok_rust, rust_neotest = pcall(require, "rustaceanvim.neotest")
            if ok_rust then
                table.insert(adapters, rust_neotest)
            end
            require("neotest").setup({ adapters = adapters })
        end,
    },
}

