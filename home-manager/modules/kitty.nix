{ config, pkgs, lib, ... }:
{
  programs.kitty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.runCommand "kitty-dummy" {} "mkdir $out" else pkgs.kitty;
    settings = {
      font_family = "JetBrainsMono Nerd Font Light";
      font_size = 12;
      background_opacity = "0.92";
      background_blur = 1;
      window_padding_width = "0 4";
      # Colors
      background = "#161821";
      foreground = "#d2d4de";
      color0 = "#161821";
      color1 = "#e27878";
      color2 = "#b4be82";
      color3 = "#e2a478";
      color4 = "#84a0c6";
      color5 = "#a093c7";
      color6 = "#89b8c2";
      color7 = "#c6c8d1";
      color8 = "#6b7089";
      color9 = "#e98989";
      color10 = "#c0ca8e";
      color11 = "#e9b189";
      color12 = "#91acd1";
      color13 = "#ada0d3";
      color14 = "#95c4ce";
      color15 = "#d2d4de";
      # Tab bar
      tab_bar_style = "custom";
      tab_bar_edge = "top";
      tab_bar_background = "#161821";
      active_tab_foreground = "#d2d4de";
      active_tab_background = "#84a0c6";
      active_tab_font_style = "normal";
      inactive_tab_foreground = "#6b7089";
      inactive_tab_background = "#1e2030";
      inactive_tab_font_style = "normal";
    };
    keybindings = {
      "super+1" = "goto_tab 1";
      "super+2" = "goto_tab 2";
      "super+3" = "goto_tab 3";
      "super+4" = "goto_tab 4";
      "super+5" = "goto_tab 5";
      "super+6" = "goto_tab 6";
      "super+7" = "goto_tab 7";
      "super+8" = "goto_tab 8";
      "super+9" = "goto_tab 9";
      "ctrl+w" = "send_text all \\x17";
    };
  };

  xdg.configFile."kitty/tab_bar.py".text = ''
    from kitty.fast_data_types import Screen
    from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

    def draw_tab(
        draw_data: DrawData,
        screen: Screen,
        tab: TabBarData,
        before: int,
        max_title_length: int,
        index: int,
        is_last: bool,
        extra_data: ExtraData,
    ) -> int:
        num_tabs = extra_data.num_tabs
        base_width = screen.columns // num_tabs
        tab_width = screen.columns - before if is_last else base_width

        if tab.is_active:
            fg = draw_data.active_fg
            bg = draw_data.active_bg
        else:
            fg = draw_data.inactive_fg
            bg = draw_data.inactive_bg

        screen.cursor.fg = as_rgb(fg)
        screen.cursor.bg = as_rgb(bg)

        title = tab.title or f"Tab {index}"
        if len(title) > tab_width - 2:
            title = title[: tab_width - 5] + "..."
        padding_total = tab_width - len(title)
        left_pad = padding_total // 2
        right_pad = padding_total - left_pad
        screen.draw(" " * left_pad + title + " " * right_pad)

        return screen.cursor.x
  '';
}
