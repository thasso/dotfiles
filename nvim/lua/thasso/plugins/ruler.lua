return {
	"lukas-reineke/virt-column.nvim",
	config = function()
		local vc = require("virt-column")
		vc.setup({
			char = "▕",
			virtcolumn = "+1,80,120",
		})
	end,
}
