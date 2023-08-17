#!/usr/bin/env bash
set -e

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
