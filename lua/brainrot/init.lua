local M = {}

local config = {
  phonk_time = 2.5,
  min_error_duration = 0.5,
  disable_phonk = false,
  sound_enabled = true,
  image_enabled = true,
  boom_volume = 50,
  phonk_volume = 50,
  boom_sound = nil,
  phonk_dir = nil,
  image_dir = nil,
  block_input = false,
  dim_level = 60,
  lsp_wide = false,
}

local audio_player = nil
local is_phonk_celebrating = false
local last_phonk_time = 0
local error_start_time = nil

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
  elseif os == 'OSX' or os == 'Windows' then
    if is_cmd_available('ffplay') then return 'ffplay' end
    if is_cmd_available('mpv') then return 'mpv' end
  else
    vim.notify("Unsupported OS '" .. os .. "' for audio playback", vim.log.levels.ERROR)
  end

  return nil
end

local function play_with_player(player, path, volume, timeout)
  local cmd = player
  local args = {}
  local full_cmd = {}

  if player == "paplay" then
    args = { "--volume=" .. math.floor((volume / 100) * 65536), path }
    if timeout then
      full_cmd = { "timeout", tostring(timeout), cmd, unpack(args) }
    else
      full_cmd = { cmd, unpack(args) }
    end
  elseif player == "ffplay" then
    args = { "-autoexit", "-nodisp", "-v", "quiet", "-volume", tostring(volume) }
    if timeout then
      table.insert(args, "-t")
      table.insert(args, tostring(timeout))
    end
    table.insert(args, path)
    full_cmd = { cmd, unpack(args) }
  elseif player == "mpv" then
    args = { "--no-video", "--no-terminal", "--no-config", "--volume=" .. volume }
    if timeout then
      table.insert(args, "--length=" .. tostring(timeout))
    end
    table.insert(args, path)
    full_cmd = { cmd, unpack(args) }
  else
    vim.notify(player .. " isn't supported", vim.log.levels.ERROR)
    return
  end

  if vim.fn.executable(cmd) == 0 then
    vim.notify(player .. " not found.", vim.log.levels.ERROR)
    return
  end
  vim.notify(table.concat(full_cmd, " "), vim.log.levels.DEBUG)
  vim.system(full_cmd, { detach = true })
end

local function playBoom()
  if not config.sound_enabled or not audio_player then return end
  local media_path = config.boom_sound or (get_plugin_path() .. '/boom.ogg')
  media_path = vim.fn.expand(media_path)
  play_with_player(audio_player, media_path, config.boom_volume, nil)
end

local function playRandomPhonk()
  if not config.sound_enabled or not audio_player then return end
  local media_path = config.phonk_dir or (get_plugin_path() .. '/phonks')
  media_path = vim.fn.expand(media_path)
  local glob_pattern = media_path .. '/*.{mp3,ogg,wav,flac,m4a,aac,opus}'
  local files = vim.fn.glob(glob_pattern, false, true)
  if #files == 0 then
    vim.notify("Error: No audio files found in " .. media_path .. " directory.", vim.log.levels.ERROR)
    return
  end
  local idx = math.random(#files)
  local path = files[idx]
  play_with_player(audio_player, path, config.phonk_volume, config.phonk_time)
end

local function showRandomImage()
  if not config.image_enabled then return end
  local media_path = config.image_dir or (get_plugin_path() .. '/images')
  media_path = vim.fn.expand(media_path)
  local glob_pattern = media_path .. '/*.{png,jpg,jpeg,gif,webp}'
  local files = vim.fn.glob(glob_pattern, false, true)
  if #files == 0 then
    vim.notify("Error: No image files found in " .. media_path .. " directory.", vim.log.levels.ERROR)
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
  vim.defer_fn(function()
    img:clear()
  end, config.phonk_time * 1000)
end

local function get_diag_key(diag)
  return string.format("%s:%s:%s:%s", diag.bufnr or '', diag.code or '', diag.source or '', diag.message or '')
end

local function get_prev_keys()
  return config.lsp_wide and (vim.g.prev_error_keys or {}) or (vim.b.prev_error_keys or {})
end

local function set_prev_keys(keys)
  if config.lsp_wide then
    vim.g.prev_error_keys = keys
  else
    vim.b.prev_error_keys = keys
  end
end

local function get_error_start_time()
  return config.lsp_wide and error_start_time or (vim.b.error_start_time or nil)
end

local function set_error_start_time(time)
  if config.lsp_wide then
    error_start_time = time
  else
    vim.b.error_start_time = time
  end
end

local function update_prev_errors()
  local bufnr
  if config.lsp_wide then
    bufnr = nil
  else
    bufnr = 0
  end
  local current_errors = {}
  for _, diag in ipairs(vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })) do
    local key = get_diag_key(diag)
    current_errors[key] = true
  end
  set_prev_keys(current_errors)
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
  local now = vim.uv.now()
  if last_phonk_time > 0 and (now - last_phonk_time) < 2500 then return end
  if is_phonk_celebrating then return end

  last_phonk_time = now
  is_phonk_celebrating = true

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
  vim.wo[win].winblend = 100 - config.dim_level

  vim.api.nvim_set_hl(0, 'BrainrotDimOverlay', { bg = '#000000' })
  vim.wo[win].winhl = 'Normal:BrainrotDimOverlay'

  if config.block_input then blockInput() end
  showRandomImage()
  playRandomPhonk()
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.cmd('redraw!')
    is_phonk_celebrating = false
  end, config.phonk_time * 1000)
end

local function compare_and_play()
  local bufnr
  if config.lsp_wide then
    bufnr = nil
  else
    bufnr = 0
  end
  local current_errors = {}
  for _, diag in ipairs(vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })) do
    local key = get_diag_key(diag)
    current_errors[key] = true
  end

  local prev_keys = get_prev_keys()
  local current_error_count = 0
  for _ in pairs(current_errors) do current_error_count = current_error_count + 1 end
  local prev_error_count = 0
  for _ in pairs(prev_keys) do prev_error_count = prev_error_count + 1 end

  if not config.disable_phonk then
    -- errors -> no errors: check timer, play phonk
    if prev_error_count > 0 and current_error_count == 0 then
      local est = get_error_start_time()
      if config.min_error_duration > 0 and est then
        local elapsed = (vim.uv.now() - est) / 1000
        if elapsed >= config.min_error_duration then
          phonk()
        end
      elseif config.min_error_duration == 0 then
        phonk()
      end
      set_error_start_time(nil)
    end
  end

  -- no errors -> errors: start timer
  if current_error_count > 0 and prev_error_count == 0 and config.min_error_duration > 0 then
    set_error_start_time(vim.uv.now())
  elseif current_error_count == 0 then
    set_error_start_time(nil)
  end

  for key in pairs(current_errors) do
    if not prev_keys[key] then
      playBoom()
      break
    end
  end

  set_prev_keys(current_errors)
end

function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_extend('force', config, opts)

  if type(config.lsp_wide) ~= 'boolean' then
    vim.notify("brainrot.nvim: lsp_wide must be a boolean. Defaulting to false.", vim.log.levels.WARN)
    config.lsp_wide = false
  end
  if config.phonk_time < 0.0 then
    vim.notify("brainrot.nvim: phonk_time cannot be negative. Setting to 0.", vim.log.levels.WARN)
    config.phonk_time = 0.0
  end

  if config.min_error_duration < 0 then
    vim.notify("brainrot.nvim: min_error_duration cannot be negative. Setting to 0.", vim.log.levels.WARN)
    config.min_error_duration = 0
  end

  if config.boom_volume < 0 or config.boom_volume > 100 then
    vim.notify("brainrot.nvim: boom_volume must be between 0 and 100. Setting to 50.", vim.log.levels.WARN)
    config.boom_volume = 50
  end

  if config.phonk_volume < 0 or config.phonk_volume > 100 then
    vim.notify("brainrot.nvim: phonk_volume must be between 0 and 100. Setting to 50.", vim.log.levels.WARN)
    config.phonk_volume = 50
  end

  if config.dim_level < 0 or config.dim_level > 100 then
    vim.notify("brainrot.nvim: dim_level must be between 0 and 100. Setting to 70.", vim.log.levels.WARN)
    config.dim_level = 70
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

function M.toggle_boom()
  config.sound_enabled = not config.sound_enabled
  local status = config.sound_enabled and 'enabled' or 'disabled'
  vim.notify('Boom ' .. status, vim.log.levels.INFO)
end

function M.enable_boom()
  config.sound_enabled = true
  vim.notify('Boom enabled', vim.log.levels.INFO)
end

function M.disable_boom()
  config.sound_enabled = false
  vim.notify('Boom disabled', vim.log.levels.INFO)
end

function M.toggle_phonk()
  config.disable_phonk = not config.disable_phonk
  local status = config.disable_phonk and 'disabled' or 'enabled'
  vim.notify('Phonk ' .. status, vim.log.levels.INFO)
end

function M.enable_phonk()
  config.disable_phonk = false
  vim.notify('Phonk enabled', vim.log.levels.INFO)
end

function M.disable_phonk()
  config.disable_phonk = true
  vim.notify('Phonk disabled', vim.log.levels.INFO)
end

return M
