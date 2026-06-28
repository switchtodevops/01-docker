# Dockerfile Instructions - High-Level Refresher

Use this page when you want to quickly remember what each Dockerfile instruction does.

This is not the deep-dive page. Detailed files in this folder explain individual instructions with more examples and best practices.

## Quick Mental Model

A Dockerfile is a recipe for building an image.

- `FROM` chooses the base image.
- `RUN`, `COPY`, and `ADD` build the filesystem.
- `WORKDIR`, `USER`, `ENV`, and `ARG` configure the build and runtime environment.
- `CMD` and `ENTRYPOINT` decide what runs when the container starts.
- `EXPOSE`, `VOLUME`, `HEALTHCHECK`, and `STOPSIGNAL` document or control runtime behavior.
- `LABEL`, `SHELL`, and `ONBUILD` are useful for metadata and advanced cases.

## Common Dockerfile Flow

```dockerfile
FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

ENV NODE_ENV=production
USER node
EXPOSE 3000

CMD ["node", "server.js"]
```

## Instructions At A Glance

| Instruction | Simple Meaning | Common Use |
|-------------|----------------|------------|
| `FROM` | Start from a base image | Choose OS/runtime image |
| `RUN` | Run command while building image | Install packages, build code |
| `CMD` | Default command for container | Start app by default |
| `LABEL` | Add image metadata | Version, owner, description |
| `EXPOSE` | Document container port | Show expected listening port |
| `ENV` | Set environment variable | Runtime config/defaults |
| `ADD` | Copy files with extra features | Tar extract, remote URL |
| `COPY` | Copy files into image | App code, config, artifacts |
| `ENTRYPOINT` | Fixed main executable | Make image behave like a command |
| `VOLUME` | Declare external data path | Persistent or mounted data |
| `USER` | Change user context | Run as non-root |
| `WORKDIR` | Set working directory | Avoid repeated `cd` commands |
| `ARG` | Build-time variable | Version, build option |
| `ONBUILD` | Trigger for child images | Base image automation |
| `STOPSIGNAL` | Stop signal for container | Graceful shutdown |
| `HEALTHCHECK` | Test if container is healthy | App/service health check |
| `SHELL` | Change default shell | Use bash, PowerShell, strict shell |
| `MAINTAINER` | Old author metadata | Deprecated, use `LABEL` |

## Core Instructions

### `FROM`

Starts a new image build stage from a base image.

```dockerfile
FROM ubuntu:22.04
FROM node:20-alpine AS builder
```

Remember:

- Usually the first instruction.
- `ARG` is allowed before `FROM`.
- Multiple `FROM` lines mean multi-stage build.

### `RUN`

Runs commands during image build and saves the result in a new image layer.

```dockerfile
RUN apt-get update && apt-get install -y nginx
RUN npm run build
```

Use it for installing packages, compiling code, or preparing files.

### `CMD`

Sets the default command when a container starts.

```dockerfile
CMD ["node", "server.js"]
```

Remember:

- Can be overridden in `docker run`.
- Only the last `CMD` is used.
- Exec form is preferred: `CMD ["command", "arg"]`.

### `ENTRYPOINT`

Sets the main executable for the container.

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

With this example, the image behaves like the `python` command, and `CMD` provides default arguments.

### `COPY`

Copies files or folders from the build context into the image.

```dockerfile
COPY package.json /app/
COPY . /app
COPY --from=builder /app/dist /app/dist
```

Prefer `COPY` for normal file copying because it is simple and predictable.

### `ADD`

Copies files like `COPY`, but also supports automatic tar extraction and remote URLs.

```dockerfile
ADD app.tar.gz /app/
```

Use `ADD` only when you need its extra behavior. For normal files, use `COPY`.

### `WORKDIR`

Sets the working directory for following instructions.

```dockerfile
WORKDIR /app
```

It creates the directory if it does not exist.

### `USER`

Sets the user for later build steps and for the running container.

```dockerfile
USER node
USER 1001:1001
```

Use a non-root user for production containers whenever possible.

## Configuration Instructions

### `ENV`

Sets environment variables that are available during build and in the running container.

```dockerfile
ENV NODE_ENV=production
ENV PORT=3000
```

Do not store secrets in `ENV`.

### `ARG`

Sets build-time variables.

```dockerfile
ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-alpine
```

Remember:

- Available only during build.
- Not available in the running container unless copied into `ENV`.
- Useful for versions, build options, and metadata.

### `LABEL`

Adds metadata to the image.

```dockerfile
LABEL org.opencontainers.image.title="my-app"
LABEL org.opencontainers.image.version="1.0.0"
```

Use labels for version, owner, source repo, description, or license.

### `EXPOSE`

Documents which port the container is expected to listen on.

```dockerfile
EXPOSE 80
EXPOSE 8080/tcp
```

Important: `EXPOSE` does not publish the port. Use `docker run -p` for that.

### `VOLUME`

Declares a path intended for persistent or external data.

```dockerfile
VOLUME /var/lib/mysql
```

Use it for data that should live outside the image layer.

## Runtime Control Instructions

### `HEALTHCHECK`

Tells Docker how to check whether the container is healthy.

```dockerfile
HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1
```

Useful for detecting broken applications even when the process is still running.

### `STOPSIGNAL`

Sets the signal Docker sends when stopping the container.

```dockerfile
STOPSIGNAL SIGTERM
```

Use it when your application needs a specific signal for graceful shutdown.

## Advanced Instructions

### `SHELL`

Changes the default shell used by shell-form commands.

```dockerfile
SHELL ["/bin/bash", "-c"]
```

Useful when you need bash features, PowerShell, or stricter shell behavior.

### `ONBUILD`

Adds an instruction that runs later when another Dockerfile uses this image as its base.

```dockerfile
ONBUILD COPY . /app
ONBUILD RUN npm install
```

Use carefully. It can make child builds surprising if the trigger is not obvious.

### `MAINTAINER`

Deprecated instruction for image author information.

```dockerfile
# Do not use this in new Dockerfiles
MAINTAINER John Doe <john@example.com>
```

Use `LABEL` instead:

```dockerfile
LABEL org.opencontainers.image.authors="john@example.com"
```

## Easy Confusions

### `CMD` vs `ENTRYPOINT`

- `CMD` is the default command or default arguments.
- `ENTRYPOINT` is the fixed executable.
- Use both when you want a fixed command with changeable default arguments.

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

### `COPY` vs `ADD`

- Use `COPY` for normal files and folders.
- Use `ADD` only when you need tar extraction or URL support.

### `ENV` vs `ARG`

- `ARG` is for build time.
- `ENV` is for runtime.
- Do not use either for secrets.

### `RUN` vs `CMD`

- `RUN` happens while building the image.
- `CMD` happens when starting a container.

## Practical Checklist

Before you call a Dockerfile production-ready, check:

- Base image uses a specific tag, not `latest`.
- App runs as a non-root user with `USER`.
- App start command uses exec form: `CMD ["..."]` or `ENTRYPOINT ["..."]`.
- `.dockerignore` exists.
- Dependencies are pinned where possible.
- Secrets are not stored in `ENV`, `ARG`, or image layers.
- Health check exists for long-running services.
- Multi-stage build is used when it reduces image size.

## Suggested Reading In This Folder

- [LABELS](./01-LABELS.MD)
- [ADD vs COPY](./02-ADD-vs-COPY.MD)
- [ARG](./03-ARG.MD)

More detailed instruction files can be added here as the folder grows.

## Final Memory Hook

Think of a Dockerfile in this order:

1. Choose base: `FROM`
2. Prepare app: `WORKDIR`, `COPY`, `RUN`
3. Configure app: `ENV`, `ARG`, `LABEL`
4. Secure app: `USER`
5. Describe runtime: `EXPOSE`, `VOLUME`, `HEALTHCHECK`
6. Start app: `CMD` or `ENTRYPOINT`
