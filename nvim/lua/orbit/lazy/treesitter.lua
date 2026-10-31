-- The `main` branch of nvim-treesitter needs the tree-sitter CLI and a C
-- compiler to build parsers (install.sh installs both).
return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").install({
            "bash", "c", "cpp", "css", "fish", "gdscript", "go", "html", "java",
            "javascript", "json", "kotlin", "lua", "markdown", "markdown_inline",
            "python", "rust", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
        })

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("orbit_treesitter", { clear = true }),
            callback = function(args)
                if pcall(vim.treesitter.start, args.buf) then
                    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end,
        })
    end,
}
