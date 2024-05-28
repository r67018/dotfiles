local wezterm = require 'wezterm'
local act = wezterm.act

return {
    keys = {
        {
            key = "k",
            mods="ALT",
            action = act.SplitPane{
                direction = 'Left',
                command = { args = { 'top' } },
                size = { Percent = 50 },
            },
        },
    },
}

