return {
  "akinsho/flutter-tools.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim", -- Optional: UI enhancements
  },
  config = function()
    require("flutter-tools").setup({
      widget_guides = { enabled = true },
      closing_tags = {
        highlight = "Comment", -- highlight for closing tag
        prefix = "// ", -- character to use for close tag e.g. > //
        enabled = true,
      },
      dev_log = {
        enabled = true,
        open_cmd = "tabedit", -- or "vsplit"
      },
    })
  end,
}
