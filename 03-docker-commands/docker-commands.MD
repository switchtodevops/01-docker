# Docker Commands — Quick Reference

> **Purpose:** Segregated cheat sheet for everyday Docker CLI commands with syntax and examples.  
> **Tip:** Replace placeholders — `<name>`, `<image>`, `<tag>`, `<port>`, `<path>` — with your values.

---

## Table of Contents

1. [System & Authentication](#1-system--authentication)
2. [Image Management](#2-image-management)
3. [Build Images](#3-build-images)
4. [Container Lifecycle](#4-container-lifecycle)
5. [Container Inspection & Monitoring](#5-container-inspection--monitoring)
6. [Container Interaction](#6-container-interaction)
7. [Image from Container](#7-image-from-container)
8. [Networking](#8-networking)
9. [Volumes & Storage](#9-volumes--storage)
10. [System Cleanup](#10-system-cleanup)
11. [Docker Compose](#11-docker-compose)

---

## 1. System & Authentication

| Command | Purpose |
|---------|---------|
| **`docker version`** | Show Docker client and server version details |
| **`docker -v`** | Show client version only (shortcut) |
| **`docker info`** | Display system-wide Docker info (storage, runtime, counts) |
| **`docker login`** | Log in to a registry (Docker Hub by default) |
| **`docker logout`** | Log out from a registry |

```bash
**# Version and system info**
docker version
docker -v
docker info

**# Registry authentication**
docker login                          # prompts for username/password
docker login -u myuser                # specify username
docker login registry.example.com     # private registry
docker logout
```

---

## 2. Image Management

| Command | Purpose |
|---------|---------|
| `docker images` | List images on the local host |
| `docker pull` | Download an image from a registry |
| `docker push` | Upload an image to a registry |
| `docker search` | Search Docker Hub for images |
| `docker tag` | Create a new tag (alias) for an image |
| `docker rmi` | Remove one or more images |
| `docker save` | Export image(s) to a tar archive |
| `docker load` | Import image(s) from a tar archive |
| `docker history` | Show layers and build history of an image |
| `docker import` | Create an image from a tarball (not from Dockerfile) |

```bash
# List and search
docker images
docker images nginx
docker search nginx
docker search nginx --limit 5
docker search --filter=is-official=true nginx

# Pull and push
docker pull nginx:latest
docker pull stacksimplify/mynginx:v1
docker push stacksimplify/mynginx:v1

# Tag (required before push to your namespace)
docker tag mynginx:v1 stacksimplify/mynginx:v1

# Remove images
docker rmi mynginx:v1
docker rmi -f mynginx:v1              # force remove (even if in use)
docker image prune                  # remove dangling images
docker image prune -a                 # remove all unused images

# Save / load (offline transfer)
docker save -o mynginx.tar mynginx:v1
docker load -i mynginx.tar

# Inspect image layers
docker history nginx:latest
docker history --no-trunc mynginx:v1

# Import tarball as image
docker import backup.tar myapp:imported
```

---

## 3. Build Images

| Command | Purpose |
|---------|---------|
| `docker build` | Build an image from a Dockerfile |
| `docker bake` | Build multiple images from a `docker-bake.hcl` file |

```bash
# Basic build
docker build -t mynginx:v1 .
docker build -t mynginx:v1 -f Dockerfile.prod .

# Build with build-args
docker build --build-arg VERSION=1.0 -t myapp:v1 .

# Build without cache
docker build --no-cache -t mynginx:v1 .

# Multi-platform build (requires buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:v1 .

# Bake — multiple targets from one file
docker bake
docker bake --print                    # preview without building
docker bake mytarget
```

> 📌 **`docker exec` and `docker create` are not build commands** — they belong under [Container Lifecycle](#4-container-lifecycle) and [Container Interaction](#6-container-interaction).

---

## 4. Container Lifecycle

| Command | Purpose |
|---------|---------|
| `docker run` | Create **and** start a container |
| `docker create` | Create a container without starting it |
| `docker start` | Start a stopped container |
| `docker stop` | Gracefully stop a running container |
| `docker restart` | Stop then start a container |
| `docker kill` | Force-stop a container (SIGKILL) |
| `docker pause` | Pause all processes in a container |
| `docker unpause` | Resume a paused container |
| `docker rm` | Remove one or more containers |
| `docker rename` | Rename a container |
| `docker wait` | Block until container stops; print exit code |
| `docker update` | Update resource limits on a running container |

```bash
# Run (create + start)
docker run --name myapp1 -p 8080:80 -d nginx
docker run --name myapp2 -p 8081:80 -d --rm nginx    # auto-remove on stop
docker run -it --name shell ubuntu bash               # interactive shell

# Create then start separately
docker create --name myapp3 -p 8082:80 nginx
docker start myapp3

# Stop / start / restart
docker stop myapp1
docker start myapp1
docker restart myapp1
docker kill myapp1                    # immediate stop

# Pause / unpause
docker pause myapp1
docker unpause myapp1

# Remove containers
docker rm myapp1
docker rm -f myapp1                   # force remove running container
docker container prune                # remove all stopped containers

# Rename and wait
docker rename myapp1 web-primary
docker wait web-primary               # exits when container stops

# Update limits (running container)
docker update --memory 512m --cpus 1 myapp1
```

---

## 5. Container Inspection & Monitoring

| Command | Purpose |
|---------|---------|
| `docker ps` | List containers |
| `docker logs` | Fetch container logs (stdout/stderr) |
| `docker inspect` | Return detailed JSON info about object(s) |
| `docker top` | Show running processes inside a container |
| `docker stats` | Live CPU, memory, network, disk usage |
| `docker port` | List port mappings for a container |
| `docker diff` | Show filesystem changes vs image |
| `docker events` | Stream real-time Docker daemon events |

```bash
# List containers
docker ps                             # running only
docker ps -a                          # all (including stopped)
docker ps -q                          # IDs only
docker ps --filter "status=exited"

# Logs
docker logs myapp1
docker logs -f myapp1                 # follow (live tail)
docker logs --tail 100 myapp1
docker logs --since 10m myapp1

# Inspect
docker inspect myapp1
docker inspect --format '{{.State.Status}}' myapp1
docker inspect --format '{{.NetworkSettings.IPAddress}}' myapp1

# Process and resource monitoring
docker top myapp1
docker stats                          # all running containers
docker stats myapp1 --no-stream       # single snapshot

# Ports and filesystem changes
docker port myapp1
docker diff myapp1

# Real-time events
docker events
docker events --filter container=myapp1
```

---

## 6. Container Interaction

| Command | Purpose |
|---------|---------|
| `docker exec` | Run a command inside a **running** container |
| `docker attach` | Attach to a running container's main process |
| `docker cp` | Copy files between host and container |

```bash
# Execute command in running container
docker exec myapp1 ls /usr/share/nginx/html
docker exec -it myapp1 bash           # interactive shell
docker exec -u root myapp1 apt update

# Attach to main process (Ctrl+P, Ctrl+Q to detach)
docker attach myapp1

# Copy files
docker cp myapp1:/etc/nginx/nginx.conf ./nginx.conf    # container → host
docker cp ./index.html myapp1:/usr/share/nginx/html/   # host → container
```

---

## 7. Image from Container

| Command | Purpose |
|---------|---------|
| `docker commit` | Create a new image from a container's current state |
| `docker export` | Export a container filesystem as a tar archive |

```bash
# Snapshot running container to new image (prefer Dockerfile in production)
docker commit myapp1 mynginx:snapshot-v1

# Export container filesystem
docker export myapp1 -o myapp1-fs.tar

# Import exported tar as image (see also: docker import)
docker import myapp1-fs.tar myapp:from-export
```

> ⚠️ Prefer **`docker build`** over `docker commit` for reproducible images.

---

## 8. Networking

| Command | Purpose |
|---------|---------|
| `docker network ls` | List networks |
| `docker network create` | Create a network |
| `docker network inspect` | Show network details |
| `docker network connect` | Connect a container to a network |
| `docker network disconnect` | Disconnect a container from a network |
| `docker network rm` | Remove a network |
| `docker network prune` | Remove unused networks |

```bash
docker network ls
docker network create mynet
docker network create --driver bridge frontend-net

docker run -d --name web --network mynet nginx
docker network connect mynet myapp1
docker network disconnect mynet myapp1

docker network inspect mynet
docker network rm mynet
docker network prune
```

---

## 9. Volumes & Storage

| Command | Purpose |
|---------|---------|
| `docker volume ls` | List volumes |
| `docker volume create` | Create a volume |
| `docker volume inspect` | Show volume details |
| `docker volume rm` | Remove a volume |
| `docker volume prune` | Remove unused volumes |

```bash
docker volume create mydata
docker volume ls
docker volume inspect mydata

# Use volume with container
docker run -d --name db -v mydata:/var/lib/mysql mysql:8

# Bind mount (host path)
docker run -d -v /host/path:/container/path nginx

docker volume rm mydata
docker volume prune
```

---

## 10. System Cleanup

| Command | Purpose |
|---------|---------|
| `docker system df` | Show disk usage by images, containers, volumes |
| `docker system prune` | Remove unused data (containers, networks, dangling images) |
| `docker system prune -a` | Remove all unused images (not just dangling) |
| `docker system events` | Same as `docker events` — daemon event stream |

```bash
docker system df
docker system prune                       # interactive prompt
docker system prune -f                    # skip confirmation
docker system prune -a --volumes          # aggressive cleanup
```

---

## 11. Docker Compose

| Command | Purpose |
|---------|---------|
| `docker compose up` | Create and start services from `docker-compose.yml` |
| `docker compose down` | Stop and remove containers, networks |
| `docker compose ps` | List compose project containers |
| `docker compose logs` | View service logs |
| `docker compose build` | Build or rebuild services |
| `docker compose pull` | Pull service images |

```bash
docker compose up -d
docker compose up -d --build
docker compose ps
docker compose logs -f web
docker compose down
docker compose down -v                  # also remove volumes
```

---

## Command Placement — Validation Notes

Corrections applied from the original draft:

| Issue | Fix |
|-------|-----|
| `$ $docker login` | Typo removed — use `docker login` |
| `docker exec`, `docker create` under **Build Image** | Moved to **Container Lifecycle** / **Container Interaction** |
| `docker commit`, `docker export`, `docker import` under **Container Management** | Grouped under **Image from Container** / **Image Management** |
| `Manamgement` typo | Fixed to **Management** |
| Missing examples | Added for every command group |
| Inconsistent headings | Standardized sections with tables + code blocks |

---

## Most Used — At a Glance

```bash
# Daily workflow
docker version && docker info
docker pull nginx:latest
docker run -d --name web -p 8080:80 nginx
docker ps
docker logs -f web
docker exec -it web bash
docker stop web && docker rm web

# Build and publish
docker build -t myapp:v1 .
docker tag myapp:v1 myuser/myapp:v1
docker login
docker push myuser/myapp:v1

# Cleanup
docker system df
docker system prune -f
```

---

## Related Resources

- [README — Build & Push to Docker Hub](./README.MD)
- [Docker Architecture](../01-docker-intro/03-docker-architeture.MD)
- [Study Plan](../01-docker-intro/01-study-plan.md)
- [Official Docker CLI Reference](https://docs.docker.com/reference/cli/docker/)
