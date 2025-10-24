local M = {}

local config = {
  phonk_time = 2.5,
  disable_phonk = false,
  sound_enabled = true,
  image_enabled = true,
}

local function get_plugin_path()
  return vim.fn.stdpath('data') .. '/lazy/brainrot.nvim'
end

local function playBoom()
  if not config.sound_enabled then return end
  local media_path = get_plugin_path() .. '/boom.ogg'
  vim.system({ 'paplay', media_path, '--volume=35536' }, { detach = true })
end

local function playRandomPhonk()
  if not config.sound_enabled then return end
  local media_path = get_plugin_path() .. '/phonks'
  local glob_pattern = media_path .. '/*'
  local files = vim.fn.glob(glob_pattern, false, true)
  if #files == 0 then
    vim.notify("Error: No sound files found in phonks/ directory.", vim.log.levels.ERROR)
    return
  end
  local idx = math.random(#files)
  local path = files[idx]
  vim.system({ 'timeout', tostring(config.phonk_time), 'paplay', path, '--volume=35536' }, { detach = true })
end

local function showRandomImage()
  if not config.image_enabled then return end
  local media_path = get_plugin_path() .. '/images'
  local glob_pattern = media_path .. '/*.png'
  local files = vim.fn.glob(glob_pattern, false, true)
  if #files == 0 then
    vim.notify("Error: No PNG files found in images/ directory.", vim.log.levels.ERROR)
    return
  end

  local idx = math.random(#files)
  local path = files[idx]
  local w, h = 30, 30
  local wh = vim.api.nvim_win_get_height(0)
  local total_lines = vim.api.nvim_buf_line_count(0)
  local top_line = vim.fn.line('w0')
  local visible_y = math.floor(wh * 0.6)
  local buffer_y = top_line + visible_y - 1
  buffer_y = math.max(1, math.min(buffer_y, total_lines))

  local x = math.floor((vim.o.columns - w) / 2)

  local ok, image_module = pcall(require, 'image')
  if not ok then
    vim.notify("image.nvim not installed. Install it to see images.", vim.log.levels.WARN)
    return
  end

  local img = image_module.from_file(path, {
    x = x,
    y = buffer_y,
    width = w,
    height = h,
    window = vim.api.nvim_get_current_win(),
  })

  if not img then
    vim.notify("image.nvim failed to load image", vim.log.levels.ERROR)
    return
  end

  img:render()
  vim.defer_fn(function() img:clear() end, config.phonk_time * 1000)
end

local function get_diag_key(diag)
  return string.format("%s:%s:%s", diag.code or '', diag.source or '', diag.message or '')
end

local function update_prev_errors()
  local current_errors = {}
  for _, diag in ipairs(vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })) do
    local key = get_diag_key(diag)
    current_errors[key] = true
  end
  vim.b.prev_error_keys = current_errors
end

local function phonk()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  local opts = {
    relative = 'editor',
    width = vim.o.columns,
    height = vim.o.lines - 1,
    row = 1,
    col = 0,
    style = 'minimal',
    border = 'none',
  }
  local win = vim.api.nvim_open_win(buf, false, opts)
  vim.wo[win].winblend = 70

  vim.api.nvim_set_hl(0, 'BrainrotDimOverlay', { bg = '#000000' })
  vim.wo[win].winhl = 'Normal:BrainrotDimOverlay'

  showRandomImage()
  playRandomPhonk()
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.cmd('redraw!')
  end, config.phonk_time * 1000)
end

local function compare_and_play()
  local current_errors = {}
  for _, diag in ipairs(vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })) do
    local key = get_diag_key(diag)
    current_errors[key] = true
  end

  local prev_keys = vim.b.prev_error_keys or {}
  if not config.disable_phonk then
    local prev_count = 0
    for _ in pairs(prev_keys) do prev_count = prev_count + 1 end
    if prev_count > 0 and next(current_errors) == nil then
      phonk()
    end
  end

  for key in pairs(current_errors) do
    if not prev_keys[key] then
      playBoom()
      break
    end
  end

  vim.b.prev_error_keys = current_errors
end

function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_extend('force', config, opts)

  vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = 'n:*',
    callback = update_prev_errors,
    group = vim.api.nvim_create_augroup('Brainrot', { clear = true }),
  })

  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    callback = function()
      if vim.fn.mode() == 'n' then
        compare_and_play()
      end
    end,
    group = 'Brainrot',
  })

  vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = '*:n',
    callback = compare_and_play,
    group = 'Brainrot',
  })
end

function M.phonk()
  phonk()
end

function M.boom()
  playBoom()
end

return M
