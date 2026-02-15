# QUICK START - COPY vs ADD Demo

> Get the DevOps Navigator demo running in 60 seconds!

## 🚀 One-Command Start

```bash
cd /root/switchtodevops/01-docker/03-docker-files/04-add-vs-copy && ./build-and-run.sh
```

## 📋 Manual Steps (If Script Doesn't Work)

### 1. Navigate to Project

```bash
cd /root/switchtodevops/01-docker/03-docker-files/04-add-vs-copy
```

### 2. Verify Files

```bash
# Should show 6 HTML files
ls -1 app-files/
```

Expected output:
```
copy-vs-add.html    ⭐ NEW!
docker-build.html
docker-labels.html
docker-push.html
docker-run.html
docker-tag.html
```

### 3. Navigate to Dockerfiles

```bash
cd Dockerfiles
```

### 4. Build Image

```bash
docker build -t devops-navigator:v2 .
```

### 5. Run Container

```bash
docker run -d -p 8080:80 --name devops-nav devops-navigator:v2
```

### 6. Access Website

Open in browser: **http://localhost:8080**

## ✅ Verification

### Check Container Status

```bash
docker ps | grep devops-nav
```

Should show: `devops-nav` running

### Test Main Page

```bash
curl -I http://localhost:8080
```

Should show: `HTTP/1.1 200 OK`

### Verify All Files Copied

```bash
docker exec devops-nav ls /usr/share/nginx/html/app-files/
```

Should list 6 HTML files including **copy-vs-add.html**

## 🌐 Access Points

| Page | URL | Status |
|------|-----|--------|
| **Home** | http://localhost:8080 | Landing |
| **Docker Build** | http://localhost:8080/app-files/docker-build.html | Guide |
| **Docker Run** | http://localhost:8080/app-files/docker-run.html | Guide |
| **Docker Tag** | http://localhost:8080/app-files/docker-tag.html | Guide |
| **Docker Push** | http://localhost:8080/app-files/docker-push.html | Guide |
| **Docker Labels** | http://localhost:8080/app-files/docker-labels.html | Guide |
| **COPY vs ADD** | http://localhost:8080/app-files/copy-vs-add.html | ⭐ NEW! |

## 🎯 What to Click

1. Visit **http://localhost:8080**
2. See 6 colored cards
3. Click **COPY vs ADD** (the new one!)
4. Read the comparison guide
5. Use "Back to Home" to return
6. Explore other topics

## 🔧 Common Commands

```bash
# View logs
docker logs devops-nav

# Stop container
docker stop devops-nav

# Start again
docker start devops-nav

# Remove completely
docker rm -f devops-nav

# Rebuild (if you make changes)
docker build -t devops-navigator:v2 .
docker rm -f devops-nav
docker run -d -p 8080:80 --name devops-nav devops-navigator:v2
```

## 🏷️ View Labels

```bash
# All labels
docker inspect devops-nav | jq '.[0].Config.Labels'

# Demo instruction
docker inspect devops-nav | jq -r '.[0].Config.Labels["demo.instruction"]'
# Output: COPY
```

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Use different port
docker run -d -p 8081:80 --name devops-nav devops-navigator:v2
# Access: http://localhost:8081
```

### 404 Not Found

```bash
# Rebuild to include latest changes
docker rm -f devops-nav
cd /root/switchtodevops/01-docker/03-docker-files/04-add-vs-copy/Dockerfiles
docker build --no-cache -t devops-navigator:v2 .
docker run -d -p 8080:80 --name devops-nav devops-navigator:v2
```

### Container Exits Immediately

```bash
# Check logs
docker logs devops-nav

# Common fix: Rebuild without cache
docker build --no-cache -t devops-navigator:v2 .
```

## 📊 What This Demo Shows

### COPY Instruction (Industry Standard)

```dockerfile
# ✅ Main page
COPY index.html /usr/share/nginx/html/

# ✅ All linked pages (6 files)
COPY ../app-files/ /usr/share/nginx/html/app-files/
```

### Why COPY, Not ADD?

- ✅ **More predictable** - No surprises
- ✅ **Safer** - No automatic extraction
- ✅ **Recommended** - Docker best practice
- ✅ **Standard** - Used in 95% of cases

### When to Use ADD

- Only for **tar extraction**
- Example: `ADD vendor.tar.gz /opt/`

## 🎓 Key Takeaways

1. **COPY** is the default choice (used in this project)
2. **ADD** only for tar files
3. Never use ADD for URLs
4. This demo has **7 pages total** (1 main + 6 linked)
5. All pages copied using **COPY instruction**
6. New **COPY vs ADD** page explains everything!

## 🆕 What's New

### Just Added

- ✨ **New Page:** `copy-vs-add.html` (799 lines!)
- ✨ **New Card:** Added to landing page
- ✨ **New Content:** Complete COPY vs ADD comparison
- ✨ **New Examples:** Real-world scenarios
- ✨ **New Design:** Color-coded comparison cards

### Features

- 📊 Comparison table
- 🎨 Green/Orange coding (COPY/ADD)
- 💡 Tips and warnings
- ✅ Best practices
- ⚠️ Common mistakes
- 📋 Quick reference

## ⚡ Super Quick Reference

```bash
# Build + Run + Open (3 commands)
cd /root/switchtodevops/01-docker/03-docker-files/04-add-vs-copy/Dockerfiles
docker build -t devops-navigator:v2 . && docker run -d -p 8080:80 --name devops-nav devops-navigator:v2
open http://localhost:8080  # or: curl http://localhost:8080
```

## 📚 Full Documentation

- **Complete Guide:** [README.md](./README.md) - Full documentation
- **Technical Details:** [add-vs-copy.md](./add-vs-copy.md) - 1,500+ lines
- **Automated Script:** [build-and-run.sh](./build-and-run.sh) - One command start

## ✅ Success Indicators

You've successfully started the demo if you see:

- ✅ Container named `devops-nav` is running
- ✅ Port 8080 is listening
- ✅ Main page loads in browser
- ✅ All 6 links work (including new COPY vs ADD)
- ✅ Back buttons return to home
- ✅ No errors in logs

## 🎯 Next Steps

1. ✅ **Build and run** (done with script)
2. ✅ **Visit landing page** at http://localhost:8080
3. ✅ **Click COPY vs ADD** (the new page!)
4. ✅ **Read comparison guide** with examples
5. ✅ **Explore other topics** (Build, Run, Tag, Push, Labels)
6. ✅ **Try Dockerfile editing** and rebuild
7. ✅ **Push to your registry** (optional)

## 🎊 You're Ready!

The demo is **production-ready** and demonstrates:

- ✅ COPY instruction (not ADD)
- ✅ Multi-file Docker projects
- ✅ Hyperlinked web pages
- ✅ OCI standard labels
- ✅ Security best practices
- ✅ Nginx as web server
- ✅ Non-root user
- ✅ Health checks

**Start learning now:** http://localhost:8080

---

**Time to Complete:** 60 seconds  
**Total Pages:** 7 HTML files  
**Instruction Used:** COPY ✅  
**Industry Standard:** Yes ✅  

*Built with ❤️ for DevOps Engineers*
