return {
	"nvim-lualine/lualine.nvim",
	config = function()
		local accent = "#4a03fc" -- Bleu-violet demandé
		local accent2 = "#EB0560"
		local text_color = "#FFFFFF" -- Texte blanc
		local nord = require("lualine.themes.nord")

		-- On copie le thème nord pour le modifier
		local theme = vim.deepcopy(nord)

		-- Fonction utilitaire : applique ton style à tous les modes
		local function set_mode(tbl)
			tbl.a = { fg = text_color, bg = accent, gui = "bold" } -- bloc mode
			tbl.b = { fg = text_color, bg = accent } -- partie à côté (branche, etc.)
			tbl.c = { fg = text_color, bg = accent2 } -- nom de fichier
			return tbl
		end

		theme.normal = set_mode(theme.normal)
		theme.insert = set_mode(theme.insert)
		theme.visual = set_mode(theme.visual)
		theme.replace = set_mode(theme.replace)
		theme.command = set_mode(theme.command)

		-- Mode inactif (fichiers non focus)
		theme.inactive = {
			a = { fg = "#CCCCCC", bg = "#2E3440", gui = "bold" },
			b = { fg = "#CCCCCC", bg = "#2E3440" },
			c = { fg = "#CCCCCC", bg = "#2E3440" },
		}

		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = theme,
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
					},
				},
				lualine_b = { "branch" },
				lualine_c = {
					{ "filename", file_status = true, path = 0 },
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
					},
					{ "diff", colored = false, symbols = { added = " ", modified = " ", removed = " " } },
					"encoding",
					"filetype",
				},
				lualine_y = { "location" },
				lualine_z = { "progress" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { { "filename", path = 1 } },
				lualine_x = { { "location", padding = 0 } },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			extensions = { "fugitive" },
		})

		-- 🔹 Couleur du surlignage visuel
		vim.api.nvim_set_hl(0, "Visual", { bg = "#00ff11", fg = text_color })
	end,
}
