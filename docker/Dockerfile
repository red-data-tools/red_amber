# x86_64/Ubuntu-24.04/python-3.12.10/lab-4.4.1/notebook-7.4.1/2025-04=26
ARG BASE_IMAGE_TAG=5b8d531acae5

FROM quay.io/jupyter/minimal-notebook:$BASE_IMAGE_TAG

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
        # Ruby 3.2
        libyaml-dev \
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

USER $NB_UID

WORKDIR $HOME

ENV PATH $HOME/.local/share/gem/bin:$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH

# IRuby
RUN set -eux; \
    gem install --user-install \
        rake \
        bundler \
        iruby; \
    iruby register --force

COPY --chown=$NB_UID:$NB_GID Gemfile $HOME

ENV GEM_HOME=$HOME/.local/share/gem
ENV BUNDLE_PATH=$HOME/.local/share/gem
ENV BUNDLE_BIN=$HOME/.local/share/gem/bin

RUN bundle install --jobs=4
