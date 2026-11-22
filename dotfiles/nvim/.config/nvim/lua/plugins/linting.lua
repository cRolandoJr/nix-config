return {
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPost", "BufNewFile", "BufWritePost" },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {
                python          = { "ruff" },
                javascript      = { "eslint_d" },
                javascriptreact = { "eslint_d" },
                typescript      = { "eslint_d" },
                typescriptreact = { "eslint_d" },
                go              = { "golangcilint" },
                sh              = { "shellcheck" },
                bash            = { "shellcheck" },
                markdown        = { "markdownlint" },
                yaml            = { "yamllint" },
                ["yaml.ansible"] = { "ansible_lint" },
                dockerfile      = { "hadolint" },
                terraform       = { "tflint" },
            }

            local grp = vim.api.nvim_create_augroup("rolando_lint", { clear = true })
            local function try_lint_available()
                local names = lint._resolve_linter_by_ft(vim.bo.filetype)
                names = vim.tbl_filter(function(name)
                    local linter = lint.linters[name]
                    if not linter then return false end
                    local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd
                    return type(cmd) == "string" and vim.fn.executable(cmd) == 1
                end, names)
                if #names > 0 then
                    lint.try_lint(names)
                end
            end

            vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
                group = grp,
                callback = try_lint_available,
            })
            -- El plugin carga en BufReadPost: ese evento ya pasó para el primer buffer, y el
            -- filetype todavía no está puesto. vim.schedule lo corre cuando ya lo está.
            vim.schedule(try_lint_available)
        end,
    },
}
