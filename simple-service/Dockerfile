FROM ruby:2.3.1-alpine
LABEL  srai.micro.service="simple-service" srai.micro.project="true"

ENV APP_HOME=/build
RUN mkdir $APP_HOME && apk update && apk add git
WORKDIR $APP_HOME
COPY Gemfile .
COPY Gemfile.lock .
RUN gem install bundler \
    && bundle install

EXPOSE 4567

COPY . $APP_HOME

ENTRYPOINT ["bundle", "exec", "ruby", "app/simple_server.rb"]
