FROM ruby:2.6.6-alpine
MAINTAINER rosevita <qs2811531808@gmail.com>
# 更新安装源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN apk --update add build-base libpq nodejs vim imagemagick postgresql-dev tzdata yarn
RUN mkdir /app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
ENV RAILS_ENV production
RUN gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/ \ && gem sources -l
RUN gem install bundler:2.1.4
RUN bundler -v
RUN bundle install
COPY . /app
CMD rake db:migrate assets:precompile && puma -C config/puma.rb