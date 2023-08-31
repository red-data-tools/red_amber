#!/usr/bin/env bash
set -e

# Explicitly set ownership of /workspaces to vscode:vscode
# Because recent runner has uid=1001(runner), gid=999(docker)
sudo chown -R $(id -un):$(id -un) /workspaces

# Install language and set timezone
# You should change here if you use another
sudo apt-get update
sudo apt-get install -y language-pack-ja

echo 'export LANG=ja_JP.UTF-8' >> $HOME/.bashrc
echo 'export LANG=ja_JP.UTF-8' >> $HOME/.profile
echo 'export TZ=Asia/Tokyo' >> $HOME/.bashrc
echo 'export TZ=Asia/Tokyo' >> $HOME/.profile

# Install HaranoAjiFonts
mkdir -p $HOME/.fonts
git clone https://github.com/trueroad/HaranoAjiFonts.git $HOME/.fonts/HaranoAjiFonts

# Install gems
bundle install

# Create Jupyter Notebooks
rake quarto:convert
