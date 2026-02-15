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


# Copy main index.html to nginx html directory
COPY index.html /usr/share/nginx/html/

# Copy all app-files directory (contains linked HTML pages)
# This demonstrates copying a directory with multiple files using COPY
ADD app-files.tar.gz /usr/share/nginx/html/app-files/
