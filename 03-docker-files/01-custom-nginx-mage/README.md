# Custom Nginx Docker Image

This directory contains a custom Nginx Docker image that displays the server version with a beautiful light blue interface.

## 📁 Files

- `Dockerfile` - Docker configuration file
- `index.html` - Custom HTML page with light blue background showing Nginx version
- `README.md` - This file

## 🚀 Quick Start

### Build the Image

```bash
# Navigate to the directory
cd /root/switchtodevops/01-docker/03-docker-files/01-custom-nginx-mage

# Build the Docker image
docker build -t custom-nginx:1.29.5 .
```

### Run the Container

```bash
# Run the container
docker run -d -p 8080:80 --name my-nginx custom-nginx:1.29.5

# Or run in foreground (to see logs)
docker run -p 8080:80 --name my-nginx custom-nginx:1.29.5
```

### Access the Website

Open your browser and visit:
```
http://localhost:8080
```

## 🎨 Features

The custom index.html page includes:

- ✨ **Light Blue Background** - Beautiful gradient background
- 📊 **Nginx Version Display** - Shows version 1.29.5
- 🐳 **Docker Image Info** - Displays the base image details
- 🏔️ **Alpine Linux** - Running on lightweight Alpine
- ⚡ **Live Status** - Animated status indicator
- 🕐 **Real-time Clock** - Shows current date and time
- 📱 **Responsive Design** - Works on mobile and desktop

## 🔧 Docker Commands

### View Running Containers
```bash
docker ps
```

### View Logs
```bash
docker logs my-nginx
```

### Stop Container
```bash
docker stop my-nginx
```

### Start Container Again
```bash
docker start my-nginx
```

### Remove Container
```bash
docker rm -f my-nginx
```

### Remove Image
```bash
docker rmi custom-nginx:1.29.5
```

## 🛠️ Dockerfile Details

```dockerfile
FROM nginx:1.29.5-alpine-perl
```

**Base Image Components:**
- `nginx:1.29.5` - Nginx web server version
- `alpine` - Lightweight Alpine Linux base (~5MB)
- `perl` - Perl scripting support

## 📊 Image Information

| Property | Value |
|----------|-------|
| Base Image | nginx:1.29.5-alpine-perl |
| Nginx Version | 1.29.5 |
| OS | Alpine Linux |
| Exposed Port | 80 |
| Size | ~40-50 MB |

## 🔍 Verify Nginx Version

You can verify the Nginx version inside the container:

```bash
# Execute command in running container
docker exec my-nginx nginx -v

# Or enter the container
docker exec -it my-nginx sh
nginx -v
exit
```

## 🌐 Port Mapping

The Dockerfile exposes port 80 internally. When running the container:

- `-p 8080:80` maps host port 8080 to container port 80
- Change `8080` to any available port on your host

Examples:
```bash
# Use port 80 (requires sudo/admin)
docker run -d -p 80:80 --name my-nginx custom-nginx:1.29.5

# Use port 3000
docker run -d -p 3000:80 --name my-nginx custom-nginx:1.29.5

# Use port 9000
docker run -d -p 9000:80 --name my-nginx custom-nginx:1.29.5
```

## 🔄 Rebuild After Changes

If you modify the `index.html`:

```bash
# Stop and remove old container
docker stop my-nginx && docker rm my-nginx

# Rebuild the image
docker build -t custom-nginx:1.29.5 .

# Run new container
docker run -d -p 8080:80 --name my-nginx custom-nginx:1.29.5
```

## 📝 Customization

### Change the Version Display

Edit `index.html` and update the version number:

```html
<div class="version-badge">
    Version: 1.29.5  <!-- Change this -->
</div>
```

### Change Background Color

Edit the CSS in `index.html`:

```css
body {
    background: #ADD8E6; /* Light Blue - Change this hex code */
}
```

**Color Suggestions:**
- Light Blue: `#ADD8E6`
- Sky Blue: `#87CEEB`
- Powder Blue: `#B0E0E6`
- Light Steel Blue: `#B0C4DE`
- Alice Blue: `#F0F8FF`

## 🐛 Troubleshooting

### Port Already in Use

If you get "port is already allocated" error:

```bash
# Check what's using the port
lsof -i :8080

# Use a different port
docker run -d -p 8081:80 --name my-nginx custom-nginx:1.29.5
```

### Container Name Conflict

If container name exists:

```bash
# Remove existing container
docker rm -f my-nginx

# Or use a different name
docker run -d -p 8080:80 --name my-nginx-2 custom-nginx:1.29.5
```

### Image Not Found

Make sure you built the image first:

```bash
# List images
docker images | grep custom-nginx

# Build if missing
docker build -t custom-nginx:1.29.5 .
```

## 📚 Additional Resources

- [Nginx Official Documentation](https://nginx.org/en/docs/)
- [Docker Official Documentation](https://docs.docker.com/)
- [Alpine Linux](https://alpinelinux.org/)

## ✅ Testing Checklist

- [ ] Image builds successfully
- [ ] Container starts without errors
- [ ] Website accessible at http://localhost:8080
- [ ] Nginx version displays correctly
- [ ] Light blue background shows properly
- [ ] Page is responsive on mobile
- [ ] No console errors in browser

---

**Created:** February 2026  
**Nginx Version:** 1.29.5  
**Base Image:** nginx:1.29.5-alpine-perl
