-- Tokyo Night 配色配置
-- 高对比度现代风，函数方法清晰

return {
  name = "tokyonight",
  repo = "folke/tokyonight.nvim",
  setup = function()
    require("tokyonight").setup({
      style = "night", -- night, storm, moon, day
      light_style = "day",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true, bold = true },
        functions = { bold = true },
        variables = {},
        sidebars = "dark",
        floats = "dark",
      },
      on_highlights = function(hl, c)
        -- 函数和方法 - 亮蓝色加粗
        hl["@function"] = { fg = c.blue, bold = true }
        hl["@function.call"] = { fg = c.blue, bold = true }
        hl["@function.builtin"] = { fg = c.cyan, bold = true, italic = true }
        hl["@method"] = { fg = c.blue, bold = true }
        hl["@method.call"] = { fg = c.blue, bold = true }

        -- 类和类型 - 亮黄色加粗
        hl["@type"] = { fg = c.yellow, bold = true }
        hl["@type.builtin"] = { fg = c.orange, bold = true }
        hl["@type.definition"] = { fg = c.yellow, bold = true }
        hl["@class"] = { fg = c.yellow, bold = true }

        -- 变量和参数
        hl["@parameter"] = { fg = c.red, italic = true }
        hl["@variable"] = { fg = c.fg }
        hl["@variable.parameter"] = { fg = c.red, italic = true }

        -- 关键字
        hl["@keyword"] = { fg = c.magenta, bold = true }
        hl["@keyword.function"] = { fg = c.magenta, bold = true }
        hl["@keyword.return"] = { fg = c.magenta, bold = true }

        -- 字符串
        hl["@string"] = { fg = c.green }
        hl["@string.documentation"] = { fg = c.green, italic = true }

        -- 常量
        hl["@constant"] = { fg = c.orange, bold = true }
        hl["@constant.builtin"] = { fg = c.orange, bold = true }

        -- 属性/字段 - 使用亮青色区分
        hl["@property"] = { fg = c.cyan }
        hl["@field"] = { fg = c.cyan }

        -- 命名空间/模块
        hl["@namespace"] = { fg = c.yellow, italic = true }
        hl["@module"] = { fg = c.yellow, italic = true }

        -- 数字和布尔值
        hl["@number"] = { fg = c.magenta }
        hl["@boolean"] = { fg = c.magenta, bold = true }

        -- 运算符
        hl["@operator"] = { fg = c.blue }
      end,
      sidebars = { "qf", "vista_kind", "terminal", "packer" },
      dim_inactive = false,
      lualine_bold = true,
    })
  end,
}
