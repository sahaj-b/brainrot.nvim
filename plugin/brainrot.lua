if vim.g.brainrot_loaded then
  return
end
vim.g.brainrot_loaded = true

require('brainrot').setup()
