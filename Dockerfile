# Ubuntu Homer.

FROM ubuntu:14.04
MAINTAINER Thomas Quintana <thomas@bettervoice.com>

# Install Dependencies
RUN apt-get update && apt-get install -y bison ca-certificates cron flex git-core libcurl4-openssl-dev libclass-dbi-mysql-perl libclass-dbi-pg-perl libdbi-perl libmysqlclient-dev libpcre3-dev libpq-dev libssl-dev libxml2-dev nginx perl php5 php5-cli php5-dev php5-fpm php5-gd php5-json php5-mysql php-pear php5-pgsql php-services-json postgresql-client python python-dev

# Update PIP
ADD bin/get-pip.py /usr/local/bin/get-pip.py
RUN python /usr/local/bin/get-pip.py

# Install Python Dependencies
RUN pip install --upgrade six
RUN pip install Jinja2

# Install Homer5
RUN git clone -b homer5 --depth 1 https://github.com/sipcapture/homer.git /usr/src/homer
WORKDIR /usr/src/homer
RUN git submodule init
RUN git submodule update

# Homer5 Post Install.
RUN cp -R homer-ui/* /usr/share/nginx/html/
RUN cp -R homer-api/api /usr/share/nginx/html/
RUN chmod -R 0775 /usr/share/nginx/html/store/dashboard
ADD conf/default-php.template /etc/nginx/sites-available/default-php.template

ADD conf/configuration.php.template /usr/share/nginx/html/api/configuration.php.template
ADD conf/preferences.php.template /usr/share/nginx/html/api/preferences.php.template

# Install Kamailio 4.3.4
RUN git clone git://git.sip-router.org/kamailio -b 4.3.4 /usr/src/kamailio
WORKDIR /usr/src/kamailio
RUN make FLAVOUR=kamailio include_modules="db_mysql db_postgres htable pv rtimer sipcapture siputils sl sqlops textops xlog" cfg
RUN make all
RUN make install

# Kamailiio Post Install.
ADD conf/sipcapture.kamailio.template /usr/local/etc/kamailio/kamailio.cfg.template
ADD sysv/kamailio.init /etc/init.d/kamailio
RUN chmod +x /etc/init.d/kamailio
RUN update-rc.d -f kamailio defaults

# Post Install Configuration.
RUN mkdir -p /usr/share/homer5/sql
ADD sql/homer_databases.sql.template /usr/share/homer5/sql/homer_databases.sql.template
ADD sql/homer_user.sql.template /usr/share/homer5/sql/homer_user.sql.template
ADD sql/schema_configuration.sql.template /usr/share/homer5/sql/schema_configuration.sql.template
ADD sql/schema_data.sql.template /usr/share/homer5/sql/schema_data.sql.template
ADD sql/schema_statistic.sql.template /usr/share/homer5/sql/schema_statistic.sql.template
ADD bin/start-homer /usr/bin/start-homer
RUN chmod +x /usr/bin/start-homer

# Change the workdir to the root home.
WORKDIR /root

# Open the container up to the world.
EXPOSE 80/tcp
EXPOSE 9060/udp

# Start PostgreSQL.
CMD start-homer