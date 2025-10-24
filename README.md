# brainrot.nvim

Vine boom when a new error appears. Phonk + dim overlay + meme image when you clear the last error.

## Requirements
- Neovim 0.9+
- Audio player
  - Linux: `paplay`, `ffplay`, or `mpv`
  - macOS: `afplay`, `ffplay`, or `mpv`
  - Windows: `ffplay` or `mpv`
- [image.nvim](https://github.com/3rd/image.nvim) (Optional, for images)

## Install (lazy.nvim)
```lua
{
  'sahaj-b/brainrot.nvim',
  event = 'VeryLazy',
  opts = {
    phonk_time = 2.5,      -- seconds the phonk/image overlay stays
    disable_phonk = false, -- skip phonk/overlay on "no errors"
    sound_enabled = true,  -- enable sounds
    image_enabled = true,  -- enable images (needs image.nvim)
    volume = 50,           -- 0..100
  },
}
```

## What it does
- New error detected: plays Vine Boom once.
- Went from "had errors" to "no errors": plays a random phonk track and shows a random PNG, with a dim fullscreen overlay for `phonk_time` seconds.
- Only triggers in Normal mode (won’t fire while you’re typing). It updates on `DiagnosticChanged` and on mode changes into/out of Normal.

## Commands
- `:Brainrot boom` — trigger the vine boom sound now
- `:Brainrot phonk` — trigger the overlay + random phonk now


## Issues
Image positioning is kinda funky rn (probably `image.nvim`'s issue)
