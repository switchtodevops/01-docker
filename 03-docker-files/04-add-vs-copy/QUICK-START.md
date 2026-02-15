# 🚀 Quick Start - DevOps Navigator COPY Demo

> Get up and running in 30 seconds!

## ⚡ Fastest Way

```bash
cd /root/switchtodevops/01-docker/03-docker-files/04-add-vs-copy

./build-and-run.sh
```

**Then open:** http://localhost:8080

---

## 📋 What You Get

### Landing Page with Hyperlinks

```
DevOps Navigator
├── 🐳 Docker Build    → /app-files/docker-build.html
├── ▶️ Docker Run      → /app-files/docker-run.html
├── 🏷️ Docker Tag      → /app-files/docker-tag.html
├── 📤 Docker Push     → /app-files/docker-push.html
└── 🏷️ Docker Labels   → /app-files/docker-labels.html
```

### Interactive Learning

- **Click each card** to learn about that Docker topic
- **Back button** on each page to return home
- **Comprehensive guides** with examples and best practices
- **Beautiful UI** with color-coded themes

---

## 🎯 What This Demonstrates

### COPY Instruction

```dockerfile
# Copy main page
COPY index.html /usr/share/nginx/html/

# Copy all linked pages
COPY ../app-files/ /usr/share/nginx/html/app-files/
```

### Why COPY?

✅ **Predictable** - Does exactly what you expect  
✅ **Safe** - No hidden behaviors  
✅ **Recommended** - Docker best practice  
✅ **This Demo** - All files copied with COPY  

---

## 🛠️ Manual Steps

If you prefer to run commands manually:

### Step 1: Navigate

```bash
cd /root/switchtodevops/01-docker/03-docker-files/04-add-vs-copy/Dockerfiles
```

### Step 2: Build

```bash
docker build -t devops-navigator:v2 .
```

### Step 3: Run

```bash
docker run -d -p 8080:80 --name devops-nav devops-navigator:v2
```

### Step 4: Access

```
http://localhost:8080
```

---

## 📁 File Structure

```
04-add-vs-copy/
│
├── Dockerfiles/
│   ├── Dockerfile          ← Uses COPY instruction
│   └── index.html          ← Landing page with links
│
├── app-files/              ← Linked HTML pages
│   ├── docker-build.html   
│   ├── docker-run.html
│   ├── docker-tag.html
│   ├── docker-push.html
│   └── docker-labels.html
│
├── build-and-run.sh        ← Automated script ⚡
├── README.md               ← Full documentation
├── QUICK-START.md          ← This file
└── add-vs-copy.md          ← Complete COPY vs ADD guide
```

---

## ✅ Verify Everything Works

### Test 1: Container Running

```bash
docker ps | grep devops-nav
```

Expected: Container status "Up"

### Test 2: Website Loads

```bash
curl http://localhost:8080
```

Expected: HTML content returned

### Test 3: Files Copied

```bash
docker exec devops-nav ls /usr/share/nginx/html/app-files/
```

Expected:
```
docker-build.html
docker-run.html
docker-tag.html
docker-push.html
docker-labels.html
```

### Test 4: Labels Present

```bash
docker inspect devops-navigator:v2 | grep -i "demo.instruction"
```

Expected: `"demo.instruction": "COPY"`

---

## 🎨 Color Themes

Each page has a unique color theme:

- **Landing Page**: Purple gradient (`#667eea` → `#764ba2`)
- **Docker Build**: Blue gradient (`#667eea` → `#764ba2`)
- **Docker Run**: Green gradient (`#48bb78` → `#38a169`)
- **Docker Tag**: Orange gradient (`#ed8936` → `#dd6b20`)
- **Docker Push**: Red gradient (`#e53e3e` → `#c53030`)
- **Docker Labels**: Purple gradient (`#805ad5` → `#6b46c1`)

---

## 🔧 Common Commands

```bash
# View logs
docker logs devops-nav

# Stop
docker stop devops-nav

# Start
docker start devops-nav

# Restart
docker restart devops-nav

# Remove
docker rm -f devops-nav

# Remove image
docker rmi devops-navigator:v2

# View labels
docker inspect devops-navigator:v2 | jq '.[0].Config.Labels'
```

---

## 🐛 Quick Troubleshooting

### Port 8080 in use?

```bash
docker run -d -p 8081:80 --name devops-nav devops-navigator:v2
# Access at http://localhost:8081
```

### Container name conflict?

```bash
docker rm -f devops-nav
./build-and-run.sh
```

### Build error?

```bash
# Check you're in the right directory
pwd
# Should be: .../04-add-vs-copy/Dockerfiles

# Or use the script from parent directory
cd /root/switchtodevops/01-docker/03-docker-files/04-add-vs-copy
./build-and-run.sh
```

---

## 📚 Next Steps

1. ✅ **Explore** - Click all the cards and learn each topic
2. ✅ **Understand** - Read the COPY instructions in Dockerfile
3. ✅ **Compare** - Read [add-vs-copy.md](./add-vs-copy.md) for full comparison
4. ✅ **Modify** - Change HTML files and rebuild
5. ✅ **Share** - Push to Docker Hub and share with team

---

## 🎓 Learning Points

### This Demo Uses

- ✅ **COPY** instruction (not ADD)
- ✅ **Multi-file structure** with hyperlinks
- ✅ **OCI standard labels**
- ✅ **Non-root user** (nginx)
- ✅ **Health checks**
- ✅ **Best practices**

### You'll Learn

- ✅ How COPY works
- ✅ When to use COPY vs ADD
- ✅ How to structure web apps in Docker
- ✅ How to add metadata with labels
- ✅ Docker Build, Run, Tag, Push, Labels

---

## 🎯 Summary

| Item | Details |
|------|---------|
| **Image Name** | devops-navigator:v2 |
| **Container Name** | devops-nav |
| **Port** | 8080 → 80 |
| **Access URL** | http://localhost:8080 |
| **Instruction** | COPY (demonstrated) |
| **Files** | 1 main + 5 linked pages |
| **Build Time** | ~10 seconds |

---

## 🌟 Features

- 🎨 **Beautiful UI** - Modern, responsive design
- 🔗 **Hyperlinks** - Click cards to navigate
- 📱 **Mobile Ready** - Works on all devices
- 🚀 **Fast** - Nginx serves static files
- 🔒 **Secure** - Runs as non-root user
- 🏷️ **Labeled** - Full OCI metadata
- ✅ **Tested** - Health checks included

---

**Ready?** Run this now:

```bash
cd /root/switchtodevops/01-docker/03-docker-files/04-add-vs-copy && ./build-and-run.sh
```

**Then visit:** http://localhost:8080

---

*Built with ❤️ for DevOps Engineers*
