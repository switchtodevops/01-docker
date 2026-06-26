# 🐳 Docker Commands Cheat Sheet

A simple and handy reference for commonly used Docker commands.

---

## 📦 Version & System Info

### Show Docker version information
```bash
docker version
docker version -f json
```

### Display system-wide information
```bash
docker info
```

---

## 🚀 Container Lifecycle

### Create and run a new container from an image
```bash
# Syntax
docker run --name <CONTAINER-NAME> -p <HOST_PORT>:<CONTAINER_PORT> -d <IMAGE_NAME>:<TAG>

# Example
docker run --name myapp1 -p 8080:80 -d stacksimplify/mynginx:v1
```

### List containers
```bash
docker ps      # List running containers
docker ps -a   # List all containers (including stopped)
docker ps -q   # List only numeric IDs
```

### Start, Stop, and Restart
```bash
# Stop a container
docker stop <CONTAINER-NAME>

# Start a stopped container
docker start <CONTAINER-NAME>

# Restart a container
docker restart <CONTAINER-NAME>
```

### Pause and Unpause
```bash
# Pause processes
docker pause myapp1

# Unpause processes
docker unpause myapp1
```

### Remove containers
```bash
docker rm <CONTAINER-NAME>
```

---

## 🛠 Interaction & Troubleshooting

### Execute a command in a running container
```bash
# Open an interactive shell
docker exec -it <CONTAINER-NAME> /bin/sh

# List files or check environment variables
docker exec -it myapp1 ls
docker exec -it myapp1 printenv
```

### Monitoring & Inspection
```bash
# Fetch the logs of a container
docker logs <CONTAINER-NAME>

# Display running processes of a container
docker top <CONTAINER-NAME>

# List port mappings
docker port <CONTAINER-NAME>
```

---

## 🖼 Image Management

### List and Remove Images
```bash
# List all images
docker images
docker image ls

# List only image IDs
docker images ls -q

# Remove a specific image
docker rmi <IMAGE-ID>

# Remove all images
docker rmi $(docker image ls -q)
```

### Build, Tag, and Registry Operations

| Command | Description |
|---------|-------------|
| `docker build` | Build an image from a Dockerfile |
| `docker tag` | Create a tag TARGET_IMAGE referring to SOURCE_IMAGE |
| `docker pull` | Download an image from a registry |
| `docker push` | Upload an image to a registry |
| `docker login` | Authenticate to a registry |
| `docker logout` | Log out from a registry |

---