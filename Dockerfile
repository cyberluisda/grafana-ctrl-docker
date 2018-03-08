FROM  appropriate/curl:latest

LABEL maintainer='Luis David Barrios <cyberluisda@gmail.com>'

# Install software required
RUN apk --no-cache add bash jq
# WAIT FOR IT
RUN curl \
    -sLko /usr/bin/wait-for-it \
    https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
  && chmod a+x /usr/bin/wait-for-it

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
