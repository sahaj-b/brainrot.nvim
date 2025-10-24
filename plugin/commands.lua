vim.api.nvim_create_user_command('Brainrot', function(opts)
  local subcommand = opts.args
  local brainrot = require('brainrot')

  if subcommand == 'phonk' then
    brainrot.phonk()
  elseif subcommand == 'boom' then
    brainrot.boom()
  else
    vim.notify('Invalid subcommand: ' .. subcommand .. '\nUsage: :Brainrot <phonk|boom>', vim.log.levels.ERROR)
  end
end, {
  nargs = 1,
  complete = function()
    return { 'phonk', 'boom' }
  end
})
