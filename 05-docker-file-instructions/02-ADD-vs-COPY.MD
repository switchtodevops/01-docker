# Dockerfile ADD vs COPY - Crisp Guide

Use this page when you want to quickly refresh the difference between `COPY` and `ADD`.

Both instructions move files into a Docker image. The important rule is simple:

> Use `COPY` by default. Use `ADD` only when you need automatic extraction of a local tar archive.

## Quick Decision

| Question | Use |
|----------|-----|
| Copy normal files or folders? | `COPY` |
| Copy app source code? | `COPY` |
| Copy config files? | `COPY` |
| Copy files from another build stage? | `COPY --from` |
| Set owner while copying? | `COPY --chown` |
| Extract a local `.tar`, `.tar.gz`, `.tgz`, `.tar.xz` archive automatically? | `ADD` |
| Download a file from URL? | Prefer `RUN curl/wget`, not `ADD` |
| Need predictable behavior? | `COPY` |

## One-Line Difference

`COPY` copies files exactly as they are.

`ADD` copies files, but also has extra behavior: it can auto-extract local tar archives and can download URLs.

That extra behavior is why `ADD` is less predictable.

## COPY Syntax

```dockerfile
COPY <src> <dest>
COPY <src1> <src2> <dest>
COPY ["<src>", "<dest>"]
COPY --chown=<user>:<group> <src> <dest>
COPY --chmod=<mode> <src> <dest>
COPY --from=<stage> <src> <dest>
```

Examples:

```dockerfile
COPY package.json /app/
COPY src/ /app/src/
COPY . /app/
COPY --chown=node:node . /app/
COPY --chmod=755 start.sh /usr/local/bin/start.sh
COPY --from=builder /app/dist /app/dist
```

## ADD Syntax

```dockerfile
ADD <src> <dest>
ADD ["<src>", "<dest>"]
ADD --chown=<user>:<group> <src> <dest>
ADD --chmod=<mode> <src> <dest>
```

Examples:

```dockerfile
ADD app.tar.gz /opt/app/
ADD vendor-package.tar.xz /opt/vendor/
```

Avoid this for URLs:

```dockerfile
ADD https://example.com/app.tar.gz /tmp/
```

Prefer this:

```dockerfile
RUN curl -fsSL https://example.com/app.tar.gz -o /tmp/app.tar.gz && \
    echo "expected-sha256  /tmp/app.tar.gz" | sha256sum -c - && \
    tar -xzf /tmp/app.tar.gz -C /opt/app && \
    rm /tmp/app.tar.gz
```

## Behavior Comparison

### Normal Files

```dockerfile
COPY app.py /app/
ADD app.py /app/
```

Both copy `app.py` into `/app/`. For this case, prefer `COPY` because it clearly says what is happening.

### Directories

```dockerfile
COPY src/ /app/src/
ADD src/ /app/src/
```

Both copy the directory recursively. Prefer `COPY`.

### Local Tar Archives

```dockerfile
COPY app.tar.gz /app/
```

Result: `/app/app.tar.gz` is copied as a file.

```dockerfile
ADD app.tar.gz /app/
```

Result: `app.tar.gz` is extracted into `/app/`.

This is the main valid reason to use `ADD`.

### URLs

```dockerfile
ADD https://example.com/file.txt /app/
```

`ADD` can download the URL, but this is usually not recommended because checksum verification, retries, error handling, and caching are weaker than an explicit `RUN curl` or `RUN wget` command.

Important: a tar file downloaded through URL is not auto-extracted by `ADD`. Only local tar archives are auto-extracted.

## When To Use COPY

Use `COPY` in most Dockerfiles.

```dockerfile
FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .

USER node
CMD ["node", "server.js"]
```

Use `COPY` for:

- Application source code.
- Config files.
- Static files.
- Dependency files like `package.json`, `requirements.txt`, `pom.xml`.
- Build artifacts from another stage.
- Files that need ownership or permissions set during copy.

## When To Use ADD

Use `ADD` only when its special behavior is intentional.

Good use case:

```dockerfile
FROM ubuntu:22.04

ADD vendor-app-3.2.1.tar.gz /opt/vendor-app/
WORKDIR /opt/vendor-app
CMD ["./bin/start.sh"]
```

This is acceptable when:

- The archive is local in the build context.
- You want automatic extraction.
- The archive is trusted.
- The behavior is obvious to the team.

If clarity matters more, use `COPY` plus explicit extraction:

```dockerfile
COPY vendor-app-3.2.1.tar.gz /tmp/vendor-app.tar.gz
RUN mkdir -p /opt/vendor-app && \
    tar -xzf /tmp/vendor-app.tar.gz -C /opt/vendor-app && \
    rm /tmp/vendor-app.tar.gz
```

## Why COPY Is Preferred

`COPY` is preferred because it is:

- Simple: it only copies.
- Predictable: no hidden extraction or download behavior.
- Safer: fewer surprises with untrusted archives.
- Clearer for code reviews.
- Better aligned with Docker best practices.

## Build Cache Logic

Docker uses layer caching. Copy order matters.

Bad cache pattern:

```dockerfile
COPY . /app/
RUN npm ci
```

Any source code change invalidates the dependency install layer.

Better cache pattern:

```dockerfile
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY . .
```

Now dependency install is cached until dependency files change.

## Multi-Stage Build Pattern

`COPY --from` is one of the most important production patterns.

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o app ./cmd/app

FROM alpine:3.20
WORKDIR /app
COPY --from=builder /src/app /app/app
USER 65534:65534
ENTRYPOINT ["/app/app"]
```

Why this is good:

- Build tools stay in the builder stage.
- Final image contains only runtime files.
- Image is smaller and cleaner.

## .dockerignore Is Important

`COPY . .` copies everything from the build context unless `.dockerignore` excludes it.

Recommended `.dockerignore` examples:

```dockerignore
.git/
node_modules/
__pycache__/
*.pyc
dist/
build/
target/
coverage/
*.log
.env
.env.*
secrets/
.vscode/
.idea/
```

Why it matters:

- Smaller build context.
- Faster builds.
- Fewer accidental secrets.
- Better cache behavior.

## Ownership And Permissions

Set ownership during copy when possible.

Less ideal:

```dockerfile
COPY . /app/
RUN chown -R appuser:appuser /app
```

Better:

```dockerfile
COPY --chown=appuser:appuser . /app/
```

Set permissions during copy with BuildKit:

```dockerfile
COPY --chmod=755 start.sh /usr/local/bin/start.sh
COPY --chmod=644 config.yaml /etc/app/config.yaml
```

## Security Best Practices

Do not copy secrets into the image.

```dockerfile
# Never do this
COPY .env /app/.env
COPY id_rsa /root/.ssh/id_rsa
COPY secrets/ /app/secrets/
```

Use runtime secrets, Docker secrets, Kubernetes secrets, or BuildKit secrets instead.

Avoid `ADD` from URLs:

```dockerfile
# Avoid
ADD https://example.com/tool /usr/local/bin/tool
```

Prefer explicit download and verification:

```dockerfile
RUN curl -fsSL https://example.com/tool -o /usr/local/bin/tool && \
    echo "expected-sha256  /usr/local/bin/tool" | sha256sum -c - && \
    chmod +x /usr/local/bin/tool
```

Be careful with untrusted tar files. `ADD archive.tar.gz /app/` extracts the archive, so unexpected paths or files can appear in the image.

## Common Mistakes

### Mistake: Using ADD For Normal Files

```dockerfile
# Avoid
ADD package.json /app/
ADD src/ /app/src/

# Prefer
COPY package.json /app/
COPY src/ /app/src/
```

### Mistake: Expecting COPY To Extract Archives

```dockerfile
COPY app.tar.gz /app/
```

This copies the tar file. It does not extract it.

Use one of these:

```dockerfile
ADD app.tar.gz /app/
```

or:

```dockerfile
COPY app.tar.gz /tmp/app.tar.gz
RUN tar -xzf /tmp/app.tar.gz -C /app && rm /tmp/app.tar.gz
```

### Mistake: Expecting URL Tar To Auto-Extract

```dockerfile
ADD https://example.com/app.tar.gz /tmp/
```

This downloads the file. It does not extract it.

### Mistake: Missing Trailing Slash Meaning

```dockerfile
COPY app.py /app
COPY app.py /app/
```

`/app/` clearly means directory. Use clear destination paths to avoid confusion.

### Mistake: Copying Too Much

```dockerfile
COPY . .
```

This is fine only when `.dockerignore` is correct. Without `.dockerignore`, you may copy local dependencies, build outputs, logs, git data, or secrets.

## Troubleshooting

### COPY Failed: File Not Found

Common causes:

- File is outside the build context.
- Path is wrong relative to the build context.
- `.dockerignore` excluded the file.
- You are building from a different directory than expected.

Check your build command:

```bash
docker build -f path/to/Dockerfile .
```

The final `.` is the build context.

### Permission Denied After Copy

Use `--chmod` or `RUN chmod`.

```dockerfile
COPY --chmod=755 start.sh /usr/local/bin/start.sh
```

### App Cannot Write Files

Files may be owned by root.

```dockerfile
COPY --chown=appuser:appuser . /app/
USER appuser
```

### ADD Did Not Extract Archive

Check:

- Is the archive local, not a URL?
- Is it a supported tar format?
- Is it actually a tar archive, not just a file with `.gz` extension?

## Interview Questions

### 1. What is the difference between COPY and ADD?

`COPY` copies files and directories from the build context into the image. `ADD` does the same, but also supports local tar auto-extraction and URL downloads.

### 2. Which one is recommended in production?

`COPY` is recommended by default because it is predictable, simple, and safer.

### 3. When should you use ADD?

Use `ADD` when you intentionally want Docker to auto-extract a local tar archive into the image.

### 4. Should ADD be used to download files from URLs?

Usually no. Prefer `RUN curl` or `RUN wget` with checksum verification and explicit error handling.

### 5. Does COPY extract tar files?

No. `COPY archive.tar.gz /app/` copies the archive as a file.

### 6. Does ADD extract remote tar files from URLs?

No. `ADD` auto-extracts only local tar archives. Remote tar files are downloaded as files.

### 7. What is COPY --from used for?

It copies files from another build stage in a multi-stage Dockerfile.

### 8. Why is .dockerignore important with COPY?

It keeps unwanted files out of the build context and image, improves build speed, protects secrets, and improves cache behavior.

### 9. How can you avoid a separate chown layer?

Use `COPY --chown=user:group`.

### 10. What is the best copy order for Node.js dependencies?

Copy dependency files first, install dependencies, then copy source code.

```dockerfile
COPY package*.json ./
RUN npm ci
COPY . .
```

## Final Memory Hook

Remember this:

1. `COPY` means copy only.
2. `ADD` means copy plus extra magic.
3. Extra magic can surprise you.
4. Use `COPY` for almost everything.
5. Use `ADD` only for trusted local tar extraction.
6. Use `RUN curl/wget` for downloads, with checksum verification.

## Related Files

- [All Dockerfile Instructions](./00-all-docker-file-instructions.MD)
- [LABELS](./01-LABELS.MD)
- [ARG](./03-ARG.MD)

## Official References

- [Dockerfile COPY reference](https://docs.docker.com/reference/dockerfile/#copy)
- [Dockerfile ADD reference](https://docs.docker.com/reference/dockerfile/#add)
- [Docker build context and .dockerignore](https://docs.docker.com/build/building/context/)
