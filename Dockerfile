FROM ruby:2.3
ADD ./demoapp.rb /usr/local/bin
RUN gem install sinatra json
EXPOSE 8888
cmd ["/usr/local/bin/demoapp.rb"]