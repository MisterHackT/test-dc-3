ARG prod=false
FROM php:8.1-alpine3.14

RUN apk --no-cache update
RUN apk add --no-cache  wkhtmltopdf git bash curl wget sudo gd msmtp perl wget procps shadow libzip libpng libjpeg-turbo libwebp freetype icu

RUN apk add --no-cache --virtual build-essentials \
    icu-dev icu-libs zlib-dev g++ make automake autoconf libzip-dev \
    libpng-dev libwebp-dev libjpeg-turbo-dev freetype-dev && \
    docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install gd && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install intl && \
    docker-php-ext-install opcache && \
    docker-php-ext-install exif && \
    docker-php-ext-install zip && \
    apk del build-essentials && rm -rf /usr/src/php*
#FROM php:8.1-fpm-alpine3.14
#FROM php:8.1-alpine3.14
# take the light version of php-fpm from alpine
#FROM php:8-fpm-alpine3.14

# update the package manager and download bash, curl and wget that we use
#RUN apk --no-cache update
#RUN apk --no-cache add wkhtmltopdf git bash curl wget sudo mbstring gd

# download and install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


# download andd install symfony
#RUN wget https://get.symfony.com/cli/installer -O - | bash && mv /root/.symfony/bin/symfony /usr/local/bin
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.alpine.sh' | sudo -E bash
RUN apk add symfony-cli
# create a group synfusergroup and a user synfuser
RUN addgroup -g 1000 synfusergroup
RUN adduser -u 1000 -G synfusergroup -h /app -D synfuser


# copy the symfony source to the /app dir
COPY --chown=synfuser:synfusergroup . /app


# switch user and home to /app and usersynf
WORKDIR /app
USER synfuser:synfusergroup


# update the composer dependencies
# this command will fail but all dependancies will be downloaded
# To not stop the docker build, we redirect the error to a success
RUN composer install $([[ $prod = 'true' ]] && echo --no-dev --optimize-autoloader || echo) || echo whatever


# the server communicate with the port 8000
EXPOSE 8000
CMD ["symfony", "serve"]