vim.api.nvim_create_user_command('Phonk', function()
  require('brainrot').phonk()
end, {})

vim.api.nvim_create_user_command('Boom', function()
  require('brainrot').boom()
end, {})
