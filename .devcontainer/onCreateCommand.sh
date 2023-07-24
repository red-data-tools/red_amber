#!/usr/bin/env bash
set -e

APACHE_ARROW_VERSION=12.0.1-1
RBENV_RUBY=3.2.2

# To install Ruby
# https://github.com/rbenv/ruby-build/wiki#ubuntudebianmint
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
        autoconf \
        bison \
        rustc \
        libssl-dev \
        libyaml-dev \
        libreadline6-dev \
        zlib1g-dev \
        libgmp-dev \
        libncurses5-dev \
        libffi-dev \
        libgdbm6 \
        libgdbm-dev \
        libdb-dev \
        uuid-dev
# For iruby
sudo apt-get install -y --no-install-recommends \
        libczmq-dev \
        libzmq3-dev

# Install Apache Arrow
arrow_dev_tmp=/tmp/apache-arrow-apt-source.deb
curl -sfSL -o ${arrow_dev_tmp} https://apache.jfrog.io/artifactory/arrow/ubuntu/pool/jammy/main/a/apache-arrow-apt-source/apache-arrow-apt-source_${APACHE_ARROW_VERSION}_all.deb
sudo apt-get install -y ${arrow_dev_tmp}
rm -f ${arrow_dev_tmp}
sudo apt-get update
sudo apt-get install -y \
        libarrow-dev \
        libarrow-glib-dev \
        libarrow-dataset-dev \
        libarrow-flight-dev \
        libparquet-dev \
        libparquet-glib-dev \
        libgandiva-dev \
        libgandiva-glib-dev

# Install rbenv
git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv
echo 'eval "$($HOME/.rbenv/bin/rbenv init -)"' >> $HOME/.profile
echo 'eval "$($HOME/.rbenv/bin/rbenv init -)"' >> $HOME/.bashrc
source $HOME/.profile
git clone https://github.com/rbenv/ruby-build.git $HOME/.rbenv/plugins/ruby-build

# Install Ruby
# Append `RUBY_CONFIGURE_OPTS=--disable-install-doc ` before rbenv to disable documents
rbenv install --verbose $RBENV_RUBY
rbenv global $RBENV_RUBY
bundle install

# Install IRuby
gem install iruby
iruby register --force

# Install language and set timezone
# You should change here if you use another
sudo apt-get update
sudo apt-get install -y language-pack-ja

echo 'export LANG=ja_JP.UTF-8' >> ~/.bashrc
echo 'export LANG=ja_JP.UTF-8' >> ~/.profile
echo 'export TZ=Asia/Tokyo' >> ~/.bashrc
echo 'export TZ=Asia/Tokyo' >> ~/.profile
