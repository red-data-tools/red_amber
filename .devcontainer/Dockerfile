# [Choice] debian-11, debian-10, ubuntu-22.04, ubuntu-20.04, ubuntu-18.04
ARG VARIANT=ubuntu-22.04

FROM mcr.microsoft.com/devcontainers/base:${VARIANT}

# Set env for tracking that we're running in a devcontainer
ENV DEVCONTAINER=true

RUN set -e; \
    apt-get update; \
    apt-get install -y \
    # To build Ruby
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
    uuid-dev \
    # To install IRuby
    libczmq-dev \
    libzmq3-dev

# Install Apache Arrow
ARG APACHE_ARROW_VERSION=15.0.0-1
ARG arrow_deb_tmp=/tmp/apache-arrow-apt-source-latest.deb
ARG arrow_apt_source=https://apache.jfrog.io/artifactory/arrow/ubuntu/pool/jammy/main/a/apache-arrow-apt-source/apache-arrow-apt-source_${APACHE_ARROW_VERSION}_all.deb
RUN set -e; \
    apt-get update; \
    curl -sfSL -o ${arrow_deb_tmp} ${arrow_apt_source}; \
    apt-get install -y --no-install-recommends ${arrow_deb_tmp}; \
    rm -f ${arrow_deb_tmp}; \
    apt-get update; \
    apt-get install -y \
    libarrow-dev \
    libarrow-glib-dev \
    libarrow-dataset-dev \
    libarrow-flight-dev \
    libparquet-dev \
    libparquet-glib-dev \
    libgandiva-dev \
    libgandiva-glib-dev

# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

USER $USERNAME

# Install rbenv
ARG RBENV_RUBY=3.3.0
RUN set -e; \
    git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv; \
    echo 'eval "$($HOME/.rbenv/bin/rbenv init -)"' >> $HOME/.profile; \
    echo 'eval "$($HOME/.rbenv/bin/rbenv init -)"' >> $HOME/.bashrc; \
    git clone https://github.com/rbenv/ruby-build.git $HOME/.rbenv/plugins/ruby-build

# Install Ruby
# Append `RUBY_CONFIGURE_OPTS=--disable-install-doc ` before rbenv to disable documents
RUN set -e; \
    $HOME/.rbenv/bin/rbenv install --verbose $RBENV_RUBY; \
    $HOME/.rbenv/bin/rbenv global $RBENV_RUBY

# Install IRuby
RUN set -e; \
    $HOME/.rbenv/bin/rbenv exec gem install iruby; \
    $HOME/.rbenv/bin/rbenv exec iruby register --force
