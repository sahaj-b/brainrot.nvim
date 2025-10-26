# brainrot.nvim

Vine boom when a new error appears. Phonk + dim overlay + meme image when you clear the last error.


https://github.com/user-attachments/assets/e68578ee-69e5-4fc6-b45a-493a98e8d225


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
    -- defaults:
    phonk_time = 2.5,      -- seconds the phonk/image overlay stays
    disable_phonk = false, -- skip phonk/overlay on "no errors"
    sound_enabled = true,  -- enable sounds
    image_enabled = true,  -- enable images (needs image.nvim)
    volume = 50,           -- 0..100
    boom_sound = nil,      -- custom boom sound path (e.g., "~/sounds/boom.ogg")
    phonk_dir = nil,       -- custom phonk folder path (e.g., "~/sounds/phonks")
    image_dir = nil,       -- custom image folder path (e.g., "~/memes/images")
    block_input = true,    -- block input during phonk/overlay
  },
}
```

## What it does
- New error detected: plays Vine Boom once.
- Went from "had errors" to "no errors": plays a random phonk track and shows a random PNG, with a dim fullscreen overlay (optionally blocking inputs) for `phonk_time` seconds.
- Only triggers in Normal mode (won’t fire while you’re typing). It updates on `DiagnosticChanged` and on mode changes into/out of Normal.

## Commands
- `:Brainrot boom`: trigger the vine boom sound now
- `:Brainrot phonk`: trigger the overlay + random phonk now

## Known Issues
- When pressing `<CR>` (Enter) inside a bracket pair like `{|}` to auto-expand into a block (when using an autopair plugin), it will detect errors and play vine boom. Workaround is to disable the auto-expand (eg: `map_cr = false` in `nvim-autopairs`).

## ...WHY?
[coz why not](https://x.com/sahaj__b/status/1981749009350811966)
