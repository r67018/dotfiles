#!/bin/sh

PWD=$(pwd -P)

# zsh
ln -nfs $PWD/.zshrc ~/.zshrc
# tmux
ln -nfs $PWD/.config/tmux/.tmux.conf ~/.tmux.conf
# fish
ln -nfs $PWD/.config/fish ~/.config/fish
# git
ln -nfs $PWD/.config/git/.gitconfig ~/.gitconfig
# neovim
ln -nfs $PWD/.config/nvim ~/.config/nvim
# IdeaVim(vim plugin for Jetbrains IDE)
ln -nfs $PWD/.config/intellij/.ideavimrc ~/.ideavimrc
# wezterm
ln -nfs $PWD/.config/wezterm/.wezterm.lua ~/.wezterm.lua
# gnome terminal
if command -v dconf &> /dev/null; then
    dconf load /org/gnome/terminal/ < $PWD/.config/gnome/terminal/settings.txt
fi

