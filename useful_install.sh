#! /bin/bash

# Use the pre-install ros iso, we need sudo rosdep init; rosdep update
sudo rosdep init
rosdep update

# nautilus-open-terminal
sudo apt-get install nautilus-open-terminal

# git
sudo apt-get install -y zlib1g-dev
sudo apt-get install -y curl

# zsh + oh-my-zsh
sudo apt-get install zsh
wget -nc https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
chsh -s /bin/zsh

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# emacs + gtags
sudo apt-get install -y libgtk2.0-dev
sudo apt-get install -y libxpm-dev
sudo apt-get install -y libncurses5-dev
sudo apt-get install -y libjpeg-dev
sudo apt-get install -y libgif-dev
sudo apt-get install -y libtiff5-dev

sudo apt-get install -y libsdl1.2-dev
sudo apt-get install -y ncurses-bin
sudo apt-get install -y libncurses5-dev

# vim + ctags
# sudo apt-get install vim

## "Usage: ctags-exuberant -R *"

# sudo apt-get install
sudo apt-get install exuberant-ctags
sudo apt-get install silversearcher-ag
sudo apt-get install paraview

