FROM nginx:1.25-alpine

ADD https://github.com/switchtodevops/docker-add-fetch-url-demo/archive/refs/tags/v2.0.0.tar.gz /tmp/
RUN mkdir -p /tmp/src \
    && tar -xzf /tmp/v2.0.0.tar.gz -C /tmp/src \
    && cp -r /tmp/src/docker-add-fetch-url-demo-2.0.0/* /usr/share/nginx/html/ \
    && rm -rf /tmp/src \
    && rm -rf /tmp/v2.0.0.tar.gz