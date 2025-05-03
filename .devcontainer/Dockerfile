ARG VARIANT=ubuntu-24.04

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

# To install Apache Arrow
RUN set -e; \
    apt update; \
    apt install -y -V ca-certificates lsb-release wget; \
    wget https://packages.apache.org/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb; \
    apt install -y -V ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb; \
    rm -f ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb; \
    apt update

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
