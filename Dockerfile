ARG PRIVATE_REGISTRY=ci.ru.aegean.gr:5000
FROM ${PRIVATE_REGISTRY}/base20:ruby

RUN apt-get -y update && apt-get -y install  mariadb-server mariadb-client libmysqlclient-dev postgresql postgresql-contrib

ARG RUBY_VERSION_TO_INSTALL1=2.7.8
RUN rbenv install ${RUBY_VERSION_TO_INSTALL1} && rbenv global ${RUBY_VERSION_TO_INSTALL1} \
&& rbenv rehash && gem install bundler

ARG RUBY_VERSION_TO_INSTALL2=3.0.6
RUN rbenv install ${RUBY_VERSION_TO_INSTALL2} && rbenv global ${RUBY_VERSION_TO_INSTALL2} \
&& rbenv rehash && gem install bundler

ARG RUBY_VERSION_TO_INSTALL3=3.1.4
RUN rbenv install ${RUBY_VERSION_TO_INSTALL3} && rbenv global ${RUBY_VERSION_TO_INSTALL3} \
&& rbenv rehash && gem install bundler

ARG RUBY_VERSION_TO_INSTALL4=3.2.2
RUN rbenv install ${RUBY_VERSION_TO_INSTALL4} && rbenv global ${RUBY_VERSION_TO_INSTALL4} \
&& rbenv rehash && gem install bundler

ENV PGUSER=postgres
ENV PGPORT=5432
ENV PGHOST=localhost

RUN sed -i -e '/local.*peer/s/postgres/all/' -e 's/peer\|md5/trust/g' /etc/postgresql/*/main/pg_hba.conf

RUN git config --global --add safe.directory /root/hyperstack