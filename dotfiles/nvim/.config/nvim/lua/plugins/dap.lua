-- Debugging (DAP) sin Mason: usa binarios del sistema/proyecto (dlv, debugpy, codelldb)
return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            {
                "igorlfs/nvim-dap-view",
                opts = {
                    winbar = { controls = { enabled = true } },
                },
            },
        },
        keys = {
            { "<leader>db", function() require("dap").toggle_breakpoint() end,                                 desc = "DAP: toggle breakpoint" },
            { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condición: ")) end,         desc = "DAP: breakpoint condicional" },
            { "<leader>dc", function() require("dap").continue() end,                                          desc = "DAP: continue / start" },
            { "<leader>di", function() require("dap").step_into() end,                                         desc = "DAP: step into" },
            { "<leader>do", function() require("dap").step_over() end,                                         desc = "DAP: step over" },
            { "<leader>dO", function() require("dap").step_out() end,                                          desc = "DAP: step out" },
            { "<leader>dt", function() require("dap").terminate() end,                                         desc = "DAP: terminate" },
            { "<leader>dv", "<cmd>DapViewToggle<cr>",                                                          desc = "DAP: toggle view" },
        },
        config = function()
            local dap = require("dap")
            local dv = require("dap-view")

            dap.listeners.before.attach["dap-view-config"] = function() dv.open() end
            dap.listeners.before.launch["dap-view-config"] = function() dv.open() end
            dap.listeners.before.event_terminated["dap-view-config"] = function() dv.close() end
            dap.listeners.before.event_exited["dap-view-config"] = function() dv.close() end

            vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DiagnosticError" })
            vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
            vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })

            -- Go (delve)
            if vim.fn.executable("dlv") == 1 then
                dap.adapters.go = {
                    type = "server",
                    port = "${port}",
                    executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } },
                }
                dap.configurations.go = {
                    { type = "go", name = "Debug",         request = "launch", program = "${file}" },
                    { type = "go", name = "Debug package", request = "launch", program = "${fileDirname}" },
                    { type = "go", name = "Debug test",    request = "launch", mode = "test", program = "${fileDirname}" },
                }
            end

            -- Python (debugpy)
            dap.adapters.python = function(cb, config)
                if config.request == "attach" then
                    local port = (config.connect or config).port
                    local host = (config.connect or config).host or "127.0.0.1"
                    cb({ type = "server", port = assert(port), host = host })
                else
                    cb({
                        type = "executable",
                        command = vim.fn.exepath("python3"),
                        args = { "-m", "debugpy.adapter" },
                    })
                end
            end
            dap.configurations.python = {
                { type = "python", request = "launch", name = "Launch file", program = "${file}" },
            }
        end,
    },
}

