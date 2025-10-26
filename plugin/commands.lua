vim.api.nvim_create_user_command('Brainrot', function(opts)
  local args = vim.split(opts.args, ' ')
  local subcommand = args[1]
  local action = args[2]
  local brainrot = require('brainrot')

  if subcommand == 'phonk' then
    if action == 'toggle' then
      brainrot.toggle_phonk()
    elseif action == 'enable' then
      brainrot.enable_phonk()
    elseif action == 'disable' then
      brainrot.disable_phonk()
    elseif not action then
      brainrot.phonk()
    else
      vim.notify('Invalid action for phonk: ' .. action .. '\nUsage: :Brainrot phonk [toggle|enable|disable]', vim.log.levels.ERROR)
    end
  elseif subcommand == 'boom' then
    if action == 'toggle' then
      brainrot.toggle_boom()
    elseif action == 'enable' then
      brainrot.enable_boom()
    elseif action == 'disable' then
      brainrot.disable_boom()
    elseif not action then
      brainrot.boom()
    else
      vim.notify('Invalid action for boom: ' .. action .. '\nUsage: :Brainrot boom [toggle|enable|disable]', vim.log.levels.ERROR)
    end
  else
    vim.notify('Invalid subcommand: ' .. subcommand .. '\nUsage: :Brainrot <phonk|boom> [toggle|enable|disable]', vim.log.levels.ERROR)
  end
end, {
  nargs = '+',
  complete = function(_, line)
    local args = vim.split(line, ' ')
    if #args == 2 then
      return { 'phonk', 'boom' }
    elseif #args == 3 then
      return { 'toggle', 'enable', 'disable' }
    end
    return {}
  end
})
