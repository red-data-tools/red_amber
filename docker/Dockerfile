# x86-64/Ubuntu-22.04/python-3.10.9/lab-3.6.1/notebook-6.5.3/2023-03-13
ARG BASE_IMAGE_TAG=295612d3ade4

FROM jupyter/minimal-notebook:$BASE_IMAGE_TAG

USER root

RUN set -eux; \
    apt update; \
    apt install -y --no-install-recommends \
        curl \
        \
        # For Apache Arrow
        ca-certificates \
        lsb-release \
        \
        # Ruby 3.0.2
        ruby-dev \
        \
        # For iruby
        libczmq-dev \
        libzmq3-dev

# Apache Arrow
ARG ARROW_DEB_TMP=/tmp/apache-arrow-apt-source-latest.deb

RUN set -eux; \
    apt update; \
    curl -sfSL -o ${ARROW_DEB_TMP} \
        https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb; \
    apt install -y --no-install-recommends \
        ${ARROW_DEB_TMP}; \
    rm -f ${ARROW_DEB_TMP}; \
    apt update; \
    apt install -y \
        libarrow-dev \
        libarrow-glib-dev \
        libparquet-dev \
        libparquet-glib-dev \
        libgirepository1.0-dev; \
    rm -rf /var/lib/apt/lists/*

USER $NB_USER

WORKDIR $HOME

# Install rbenv
RUN set -eux; \
    git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv; \
    echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> $HOME/.bash_profile; \
    source $HOME/.bash_profile; \
    git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

ENV MAKE_OPTS='-j 4'
ENV PATH $HOME/.local/share/gem/bin:$HOME/.local/share/gem/ruby/3.0.0/bin:$PATH

# IRuby
RUN set -eux; \
    gem install --user-install \
        rake \
        bundler \
        iruby; \
    iruby register --force

COPY Gemfile $HOME
COPY Gemfile.lock $HOME

ENV GEM_HOME=$HOME/.local/share/gem
ENV BUNDLE_PATH=$HOME/.local/share/gem
ENV BUNDLE_BIN=$HOME/.local/share/gem/bin

RUN bundle install --jobs=4
