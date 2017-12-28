# use a ubuntu 16.04 base image
FROM ubuntu:16.04

# set maintainer
LABEL maintainer "shevelevw"
# Set environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8

# Remove PHP and Update the system
RUN apt-get purge -y `dpkg -l | grep php| awk '{print $2}' |tr "\n" " "` && apt-get update && apt-get -y upgrade &&apt-get install -y software-properties-common

# Install curl (Crawler, WS, CrawlerAPI)
RUN apt-get -y install curl libcurl3-gnutls:amd64 libcurl4-openssl-dev:amd64 build-essential unzip supervisor wget inetutils-ping dnsutils

# Install apache, PHP, and supplimentary programs curl
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php && add-apt-repository -y ppa:certbot/certbot && apt-get update && \
    apt-get install -y php5.6 php5.6-cli php-common php-mongo php5.6-common php5.6-curl php5.6-fpm php5.6-json php5.6-mbstring php5.6-mcrypt php5.6-mysql \
    php5.6-opcache php5.6-readline php5.6-xml libapache2-mod-php5.6 apache2

# Install PERL and modules
RUN apt-get -y install perl perl-base perl-modules-5.22 libjson-perl libjson-xs-perl libwww-curl-perl libasterisk-agi-perl libperl5.22:amd64 sox ffmpeg mc jq

# Install Python modules (Crawler, WS)
RUN apt-get -y install python python2.7 python2.7-dev python-numpy python-requests python-scipy python-boto python-mysqldb python-pip 
RUN pip install --upgrade pip
RUN pip install --upgrade google-cloud google-cloud-speech sklearn metaphone asterisk-ami

RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && apt-get -y install google-cloud-sdk
    
# Install cert bot 
RUN apt-get install -y python-certbot-apache

# Install asterisk and modules
RUN apt-get -y install asterisk asterisk-config asterisk-core-sounds-en asterisk-modules asterisk-mysql

# Enable apache mods.
#RUN a2enmod php5.6
#RUN a2enmod rewrite

# Manually set up the apache environment variables
# ENV APACHE_RUN_USER www-data
# ENV APACHE_RUN_GROUP www-data
# ENV APACHE_LOG_DIR /var/log/apache2
# ENV APACHE_LOCK_DIR /var/lock/apache2
# ENV APACHE_PID_FILE /var/run/apache2.pid

COPY ./etc/proj/ /etc/proj/

COPY ./usr/local/proj/ /usr/local/proj/
COPY ./var/lib/asterisk/ /var/lib/asterisk/
RUN chown -R asterisk:asterisk /var/lib/asterisk/

COPY ./etc/asterisk/ /etc/asterisk/


COPY ./webroot_api/ /var/www/crawlerapi/
RUN chown -R asterisk:asterisk /var/www/

COPY ./etc/apache2/ /etc/apache2/
RUN chown -R asterisk:asterisk /etc/apache2/

RUN a2enmod ssl 
RUN a2enmod headers
RUN a2enmod rewrite

COPY ./etc/cron.d/ /etc/cron.d/

# Configure SupervisorD
COPY ./etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /home/clawlerlogs && chmod 777 /home/clawlerlogs
RUN mkdir -p /var/www/html/ws/uploads
RUN mkdir -p /var/www/html/ws/confuploads 
RUN chmod 777 -R /var/www/html/

# set a health check
#HEALTHCHECK --interval=5s \
#            --timeout=5s \
#            CMD curl -f http://127.0.0.1:443 || exit 1

# tell docker what port to expose
EXPOSE 5060/udp
EXPOSE 10000-20000/udp
EXPOSE 443

CMD ["/bin/bash","/startWOH.sh"]
