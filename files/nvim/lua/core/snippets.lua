-- Custom code snippets for different purposes

-- Prevent LSP from overwriting treesitter color settings
-- https://github.com/NvChad/NvChad/issues/1907
vim.hl.priorities.semantic_tokens = 95 -- Or any number lower than 100, treesitter's priority level

-- Appearance of diagnostics
vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
		-- Add a custom format function to show error codes
		format = function(diagnostic)
			local code = diagnostic.code and string.format("[%s]", diagnostic.code) or ""
			return string.format("%s %s", code, diagnostic.message)
		end,
	},
	underline = false,
	update_in_insert = true,
	float = {
		source = true, -- Or "if_many"
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = "󰌵 ",
		},
	},
	-- Make diagnostic background transparent
	on_ready = function()
		vim.cmd("highlight DiagnosticVirtualText guibg=NONE")
	end,
})

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

-- Palette (uniquement 2 couleurs)
local p = require("core.palette")
local accent = p.accent
local accent2 = p.accent2
local white = "#FFFFFF"

-- a) Sélection & recherche
-- vim.api.nvim_set_hl(0, "Visual", { bg = accent, fg = white })
-- vim.api.nvim_set_hl(0, "VisualNOS", { bg = accent, fg = white })

vim.api.nvim_set_hl(0, "IncSearch", { bg = accent, fg = accent2, bold = true })
vim.api.nvim_set_hl(0, "Search", { bg = accent2, fg = accent })

-- b) Matching parenthesis
vim.api.nvim_set_hl(0, "MatchParen", { fg = accent, bold = true })

-- c) Bordures & Telescope
vim.api.nvim_set_hl(0, "FloatBorder", { fg = accent })
vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = accent })
vim.api.nvim_set_hl(0, "TelescopeSelection", { bg = accent, fg = accent2, bold = true })
vim.api.nvim_set_hl(0, "TelescopeMatching", { fg = accent2, bold = true })

-- d) Neo-tree
vim.api.nvim_set_hl(0, "NeoTreeExpander", { fg = accent })
vim.api.nvim_set_hl(0, "NeoTreeIndentMarker", { fg = accent2 })
vim.api.nvim_set_hl(0, "NeoTreeFileNameOpened", { fg = accent, bold = true })

-- e) Bufferline
vim.api.nvim_set_hl(0, "BufferLineIndicatorSelected", { fg = accent })
vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { fg = accent2, bold = true })
