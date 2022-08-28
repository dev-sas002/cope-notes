# syntax=docker/dockerfile:1
#
# Three stages: a shared base with only the runtime libraries, a `gems` stage
# that owns the compilers, and a runtime stage that copies the built gems across
# and never sees a compiler. The runtime image runs as a non-root user.

ARG RUBY_VERSION=3.0.2

# --- base -------------------------------------------------------------------
FROM ruby:${RUBY_VERSION}-slim-bullseye AS base

# Which bundle groups to leave out. The default is none, because the compose
# stack runs in the development environment: it wants letter_opener_web to show
# the mail it sends, and RSpec so the suite can be run inside the image. Build a
# lean production image with:
#
#     docker build -f dockerfile --build-arg BUNDLE_WITHOUT="development test" .
#
# That image has no letter_opener_web, which is exactly why routes.rb mounts it
# behind `if Rails.env.development?` - the constant does not exist in production.
ARG BUNDLE_WITHOUT=""

ENV LANG=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_WITHOUT=${BUNDLE_WITHOUT} \
    RAILS_LOG_TO_STDOUT=1

WORKDIR /app

# Debian 11 is end of life and its security pool is part-way through being moved
# to archive.debian.org, so `security.debian.org` currently 404s on packages its
# index still advertises. archive.debian.org is the stable, reproducible mirror.
# The application is pinned to Ruby 3.0.2 by Rails 6.1, and upstream only
# publishes bullseye images for that Ruby, so this is the base we have.
RUN printf '%s\n' 'deb http://archive.debian.org/debian bullseye main' > /etc/apt/sources.list \
 && apt-get -o Acquire::Check-Valid-Until=false update -qq \
 && apt-get install -y --no-install-recommends libpq5 tzdata \
 && rm -rf /var/lib/apt/lists/*

# --- gems -------------------------------------------------------------------
FROM base AS gems

RUN apt-get -o Acquire::Check-Valid-Until=false update -qq \
 && apt-get install -y --no-install-recommends build-essential libpq-dev \
 && rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v 2.2.32

COPY Gemfile Gemfile.lock ./

# Gemfile.lock is resolved on a developer's macOS checkout, so its PLATFORMS
# section lists only x86_64-darwin. Platform-specific gems - nokogiri above all -
# have no darwin build that a Linux container can load, and bundler will not
# reach for the linux build of a gem whose platform the lockfile never
# registered. Registering the two linux platforms here fixes that inside the
# image and leaves the committed lockfile byte-for-byte unchanged, so nobody has
# to run bundler on a machine they do not develop on just to build a container.
RUN bundle lock --add-platform x86_64-linux aarch64-linux \
 && bundle install \
 && rm -rf "${BUNDLE_PATH}"/cache "${BUNDLE_PATH}"/ruby/*/cache

# --- runtime ----------------------------------------------------------------
FROM base AS runtime

COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY . .
# ...and the runtime needs the same platform-augmented lockfile the gems were
# installed from, not the darwin-only one that `COPY . .` just laid down.
COPY --from=gems /app/Gemfile.lock ./Gemfile.lock

RUN useradd --create-home --shell /bin/bash --uid 1000 app \
 && mkdir -p tmp/pids tmp/letter_opener log \
 && chown -R app:app /app

USER app

EXPOSE 3000

# /up is a static route; it proves Puma is accepting connections.
HEALTHCHECK --interval=10s --timeout=5s --start-period=60s --retries=10 \
  CMD ["bin/healthcheck"]

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
