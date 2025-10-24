# brainrot.nvim
# WIP

Vine Boom on new errors, Phonk on fixing all errors

## Requirements
- Neovim 0.9+
- `paplay` (Linux, only... Cross platform coming soon)
- `image.nvim` (optional, for showing images)

## Installation

### Using lazy.nvim

```lua
{
  'sahaj-b/brainrot.nvim',
  event = 'VeryLazy',
  opts = {
    phonk_time = 2.5,        -- duration of phonk/image display in seconds
    disable_phonk = false,   -- disable phonk/image
    sound_enabled = true,    -- enable/disable sounds
    image_enabled = true,    -- enable/disable images
  }
}
```
