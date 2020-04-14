FROM ruby:2.6.6-alpine
# Specify the maintainer of the image
MAINTAINER rosevita <qs2811531808@gmail.com>
# Update installation source for alpinelinux
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# Install the dependencies
RUN apk --update add build-base libpq nodejs vim imagemagick postgresql-dev tzdata yarn
#We use the command RUN on the Dockerfile to execute the commands we want to use in the image.
RUN mkdir /app
#Specify work directory
WORKDIR /app
#Copy the file to the target path on a image of new layer
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
ENV RAILS_ENV production
RUN gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/ \ && gem sources -l
RUN gem install bundler:2.1.4
RUN bundler -v
RUN bundle install
COPY . /app
CMD rake db:migrate assets:precompile && puma -C config/puma.rb