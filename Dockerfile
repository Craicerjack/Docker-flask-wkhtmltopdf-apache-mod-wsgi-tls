############################################################
# Dockerfile to build Flask App
############################################################
FROM debian:latest as wkhtml
LABEL maintainer='carlos.tighe@insight-centre.org'
# Install necessities for wkhtmltopdf 
# Download wkhtmltopdf and mv to directory needed for flask_wkhtmltopdf
RUN apt-get update && apt-get install -y curl xz-utils
RUN curl "https://downloads.wkhtmltopdf.org/0.12/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz" -L -o "wkhtmltopdf.tar.xz" 
RUN tar Jxvf wkhtmltopdf.tar.xz
RUN mv wkhtmltox/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf


# Install all the server side stuff, apache, mod-wsgi, python dependencies, and wkhtmltopdf dependencies
FROM debian:latest as server
RUN apt-get update && apt-get install -y apache2 \
    libapache2-mod-wsgi \
    mysql-client \
    default-libmysqlclient-dev \
    build-essential \
    python \
    python-dev\
    python-pip \
    libxrender1 \
    libfontconfig \
    libxtst6 \
    nodejs \
 && apt-get clean \
 && apt-get autoremove \
 && rm -rf /var/lib/apt/lists/*
# Copy over flask requirements and install them
COPY flask_app/requirements.txt /var/www/flask_app/requirements.txt
RUN pip install -r /var/www/flask_app/requirements.txt
# Copy over the conf file for the app (though the tls conf file is loaded as a volume at runtime)
COPY ./flask_app.conf /etc/apache2/sites-available/flask_app.conf
# Enable the conf. I know this is old apache but get what you know working first 
RUN a2dissite 000-default.conf && a2ensite flask_app.conf \
    && a2enmod headers \
    && a2enmod ssl
# I was having OS permissions errors for the tmp files that wkhtmltopdf was creating. I know this isnt ideal but I needed it working
RUN chown -R www-data:root /usr/local/lib/python2.7/dist-packages


# Set up the ember app.
FROM debian:latest as app
COPY ./flask_app /var/www/flask_app
COPY ./client/dist /var/www/html/


# Set the base image
FROM server
LABEL maintainer Carlos Tighe

RUN usermod -a -G root www-data
# Copy over the wkhtmltopdf and the flask_wkhtmltopdf and chown it. 2 commands in 1 reduces docker image size 
COPY --from=wkhtml wkhtmltox wkhtmltox
COPY --from=wkhtml --chown=www-data /usr/local/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf
# Copy over the flask and ember apps and chown at the same time
COPY --from=app --chown=www-data /var/www /var/www

# LINK apache config to docker logs.
# This outputs apache logs (error logs) to docker logs so that docker log <image_name> will show you apache logs
RUN ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/1 /var/log/apache2/error.log

# Expose necessary ports 
EXPOSE 80
EXPOSE 443

WORKDIR /var/www/html/
CMD  /usr/sbin/apache2ctl -D FOREGROUND
