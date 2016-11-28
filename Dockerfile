FROM php:5.6.28-cli

MAINTAINER Aleksey Kharlamov <aleksei.programmist@gmail.com>

# Install composer and put binary into $PATH
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/ \
    && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer


RUN docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd
RUN docker-php-ext-configure mysqli --with-mysqli=mysqlnd

RUN docker-php-ext-install mbstring bcmath
RUN curl -O https://xdebug.org/files/xdebug-2.4.0.tgz
RUN tar -xzf xdebug-2.4.0.tgz \
    && cd xdebug-2.4.0/ \
    && phpize \
    && ./configure --enable-xdebug \
    && make \
    && echo 'zend_extension="/xdebug-2.4.0/modules/xdebug.so"' > /usr/local/etc/php/conf.d/20-xdebug.ini

RUN apt-get update
RUN apt-get install -y libmcrypt-dev
RUN docker-php-ext-install mcrypt

RUN apt-get install zlib1g-dev
RUN docker-php-ext-install zip

# Install intl
RUN apt-get install -y libicu-dev
RUN pecl install intl
RUN docker-php-ext-install intl

# Install mongodb
RUN apt-get install -y libssl-dev && \
    pecl install mongodb && \
    echo 'extension=mongodb.so' > /usr/local/etc/php/conf.d/20-mongodb.ini


# Install mysql
RUN apt-get install -y apt-utils
RUN { \
        echo debconf debconf/frontend select Noninteractive; \
        echo mysql-community-server mysql-community-server/data-dir \
            select ''; \
        echo mysql-community-server mysql-community-server/root-pass \
            password 'docker'; \
        echo mysql-community-server mysql-community-server/re-root-pass \
            password 'docker'; \
        echo mysql-community-server mysql-community-server/remove-test-db \
            select true; \
    } | debconf-set-selections \
    && apt-get install -y mysql-server-5.5

# install git
RUN apt-get install -y git

RUN mkdir /root/.ssh/
RUN  echo "    IdentityFile /root/.ssh/id_rsa" >> /etc/ssh/ssh_config
RUN  echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config

# Memcached
RUN apt-get install -yqq memcached libmemcached-dev && \
    git clone https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached \
      && cd /usr/src/php/ext/memcached \
      && docker-php-ext-configure memcached \
      && docker-php-ext-install memcached

COPY ./entrypoint.sh /
RUN /bin/bash /entrypoint.sh