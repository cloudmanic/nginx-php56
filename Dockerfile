FROM alpine:3.5

MAINTAINER Spicer Mathtews <spicer@cloudmanic.com>

ENV NGINX_VERSION 1.11.10

# Essential pkgs
RUN apk add --no-cache openssh-client git tar php5-fpm curl bash vim

# Essential php magic
RUN apk add --no-cache php5-curl php5-dom php5-gd php5-ctype php5-zip php5-xml php5-iconv php5-mysql php5-sqlite3 php5-mysqli php5-pgsql php5-json php5-phar php5-openssl php5-pdo php5-mcrypt php5-pdo php5-pdo_pgsql php5-pdo_mysql php5-opcache php5-zlib

# Composer
RUN curl --silent --show-error --fail --location \
      --header "Accept: application/tar+gzip, application/x-gzip, application/octet-stream" \
      "https://getcomposer.org/installer" \
    | php5 -- --install-dir=/usr/bin --filename=composer

# Build and install Nginx
RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
	&& CONFIG="\
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--modules-path=/usr/lib/nginx/modules \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/logs/nginx.error.log \
		--http-log-path=/logs/nginx.access.log \
		--pid-path=/tmp/nginx.pid \
		--lock-path=/tmp/nginx.lock \
		--http-client-body-temp-path=/nginx-cache/client_temp \
		--http-proxy-temp-path=/nginx-cache/proxy_temp \
		--http-fastcgi-temp-path=/nginx-cache/fastcgi_temp \
		--http-uwsgi-temp-path=/nginx-cache/uwsgi_temp \
		--http-scgi-temp-path=/nginx-cache/scgi_temp \
		--user=nginx \
		--group=nginx \
		--with-http_ssl_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_sub_module \
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_random_index_module \
		--with-http_secure_link_module \
		--with-http_stub_status_module \
		--with-http_auth_request_module \
		--with-http_xslt_module=dynamic \
		--with-http_image_filter_module=dynamic \
		--with-http_geoip_module=dynamic \
		--with-http_perl_module=dynamic \
		--with-threads \
		--with-stream \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-stream_realip_module \
		--with-stream_geoip_module=dynamic \
		--with-http_slice_module \
		--with-mail \
		--with-mail_ssl_module \
		--with-compat \
		--with-file-aio \
		--with-http_v2_module \
	" \
	#&& addgroup -S nginx \
	#&& adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		make \
		openssl-dev \
		pcre-dev \
		zlib-dev \
		linux-headers \
		curl \
		gnupg \
		libxslt-dev \
		gd-dev \
		geoip-dev \
		perl-dev \
	&& curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
	&& curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEYS" \
	&& gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
	&& rm -r "$GNUPGHOME" nginx.tar.gz.asc \
	&& mkdir -p /usr/src \
	&& tar -zxC /usr/src -f nginx.tar.gz \
	&& rm nginx.tar.gz \
	&& cd /usr/src/nginx-$NGINX_VERSION \
	&& ./configure $CONFIG --with-debug \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& mv objs/nginx objs/nginx-debug \
	&& mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
	&& mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
	&& mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
	&& mv objs/ngx_http_perl_module.so objs/ngx_http_perl_module-debug.so \
	&& mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
	&& ./configure $CONFIG \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& rm -rf /etc/nginx/html/ \
	&& mkdir /etc/nginx/conf.d/ \
	&& mkdir -p /usr/share/nginx/html/ \
	&& install -m644 html/index.html /usr/share/nginx/html/ \
	&& install -m644 html/50x.html /usr/share/nginx/html/ \
	&& install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
	&& install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
	&& install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
	&& install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
	&& install -m755 objs/ngx_http_perl_module-debug.so /usr/lib/nginx/modules/ngx_http_perl_module-debug.so \
	&& install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
	&& ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
	&& strip /usr/sbin/nginx* \
	&& strip /usr/lib/nginx/modules/*.so \
	&& rm -rf /usr/src/nginx-$NGINX_VERSION \
	\
	# Bring in gettext so we can get `envsubst`, then throw
	# the rest away. To do this, we need to install `gettext`
	# then move `envsubst` out of the way so `gettext` can
	# be deleted completely, then move `envsubst` back.
	&& apk add --no-cache --virtual .gettext gettext \
	&& mv /usr/bin/envsubst /tmp/ \
	\
	&& runDeps="$( \
		scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --no-cache --virtual .nginx-rundeps $runDeps \
	&& apk del .build-deps \
	&& apk del .gettext \
	&& mv /tmp/envsubst /usr/local/bin/ 
	
	# forward request and error logs to docker log collector
  ## && ln -sf /dev/stdout /var/log/nginx/access.log \
	## && ln -sf /dev/stderr /var/log/nginx/error.log

# Copy over default configs for nginx.
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-default.conf /etc/nginx/conf.d/default.conf

# Ensure www-data user exists
RUN set -x \
   && deluser xfs \
   && addgroup -g 2000 -S xfs \
   && adduser -u 2000 -D -S -G xfs xfs \
   && addgroup -g 33 -S www-data \
   && adduser -u 33 -D -S -G www-data www-data \
   && addgroup -g 1001 -S deploy \
   && adduser -u 1001 -D -S -G deploy deploy
    
# Setup directory and Set perms for document root.
RUN set -x \
  && mkdir /www \ 
  && mkdir /cache \  
  && mkdir /nginx-cache \ 
  && chown -R www-data:www-data /www \
  && chown -R www-data:www-data /cache \ 
  && chown -R www-data:www-data /logs \
  && chown -R www-data:www-data /nginx-cache    

# Copy over default files
COPY index.php /www/public/index.php
COPY php.ini /etc/php5/php.ini
COPY php-fpm.conf /etc/php5/php-fpm.conf

# Copy the file that gets called when we start
COPY start.sh /start.sh
RUN chmod 700 /start.sh && chown www-data:www-data /start.sh

# Set port we run on because we run as a user.
EXPOSE 8080

# This needs to be at the bottom. 
USER www-data

# Workint directory
WORKDIR /www   

# Start the server
CMD ["/start.sh"]