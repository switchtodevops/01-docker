# 🚀 Quick Start Guide - Custom Nginx Container

## ⚡ Fastest Way to Get Started

### Option 1: Automated Script (Recommended)

```bash
# Run the automated build and run script
./build-and-run.sh
```

That's it! The script will:
- ✅ Build the Docker image
- ✅ Run the container
- ✅ Test the deployment
- ✅ Display access information

### Option 2: Manual Commands

```bash
# 1. Build the image
docker build -t custom-nginx:1.29.5 .

# 2. Run the container
docker run -d -p 8080:80 --name my-nginx custom-nginx:1.29.5

# 3. Access it
open http://localhost:8080
```

## 🔍 Verify Installation

```bash
# Run tests
./test.sh
```

## 🌐 Access Your Server

**URL:** http://localhost:8080

You should see:
- Light blue background ✨
- Nginx version: 1.29.5 📊
- Server status: Running 🟢
- Real-time clock 🕐

## 📦 What You Get

| File | Purpose |
|------|---------|
| `index.html` | Beautiful web page with light blue background |
| `Dockerfile` | Docker image configuration |
| `build-and-run.sh` | Automated build and deployment |
| `test.sh` | Automated testing script |
| `README.md` | Complete documentation |

## 🎨 Features

- **Light Blue Background** - Beautiful `#ADD8E6` color
- **Version Display** - Shows Nginx 1.29.5
- **Responsive Design** - Works on all devices
- **Live Status** - Real-time server status
- **Modern UI** - Clean, professional interface
- **Docker Info** - Complete container details

## 📝 Common Commands

```bash
# View running containers
docker ps

# View logs
docker logs my-nginx

# Stop container
docker stop my-nginx

# Start container
docker start my-nginx

# Remove container
docker rm -f my-nginx

# Enter container shell
docker exec -it my-nginx sh

# Check Nginx version
docker exec my-nginx nginx -v
```

## 🔄 Update and Rebuild

```bash
# Edit index.html with your changes
nano index.html

# Stop and remove old container
docker stop my-nginx && docker rm my-nginx

# Rebuild and run
./build-and-run.sh
```

## 🛠️ Customize

### Change Port

Edit `build-and-run.sh`:
```bash
HOST_PORT="8080"  # Change to your desired port
```

### Change Background Color

Edit `index.html`:
```css
body {
    background: #ADD8E6; /* Change this hex code */
}
```

**Popular Colors:**
- Light Blue: `#ADD8E6` (current)
- Sky Blue: `#87CEEB`
- Powder Blue: `#B0E0E6`
- Light Cyan: `#E0FFFF`
- Lavender: `#E6E6FA`

### Change Version Text

Edit `index.html`:
```html
<div class="version-badge">
    Version: 1.29.5  <!-- Change this -->
</div>
```

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Use different port
docker run -d -p 8081:80 --name my-nginx custom-nginx:1.29.5
```

### Container Won't Start
```bash
# Check logs
docker logs my-nginx

# Verify image exists
docker images | grep custom-nginx
```

### Can't Access Website
```bash
# Check if container is running
docker ps

# Check if port is listening
netstat -an | grep 8080

# Test from command line
curl http://localhost:8080
```

## 📊 System Requirements

- Docker installed and running
- Port 8080 available (or choose different port)
- ~50 MB disk space for image
- Internet connection for initial build

## ✅ Success Indicators

You know it's working when:
- ✅ Container status shows "Up"
- ✅ Port 8080 is listening
- ✅ Browser shows light blue page
- ✅ Version "1.29.5" is displayed
- ✅ No errors in logs

## 🎯 Next Steps

1. ✅ Build and run the container
2. ✅ Access http://localhost:8080
3. ✅ Run tests with `./test.sh`
4. ✅ Customize the page
5. ✅ Deploy to production

## 💡 Tips

- Use `./build-and-run.sh` for quick rebuilds
- Check logs with `docker logs -f my-nginx`
- Test changes locally before deploying
- Keep the Dockerfile simple and clean
- Document any customizations

## 🆘 Need Help?

1. Check `README.md` for detailed documentation
2. Run `./test.sh` to diagnose issues
3. View logs: `docker logs my-nginx`
4. Verify Docker is running: `docker --version`

---

## 🎉 You're All Set!

Your custom Nginx container with light blue background is ready to go!

**Access it now:** http://localhost:8080

Enjoy! 🚀
