-- Nightfox 配色配置
-- 温暖舒适风，专为 Treesitter 设计

return {
  name = "nightfox",
  repo = "EdenEast/nightfox.nvim",
  setup = function()
    require("nightfox").setup({
      options = {
        transparent = false,
        terminal_colors = true,
        dim_inactive = false,
        styles = {
          comments = "italic",
          conditionals = "italic",
          constants = "bold",
          functions = "bold",
          keywords = "bold",
          numbers = "bold",
          operators = "bold",
          strings = "NONE",
          types = "bold",
          variables = "NONE",
        },
      },
    })

    -- 通过 highlight 命令增强语义高亮
    local highlights = {
      -- 函数和方法 - 更亮的青色
      ["@function"] = { fg = "#7ee787", bold = true },
      ["@function.call"] = { fg = "#7ee787", bold = true },
      ["@function.builtin"] = { fg = "#4ec9b0", bold = true, italic = true },
      ["@method"] = { fg = "#7ee787", bold = true },
      ["@method.call"] = { fg = "#7ee787", bold = true },
      -- 类和类型 - 亮橙色
      ["@type"] = { fg = "#ffbb7c", bold = true },
      ["@type.builtin"] = { fg = "#ffd166", bold = true },
      ["@type.definition"] = { fg = "#ffbb7c", bold = true },
      -- 参数 - 粉紫色
      ["@parameter"] = { fg = "#ff9ecd", italic = true },
      ["@variable.parameter"] = { fg = "#ff9ecd", italic = true },
      -- 属性/字段 - 浅绿色
      ["@property"] = { fg = "#b5cea8" },
      ["@field"] = { fg = "#b5cea8" },
      -- 关键字 - 亮紫色
      ["@keyword"] = { fg = "#c586c0", bold = true },
      ["@keyword.function"] = { fg = "#c586c0", bold = true },
      ["@keyword.return"] = { fg = "#c586c0", bold = true },
      -- 常量
      ["@constant"] = { fg = "#ff9d6b", bold = true },
      ["@constant.builtin"] = { fg = "#ff9d6b", bold = true },
    }

    for group, opts in pairs(highlights) do
      vim.api.nvim_set_hl(0, group, opts)
    end
  end,
}
