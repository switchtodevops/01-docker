FROM nginx:1.25-alpine

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
# This demonstrates copying a directory with multiple files using COPY
COPY ../app-files/ /usr/share/nginx/html/app-files/

# Why COPY instead of ADD?
# - More predictable (no automatic extraction)
# - Safer (no hidden behaviors)
# - Docker recommended best practice
# - This is the industry standard for copying files

# Note: The new copy-vs-add.html file is included in app-files/

# Create non-root user and set ownership
RUN adduser -D -u 1001 nginx-user && \
    chown -R nginx-user:nginx-user /usr/share/nginx/html && \
    chown -R nginx-user:nginx-user /var/cache/nginx && \
    chown -R nginx-user:nginx-user /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx-user:nginx-user /var/run/nginx.pid

# Switch to non-root user
USER nginx-user

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
#
# Now includes 6 interactive pages:
# - index.html (landing page)
# - docker-build.html
# - docker-run.html
# - docker-tag.html
# - docker-push.html
# - docker-labels.html
# - copy-vs-add.html (NEW!)
###########################################
