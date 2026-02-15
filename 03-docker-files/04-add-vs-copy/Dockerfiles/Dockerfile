# syntax=docker/dockerfile:1

###########################################
# Dockerfile demonstrating COPY vs ADD
# This example uses COPY (recommended)
###########################################

FROM nginx:1.25-alpine

# OCI Standard Labels
LABEL org.opencontainers.image.created="2024-02-15T10:00:00Z" \
      org.opencontainers.image.version="2.0.0" \
      org.opencontainers.image.authors="DevOps Navigator <devops@example.com>" \
      org.opencontainers.image.title="DevOps Navigator - Docker Guide" \
      org.opencontainers.image.description="Interactive Docker learning platform with hyperlinks" \
      org.opencontainers.image.vendor="DevOps Navigator" \
      org.opencontainers.image.license="MIT"

# Additional Labels
LABEL app.name="devops-navigator" \
      app.version="2.0.0" \
      app.component="web" \
      app.framework="nginx" \
      demo.instruction="COPY" \
      demo.purpose="Demonstrate COPY instruction for copying HTML files"

# ✅ Using COPY instruction (Recommended)
# COPY is more transparent and predictable than ADD

# Copy main index.html to nginx html directory
COPY index.html /usr/share/nginx/html/

# Copy all app-files directory (contains linked HTML pages)
# This demonstrates copying a directory with multiple files
COPY ../app-files/ /usr/share/nginx/html/app-files/

# Alternative: You could also copy specific files one by one
# COPY ../app-files/docker-build.html /usr/share/nginx/html/app-files/
# COPY ../app-files/docker-run.html /usr/share/nginx/html/app-files/
# COPY ../app-files/docker-tag.html /usr/share/nginx/html/app-files/
# COPY ../app-files/docker-push.html /usr/share/nginx/html/app-files/
# COPY ../app-files/docker-labels.html /usr/share/nginx/html/app-files/

# Create non-root user and set ownership
RUN adduser -D -u 1001 -g 'nginx' nginx && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Switch to non-root user
USER nginx

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]

###########################################
# Build Instructions:
# cd /root/switchtodevops/01-docker/03-docker-files/04-add-vs-copy/Dockerfiles
# docker build -t devops-navigator:v2 .
#
# Run Instructions:
# docker run -d -p 8080:80 --name devops-nav devops-navigator:v2
#
# Access: http://localhost:8080
#
# View Labels:
# docker inspect devops-navigator:v2 | jq '.[0].Config.Labels'
###########################################
