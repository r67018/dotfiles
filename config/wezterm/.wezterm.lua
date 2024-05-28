local wezterm = require 'wezterm'
local act = wezterm.action

local keys = {
    {
        key = "8",
        mods = "CTRL",
        action = act.PaneSelect,
    },
    {
        key = "\\",
        mods = "ALT",
        action = act.SplitHorizontal {
            domain = "CurrentPaneDomain",
        },
    },
    {
        key = "-",
        mods = "ALT",
        action = act.SplitVertical {
            domain = "CurrentPaneDomain",
        }
    }
}

return {
    default_prog = {"C:/Program Files/PowerShell/7/pwsh.exe", "-l"},
    color_scheme = "iceberg-dark",
    font = wezterm.font("JetBrains Mono", {weight="Light", stretch="Normal", style="Normal"}),
    font_size = 12.5,
    -- window_background_opacity = 0.9,
    keys = keys,
    harfbuzz_features = {"calt=0", "clig=0", "liga=0"},
}

