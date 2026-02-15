# ADD vs COPY Demo - DevOps Navigator

> Interactive Docker learning platform demonstrating COPY instruction with hyperlinked HTML pages

## 📁 Project Structure

```
04-add-vs-copy/
├── Dockerfiles/
│   ├── Dockerfile          # Main Dockerfile using COPY instruction
│   └── index.html          # Landing page with hyperlinks
├── app-files/
│   ├── docker-build.html   # Docker Build guide
│   ├── docker-run.html     # Docker Run guide
│   ├── docker-tag.html     # Docker Tag guide
│   ├── docker-push.html    # Docker Push guide
│   └── docker-labels.html  # Docker Labels guide
├── add-vs-copy.md          # Complete guide on ADD vs COPY
└── README.md               # This file
```

## 🎯 What This Demo Shows

### COPY Instruction Usage

This project demonstrates the **COPY instruction** which is the **recommended way** to copy files into Docker images:

```dockerfile
# ✅ Using COPY (Recommended)
COPY index.html /usr/share/nginx/html/
COPY ../app-files/ /usr/share/nginx/html/app-files/
```

### Why COPY Instead of ADD?

1. **More Predictable** - Does exactly what you expect
2. **More Transparent** - No hidden behaviors
3. **Safer** - No automatic extraction or URL downloads
4. **Industry Standard** - Recommended by Docker best practices

## 🚀 Quick Start

### Prerequisites

- Docker installed and running
- Access to terminal/command line

### Build the Image

```bash
# Navigate to Dockerfiles directory
cd /root/switchtodevops/01-docker/03-docker-files/04-add-vs-copy/Dockerfiles

# Build the image
docker build -t devops-navigator:v2 .
```

### Run the Container

```bash
# Run in detached mode
docker run -d -p 8080:80 --name devops-nav devops-navigator:v2
```

### Access the Website

Open your browser and visit:
```
http://localhost:8080
```

## 🎨 Features

### Landing Page (index.html)

- **Responsive Design** - Works on desktop and mobile
- **Interactive Cards** - Click to learn about each topic
- **Modern UI** - Beautiful gradient backgrounds
- **Navigation** - Easy access to all topics

### Topics Covered

1. **🐳 Docker Build** - Learn to build Docker images
   - Basic syntax and commands
   - Multi-stage builds
   - Build arguments
   - Best practices

2. **▶️ Docker Run** - Run containers from images
   - Port mapping
   - Environment variables
   - Volume mounts
   - Restart policies

3. **🏷️ Docker Tag** - Tag images for organization
   - Semantic versioning
   - Multiple tags
   - Registry tagging
   - Tagging strategies

4. **📤 Docker Push** - Push images to registries
   - Docker Hub workflow
   - Private registries
   - CI/CD integration
   - Verification

5. **🏷️ Docker Labels** - Add metadata to images
   - OCI standard labels
   - Dynamic labels
   - Filtering by labels
   - Production use cases

## 🔍 Understanding the Dockerfile

### COPY Instructions Explained

```dockerfile
# Copy single file
COPY index.html /usr/share/nginx/html/

# Copy entire directory
COPY ../app-files/ /usr/share/nginx/html/app-files/
```

**What This Does:**
1. Copies the main `index.html` to nginx's html directory
2. Copies all HTML files from `app-files/` directory
3. Creates the directory structure in the container
4. Preserves file permissions and metadata

### Labels Included

The image includes comprehensive OCI standard labels:

```dockerfile
LABEL org.opencontainers.image.version="2.0.0"
LABEL org.opencontainers.image.authors="DevOps Navigator"
LABEL org.opencontainers.image.title="DevOps Navigator - Docker Guide"
LABEL demo.instruction="COPY"
LABEL demo.purpose="Demonstrate COPY instruction"
```

## 📊 View Image Labels

```bash
# View all labels
docker inspect devops-navigator:v2 | jq '.[0].Config.Labels'

# View specific label
docker inspect devops-navigator:v2 | jq -r '.[0].Config.Labels["demo.instruction"]'

# List as key=value
docker inspect devops-navigator:v2 | \
  jq -r '.[0].Config.Labels | to_entries[] | "\(.key)=\(.value)"'
```

## 🛠️ Docker Commands

### Build Commands

```bash
# Basic build
docker build -t devops-navigator:v2 .

# Build with no cache
docker build --no-cache -t devops-navigator:v2 .

# Build and tag multiple versions
docker build -t devops-navigator:v2 -t devops-navigator:latest .
```

### Run Commands

```bash
# Run in background
docker run -d -p 8080:80 --name devops-nav devops-navigator:v2

# Run with different port
docker run -d -p 3000:80 --name devops-nav devops-navigator:v2

# Run and remove on stop
docker run --rm -p 8080:80 devops-navigator:v2

# Run with restart policy
docker run -d -p 8080:80 --restart unless-stopped --name devops-nav devops-navigator:v2
```

### Management Commands

```bash
# View running containers
docker ps

# View logs
docker logs devops-nav

# Follow logs
docker logs -f devops-nav

# Stop container
docker stop devops-nav

# Start container
docker start devops-nav

# Remove container
docker rm -f devops-nav

# Remove image
docker rmi devops-navigator:v2
```

### Inspect Commands

```bash
# Inspect container
docker inspect devops-nav

# View labels
docker inspect devops-navigator:v2 | jq '.[0].Config.Labels'

# View exposed ports
docker inspect devops-navigator:v2 | jq '.[0].Config.ExposedPorts'

# View health check
docker inspect devops-nav | jq '.[0].State.Health'
```

## 🔄 COPY vs ADD Comparison

### When to Use COPY (This Demo)

```dockerfile
# ✅ Copying HTML files (this project)
COPY index.html /usr/share/nginx/html/
COPY app-files/ /usr/share/nginx/html/app-files/

# ✅ Copying application code
COPY src/ /app/src/

# ✅ Copying configuration files
COPY nginx.conf /etc/nginx/

# ✅ Copying from build stages
COPY --from=builder /app/dist /app/dist
```

### When to Use ADD

```dockerfile
# ✅ Extracting tar archives (valid use case)
ADD myapp-v1.0.0.tar.gz /opt/app/

# ⚠️ Downloading from URL (not recommended)
ADD https://example.com/file.tar.gz /tmp/
# Better: Use RUN with curl/wget
```

### Key Differences

| Feature | COPY (This Demo) | ADD |
|---------|-----------------|-----|
| Copy local files | ✅ Yes | ✅ Yes |
| Copy directories | ✅ Yes | ✅ Yes |
| Auto-extract tar | ❌ No | ✅ Yes |
| Download URLs | ❌ No | ✅ Yes |
| Recommended | ✅ Yes | ⚠️ Only for tar |
| This Project | ✅ Used | ❌ Not used |

## 📝 Testing the Demo

### Test 1: Verify Build

```bash
# Build should complete without errors
docker build -t devops-navigator:v2 .

# Expected output:
# Successfully built abc123
# Successfully tagged devops-navigator:v2
```

### Test 2: Verify Container Runs

```bash
# Start container
docker run -d -p 8080:80 --name devops-nav devops-navigator:v2

# Check if running
docker ps | grep devops-nav

# Expected: Container status should be "Up"
```

### Test 3: Verify Website Loads

```bash
# Test with curl
curl http://localhost:8080

# Expected: Should return HTML content

# Test with browser
# Visit: http://localhost:8080
# Expected: Should see DevOps Navigator landing page
```

### Test 4: Verify Hyperlinks Work

Click each card on the landing page:
- ✅ Docker Build → Should load docker-build.html
- ✅ Docker Run → Should load docker-run.html
- ✅ Docker Tag → Should load docker-tag.html
- ✅ Docker Push → Should load docker-push.html
- ✅ Docker Labels → Should load docker-labels.html

### Test 5: Verify Labels

```bash
# Check if COPY instruction label exists
docker inspect devops-navigator:v2 | \
  jq -r '.[0].Config.Labels["demo.instruction"]'

# Expected output: COPY
```

## 🎓 Learning Outcomes

After completing this demo, you'll understand:

### Technical Skills

1. ✅ How to use **COPY instruction** in Dockerfiles
2. ✅ How to copy multiple files and directories
3. ✅ How to structure a multi-page web application in Docker
4. ✅ How to add **OCI standard labels** to images
5. ✅ How to build and run containerized applications

### Best Practices

1. ✅ **Prefer COPY over ADD** for regular file operations
2. ✅ **Use labels** for metadata and documentation
3. ✅ **Run as non-root** for security
4. ✅ **Include health checks** for monitoring
5. ✅ **Use multi-stage builds** when applicable

### Docker Commands

1. ✅ `docker build` - Building images
2. ✅ `docker run` - Running containers
3. ✅ `docker inspect` - Inspecting images and containers
4. ✅ `docker logs` - Viewing container logs
5. ✅ Port mapping with `-p` flag

## 🐛 Troubleshooting

### Issue 1: Build Fails with "File Not Found"

**Problem:**
```
COPY failed: file not found in build context
```

**Solution:**
```bash
# Make sure you're in the Dockerfiles directory
cd /root/switchtodevops/01-docker/03-docker-files/04-add-vs-copy/Dockerfiles

# Verify files exist
ls -la
ls -la ../app-files/
```

### Issue 2: Port Already in Use

**Problem:**
```
Error: port is already allocated
```

**Solution:**
```bash
# Use different port
docker run -d -p 8081:80 --name devops-nav devops-navigator:v2

# Or stop the conflicting container
docker stop $(docker ps -q --filter "publish=8080")
```

### Issue 3: Container Name Conflict

**Problem:**
```
Error: name is already in use
```

**Solution:**
```bash
# Remove existing container
docker rm -f devops-nav

# Or use different name
docker run -d -p 8080:80 --name devops-nav-2 devops-navigator:v2
```

### Issue 4: 404 on Hyperlinks

**Problem:** Clicking links shows "404 Not Found"

**Solution:**
```bash
# Verify app-files were copied
docker exec devops-nav ls -la /usr/share/nginx/html/app-files/

# Should show all 5 HTML files
```

## 📚 Additional Resources

- [Complete ADD vs COPY Guide](./add-vs-copy.md)
- [Dockerfile COPY Reference](https://docs.docker.com/engine/reference/builder/#copy)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [OCI Image Spec](https://github.com/opencontainers/image-spec)

## 🎯 Next Steps

1. ✅ **Experiment** - Modify the HTML files and rebuild
2. ✅ **Compare** - Try using ADD instead and see the difference
3. ✅ **Extend** - Add more pages or features
4. ✅ **Deploy** - Push to Docker Hub and share
5. ✅ **Learn More** - Read the complete [add-vs-copy.md](./add-vs-copy.md) guide

## 📋 Summary

This demo demonstrates:
- ✅ **COPY instruction** for copying files
- ✅ **Multi-file structure** with hyperlinks
- ✅ **OCI labels** for metadata
- ✅ **Security** with non-root user
- ✅ **Health checks** for monitoring
- ✅ **Best practices** for production

**Key Takeaway:** Always use COPY instead of ADD unless you specifically need tar extraction or URL downloads.

---

**Version:** 2.0.0  
**Last Updated:** February 2026  
**Demo Instruction:** COPY  
**Purpose:** Learn COPY instruction through interactive examples

---

*Built with ❤️ for DevOps Engineers*
