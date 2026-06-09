return {
	"nvim-lualine/lualine.nvim",
	config = function()
		local p = require("core.palette")
		local accent = p.accent -- #3DA5FF
		local accent2 = p.accent2 -- #F6C299
		local white = "#FFFFFF"

		local theme = {
			normal = {
				a = { fg = white, bg = accent, gui = "bold" },
				b = { fg = white, bg = accent },
				c = { fg = white, bg = accent2 },
			},
			insert = {
				a = { fg = white, bg = accent, gui = "bold" },
				b = { fg = white, bg = accent },
				c = { fg = white, bg = accent2 },
			},
			visual = {
				a = { fg = white, bg = accent, gui = "bold" },
				b = { fg = white, bg = accent },
				c = { fg = white, bg = accent2 },
			},
			replace = {
				a = { fg = white, bg = accent, gui = "bold" },
				b = { fg = white, bg = accent },
				c = { fg = white, bg = accent2 },
			},
			command = {
				a = { fg = white, bg = accent, gui = "bold" },
				b = { fg = white, bg = accent },
				c = { fg = white, bg = accent2 },
			},
			inactive = {
				a = { fg = white, bg = accent2 },
				b = { fg = white, bg = accent2 },
				c = { fg = white, bg = accent2 },
			},
		}

		require("lualine").setup({
			options = {
				theme = theme, -- ✅ important
				icons_enabled = true,
				section_separators = { left = "", right = "" },
				component_separators = { left = "", right = "" },
				disabled_filetypes = { "alpha", "neo-tree" },
				always_divide_middle = true,
			},
			sections = {
				lualine_a = {
					{
						"mode",
						fmt = function(str)
							return " " .. str
						end,
						color = { fg = white, bg = accent, gui = "bold" },
					},
				},
				lualine_b = {
					{ "branch", color = { fg = white, bg = accent } },
				},
				lualine_c = {
					{ "filename", file_status = true, path = 0, color = { fg = white, bg = accent2 } },
				},
				lualine_x = {
					{
						"diagnostics",
						sources = { "nvim_diagnostic" },
						sections = { "error", "warn" },
						symbols = { error = " ", warn = " ", info = " ", hint = " " },
						colored = false,
						update_in_insert = false,
						always_visible = false,
						color = { fg = white, bg = accent },
					},
					{
						"diff",
						colored = false,
						symbols = { added = " ", modified = " ", removed = " " },
						color = { fg = white, bg = accent },
					},
					{ "encoding", color = { fg = white, bg = accent } },
					{ "filetype", color = { fg = white, bg = accent } },
				},
				lualine_y = {
					{ "location", color = { fg = white, bg = accent } },
				},
				lualine_z = {
					{ "progress", color = { fg = white, bg = accent } },
				},
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { { "filename", path = 1, color = { fg = white, bg = accent2 } } },
				lualine_x = { { "location", padding = 0, color = { fg = white, bg = accent } } },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			extensions = { "fugitive" },
		})

		-- Visuel (sélection)
		vim.api.nvim_set_hl(0, "Visual", { bg = accent, fg = white })
	end,
}
