-- Catppuccin 配色配置
-- 柔和奶油风，语义高亮出色

return {
  name = "catppuccin",
  repo = "catppuccin/nvim",
  setup = function()
    require("catppuccin").setup({
      flavour = "mocha", -- mocha, macchiato, frappe, latte
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = false,
      },
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = { "bold" },
        keywords = { "italic" },
        strings = {},
        variables = {},
        numbers = { "bold" },
        booleans = { "bold" },
        properties = {},
        types = { "bold" },
        operators = {},
      },
      highlight_overrides = {
        mocha = function(colors)
          return {
            -- 函数和方法更加突出
            ["@function"] = { fg = colors.blue, style = { "bold" } },
            ["@function.call"] = { fg = colors.blue, style = { "bold" } },
            ["@function.builtin"] = { fg = colors.blue, style = { "bold", "italic" } },
            ["@method"] = { fg = colors.blue, style = { "bold" } },
            ["@method.call"] = { fg = colors.blue, style = { "bold" } },
            -- 类和类型
            ["@type"] = { fg = colors.yellow, style = { "bold" } },
            ["@type.builtin"] = { fg = colors.yellow, style = { "bold" } },
            ["@type.definition"] = { fg = colors.yellow, style = { "bold" } },
            ["@class"] = { fg = colors.yellow, style = { "bold" } },
            -- 变量和参数
            ["@parameter"] = { fg = colors.maroon, style = { "italic" } },
            ["@variable"] = { fg = colors.text },
            ["@variable.parameter"] = { fg = colors.maroon, style = { "italic" } },
            -- 关键字
            ["@keyword"] = { fg = colors.mauve, style = { "bold" } },
            ["@keyword.function"] = { fg = colors.mauve, style = { "bold" } },
            ["@keyword.return"] = { fg = colors.mauve, style = { "bold" } },
            -- 字符串
            ["@string"] = { fg = colors.green },
            ["@string.documentation"] = { fg = colors.green, style = { "italic" } },
            -- 常量
            ["@constant"] = { fg = colors.peach, style = { "bold" } },
            ["@constant.builtin"] = { fg = colors.peach, style = { "bold" } },
            -- 属性/字段
            ["@property"] = { fg = colors.lavender },
            ["@field"] = { fg = colors.lavender },
            -- 命名空间/模块
            ["@namespace"] = { fg = colors.flamingo, style = { "italic" } },
            ["@module"] = { fg = colors.flamingo, style = { "italic" } },
          }
        end,
      },
      integrations = {
        treesitter = true,
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
          },
        },
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        bufferline = true,
        lualine = true,
        indent_blankline = { enabled = true },
      },
    })
  end,
}
