-- vim basic config

local map = vim.api.nvim_set_keymap
local opt = {noremap = true, silent = true }

vim.cmd "colorscheme zephyr"

map('n', '<Leader>w', ':NvimTreeToggle<CR>', opt)

map("n", "gh", ":BufferLineCyclePrev<CR>", opt)
map("n", "gl", ":BufferLineCycleNext<CR>", opt)



