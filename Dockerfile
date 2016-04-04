FROM ubuntu:16.04

RUN /usr/bin/apt-get update && /usr/bin/apt-get install --no-install-recommends -qy ruby ruby-dev make g++ && gem install bundler --no-ri --no-rdoc
ADD Gemfile /ruby-app/Gemfile
ADD Gemfile.lock /ruby-app/Gemfile.lock
WORKDIR /ruby-app
RUN /usr/bin/env bundle install
RUN /usr/bin/apt-get remove -qy ruby-dev make g++ && /usr/bin/apt-get -qy autoremove
RUN /bin/rm -rf /var/lib/gems/2.1.0/cache /var/cache/* /var/lib/apt/lists/*
ADD . /ruby-app
RUN find . -type f -print -exec chmod 444 {} \; && find . -type d -print -exec chmod 555 {} \;
ENTRYPOINT ["/usr/bin/ruby", "/ruby-app/agent.rb"]
