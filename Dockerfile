ARG PRIVATE_REGISTRY=ci.ru.aegean.gr:5000
FROM ${PRIVATE_REGISTRY}/base20:ruby

RUN apt-get -y update && apt-get -y install  mariadb-server mariadb-client libmysqlclient-dev postgresql postgresql-contrib
#RUN  apt-get -y purge google-chrome-stable \
#    && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
#        && dpkg -i google-chrome*.deb \
#    && sed -i -e 's@exec -a "$0" "$HERE/chrome" "$\@"@exec -a "$0" "$HERE/chrome" "$\@" --no-sandbox  --user-data-dir $HOME/chrome-dir@g' /opt/google/chrome/google-chrome

#chrome driver
#https://stackoverflow.com/questions/50692358/how-to-work-with-a-specific-version-of-chromedriver-while-chrome-browser-gets-up
ARG RUBY_VERSION_TO_INSTALL1=2.7.8
RUN rbenv install ${RUBY_VERSION_TO_INSTALL1} && rbenv global ${RUBY_VERSION_TO_INSTALL1} \
&& rbenv rehash && gem install bundler

#ARG RUBY_VERSION_TO_INSTALL2=3.0.6
#RUN rbenv install ${RUBY_VERSION_TO_INSTALL2} && rbenv global ${RUBY_VERSION_TO_INSTALL2} \
#&& rbenv rehash && gem install bundler
#
#ARG RUBY_VERSION_TO_INSTALL3=3.1.4
#RUN rbenv install ${RUBY_VERSION_TO_INSTALL3} && rbenv global ${RUBY_VERSION_TO_INSTALL3} \
#&& rbenv rehash && gem install bundler
#
#ARG RUBY_VERSION_TO_INSTALL4=3.2.2
#RUN rbenv install ${RUBY_VERSION_TO_INSTALL4} && rbenv global ${RUBY_VERSION_TO_INSTALL4} \
#&& rbenv rehash && gem install bundler

ENV PGUSER=postgres
ENV PGPORT=5432
ENV PGHOST=localhost

RUN sed -i -e '/local.*peer/s/postgres/all/' -e 's/peer\|md5/trust/g' /etc/postgresql/*/main/pg_hba.conf

RUN git config --global --add safe.directory /root/hyperstack

## RUN apt-get purge google-chrome-stable
#RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
#RUN dpkg -i google-chrome*.deb

#RUN apt-get install -y chromium-chromedriver \
##           && ln -s /usr/lib/chromium-browser/chromium-browser /usr/bin/google-chrome \
#           && ln -s /usr/lib/chromium-browser/chromedriver /usr/bin/chromedriver
#  pg_ctlcluster 12 main start
#RUN curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
#RUN apt-get install -y ./google-chrome-stable_current_amd64.deb
#RUN rm google-chrome-stable_current_amd64.deb

#&& \
#    gem install rubygems-update && gem update --system && gem update &&  rbenv rehash