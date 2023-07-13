#!/usr/bin/env sh
set -eux

# Install IRuby 
sudo apt-get update
sudo apt-get install -y libczmq-dev libzmq3-dev

gem install iruby
iruby register --force

# Install Apache Arrow
APACHE_ARROW_VERSION=12.0.1-1
arrow_dev_tmp=/tmp/apache-arrow-apt-source.deb

sudo apt-get update
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

bundle install
