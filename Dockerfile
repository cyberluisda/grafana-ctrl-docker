FROM  appropriate/curl:latest

LABEL maintainer='Luis David Barrios <cyberluisda@gmail.com>'

# Install software required
RUN apk --no-cache add bash jq
# DOCKERIZE
ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Environmet variables (used for config)
ENV GRAFANA_ENDPOINT "http://grafana:3000"
ENV GRAFANA_AUTH_BEARER ""
ENV GRAFANA_AUTH_USERPASSWD "admin:admin"
ENV GRAFANA_WAIT_TIMEOUT ""

# Add config file
ADD files/entrypoint.sh /
RUN chmod a+x /entrypoint.sh

# Set entry point and default options
ENTRYPOINT  ["/entrypoint.sh"]
CMD ["--help"]
