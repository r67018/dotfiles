#!/bin/sh

PWD=$(pwd -P)

ln -nfs $PWD/config/tmux/.tmux.conf ~/.tmux.conf
ln -nfs $PWD/config/fish ~/.config/fish
ln -nfs $PWD/config/nvim ~/.config/nvim
ln -nfs $PWD/config/intellij/.ideavimrc ~/.ideavimrc
ln -nfs $PWD/config/wezterm/.wezterm.lua ~/.wezterm.lua
dconf load /org/gnome/terminal/ < $PWD/config/gnome/terminal/settings.txt

