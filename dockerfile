# syntax=docker/dockerfile:1
#
# Three stages: a shared base with only the runtime libraries, a `gems` stage
# that owns the compilers, and a runtime stage that copies the built gems across
# and never sees a compiler. The runtime image runs as a non-root user.

ARG RUBY_VERSION=3.4

# --- base -------------------------------------------------------------------
FROM ruby:${RUBY_VERSION}-slim-bookworm AS base

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
    BUNDLE_WITHOUT=${BUNDLE_WITHOUT}

WORKDIR /app

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends libpq5 libyaml-0-2 tzdata \
 && rm -rf /var/lib/apt/lists/*

# --- gems -------------------------------------------------------------------
FROM base AS gems

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends build-essential libpq-dev libyaml-dev git \
 && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install \
 && rm -rf "${BUNDLE_PATH}"/cache "${BUNDLE_PATH}"/ruby/*/cache

# --- runtime ----------------------------------------------------------------
FROM base AS runtime

COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY . .

RUN useradd --create-home --shell /bin/bash --uid 1000 app \
 && mkdir -p tmp/pids tmp/letter_opener log \
 && chown -R app:app /app

USER app

EXPOSE 3000

# /up is Rails' health route; it proves the app booted and Puma is accepting
# connections.
HEALTHCHECK --interval=10s --timeout=5s --start-period=60s --retries=10 \
  CMD ["bin/healthcheck"]

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
