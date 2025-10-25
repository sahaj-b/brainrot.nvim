local M = {}

local config = {
  phonk_time = 2.5,
  disable_phonk = false,
  sound_enabled = true,
  image_enabled = true,
  volume = 50,
}

local audio_player = nil
local is_phonk_playing = false

local function get_plugin_path()
  local script_path = debug.getinfo(1, 'S').source:sub(2)
  return vim.fn.fnamemodify(script_path, ':h:h:h')
end

local function is_cmd_available(cmd)
  return vim.fn.executable(cmd) == 1
end

local function detect_audio_player()
  local os = jit.os

  if os == 'Linux' then
    if is_cmd_available('paplay') then return 'paplay' end
    if is_cmd_available('ffplay') then return 'ffplay' end
    if is_cmd_available('mpv') then return 'mpv' end
  elseif os == 'OSX' then
    if is_cmd_available('afplay') then return 'afplay' end
    if is_cmd_available('ffplay') then return 'ffplay' end
    if is_cmd_available('mpv') then return 'mpv' end
  elseif os == 'Windows' then
    if is_cmd_available('ffplay') then return 'ffplay' end
    if is_cmd_available('mpv') then return 'mpv' end
  else
    vim.notify("Unsupported OS '" .. os .. "' for audio playback", vim.log.levels.ERROR)
  end

  return nil
end

local function play_with_player(player, path, volume, timeout)
  local cmd
  local args = {}
  if player == "paplay" then
    cmd = "paplay"
    table.insert(args, "--volume=" .. math.floor((volume / 100) * 65536))
    table.insert(args, path)
  elseif player == "ffplay" then
    cmd = "ffplay"
    table.insert(args, "-autoexit")
    table.insert(args, "-nodisp")
    table.insert(args, "-v")
    table.insert(args, "quiet")
    table.insert(args, "-volume")
    table.insert(args, tostring(volume))
    table.insert(args, path)
  elseif player == "afplay" then
    cmd = "afplay"
    table.insert(args, "-v")
    table.insert(args, tostring(volume / 100))
    table.insert(args, path)
  elseif player == "mpv" then
    cmd = "mpv"
    table.insert(args, "--no-video")
    table.insert(args, "--no-terminal")
    table.insert(args, "--no-config")
    table.insert(args, "--volume=" .. volume)
    table.insert(args, path)
  else
    vim.notify(player .. " isn't supported", vim.log.levels.ERROR)
    return
  end

  if vim.fn.executable(cmd) == 0 then
    vim.notify(player .. " not found.", vim.log.levels.ERROR)
    return
  end

  table.insert(args, 1, cmd)

  if timeout and jit.os ~= 'Windows' then
    table.insert(args, 1, tostring(timeout))
    table.insert(args, 1, "timeout")
  end

  vim.system(args, { detach = true })
end

local function playBoom()
  if not config.sound_enabled or not audio_player then return end
  local media_path = get_plugin_path() .. '/boom.ogg'
  play_with_player(audio_player, media_path, config.volume, nil)
end

local function playRandomPhonk()
   if is_phonk_playing or not config.sound_enabled or not audio_player then return end
   is_phonk_playing = true
   local media_path = get_plugin_path() .. '/phonks'
   local glob_pattern = media_path .. '/*'
   local files = vim.fn.glob(glob_pattern, false, true)
   if #files == 0 then
     vim.notify("Error: No sound files found in " .. media_path .. " directory.", vim.log.levels.ERROR)
     is_phonk_playing = false
     return
   end
   local idx = math.random(#files)
   local path = files[idx]
   play_with_player(audio_player, path, config.volume, config.phonk_time)
   vim.defer_fn(function()
     is_phonk_playing = false
   end, config.phonk_time * 1000)
end

local function showRandomImage()
  if not config.image_enabled then return end
  local media_path = get_plugin_path() .. '/images'
  local glob_pattern = media_path .. '/*.png'
  local files = vim.fn.glob(glob_pattern, false, true)
  if #files == 0 then
    vim.notify("Error: No PNG files found in " .. media_path .. " directory.", vim.log.levels.ERROR)
    return
  end

  local ok, image_module = pcall(require, 'image')
  if not ok then
    vim.notify("image.nvim not installed. Install it to see images.", vim.log.levels.WARN)
    return
  end

  local idx = math.random(#files)
  local path = files[idx]
  local w, h = 30, 30
  local wh = vim.api.nvim_win_get_height(0)
  local x = math.floor((vim.o.columns - w) / 2)
  local y = math.floor(wh * 0.6)


  local img = image_module.from_file(path, {
    x = x,
    y = y,
    width = w,
    height = h,
    window = nil,
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

local function blockInput()
  local ns_id = vim.on_key(function(_, _)
    return ""
  end)
  vim.defer_fn(function()
    vim.on_key(nil, ns_id)
  end, config.phonk_time * 1000)
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

  blockInput()
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
  if config.phonk_time < 0.0 then
    vim.notify("brainrot.nvim: phonk_time cannot be negative. Setting to 0.", vim.log.levels.WARN)
    config.phonk_time = 0.0
  end

  if config.volume < 0 or config.volume > 100 then
    vim.notify("brainrot.nvim: Volume must be between 0 and 100. Setting to 0.", vim.log.levels.WARN)
    config.volume = 0
  end

  audio_player = detect_audio_player()

  if config.sound_enabled and not audio_player then
    vim.notify(
      "brainrot.nvim: No audio player found. Install ffplay, mpv, paplay (Linux), or afplay (macOS).",
      vim.log.levels.WARN
    )
  end

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
