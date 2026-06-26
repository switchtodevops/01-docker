# Declare ARG for build-time variable
ARG NGINX_VERSION=1.28.2

# Use ARG in the Dockerfile
FROM nginx:${NGINX_VERSION}-alpine

LABEL org.opencontainers.image.version="${NGINX_VERSION}" \
      org.opencontainers.image.title="DevOps Navigator - Nginx" \
      org.opencontainers.image.description="Nginx web server" \
      org.opencontainers.image.vendor="DevOps Navigator" \
      org.opencontainers.image.license="MIT" \
      org.opencontainers.image.source="https://github.com/DevOps-Navigator/nginx-image" \
      org.opencontainers.image.documentation="https://github.com/DevOps-Navigator/nginx-image/blob/main/README.md" \
      org.opencontainers.image.authors="DevOps Navigator <switchtodevops@gmail.com>" \
      org.opencontainers.image.created="2026-02-19" \
      org.opencontainers.image.revision="1234567890" \
      org.opencontainers.image.url="https://github.com/DevOps-Navigator/nginx-image" \
      org.opencontainers.image.title="DevOps Navigator - Nginx" \
      org.opencontainers.image.description="Nginx web server"

COPY index.html /usr/share/nginx/html
