FROM ruby:3.0.2-slim-buster

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN gem update --system
RUN bundle install

COPY . .

EXPOSE 3000

CMD ["echo", "done"]
