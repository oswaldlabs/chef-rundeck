FROM ruby:2.2.5

RUN mkdir -p /opt/chef-rundeck; mkdir -p /opt/knife

RUN apt-get install git -y

RUN git clone https://github.com/ehlerst/chef-rundeck.git /opt/chef-rundeck

### Get deps ready
RUN gem install jeweler

RUN cd /opt/chef-rundeck; gem build chef-rundeck.gemspec; gem install chef-rundeck

EXPOSE 9980

CMD ["/usr/local/bundle/bin/chef-rundeck", "-c", "/opt/knife/knife.rb", "-o", "0.0.0.0", "-t", "3600", "--partial-search", "true"]
