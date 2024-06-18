return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      svelte = { "eslint_d" },
      python = { "pylint" },
--      go = { "goimports" },


    }
    
    -- Define golangci-lint linter
    lint.linters.golangcilint = {
        cmd = 'golangci-lint', -- Specify the linting command
        args = {'run', '--out-format', 'json', '--issues-exit-code=1'},
        stream = 'stderr',
        ignore_exitcode = true, -- Golangci-lint returns non-zero exit code if any issues are found
        parser = function(output, _)
            local diagnostics = {}
            local json = vim.fn.json_decode(output) or {}
            for _, issue in ipairs(json.Issues or {}) do
            local severity = vim.lsp.protocol.DiagnosticSeverity.Warning
            if issue.Severity == "error" then
                severity = vim.lsp.protocol.DiagnosticSeverity.Error
            elseif issue.Severity == "info" then
                severity = vim.lsp.protocol.DiagnosticSeverity.Information
            elseif issue.Severity == "hint" then
                severity = vim.lsp.protocol.DiagnosticSeverity.Hint
            end
            table.insert(diagnostics, {
                lnum = issue.Pos.Line - 1,
                col = issue.Pos.Column - 1,
                end_lnum = issue.Pos.EndLine - 1,
                end_col = issue.Pos.EndColumn - 1,
                severity = severity,
                message = issue.Text,
                source = 'golangcilint',
            })
        end
        return diagnostics
        end
}   
    local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
    vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function()
        require('go.format').goimports()
    end,
    group = format_sync_grp,
    })

    
-- Run linting on save

vim.api.nvim_exec([[
  augroup NvimLint
    autocmd!
    autocmd BufWritePost *.go lua require('lint').try_lint()
  augroup END
]], false)

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })
    
    vim.keymap.set("n", "<leader>l", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })
  end,
}


