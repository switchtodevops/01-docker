# Dockerfile LABEL - Crisp Guide

Use this page when you want to quickly refresh Docker image labels.

`LABEL` adds metadata to an image as key-value pairs. Labels do not run code, configure the app, or change container behavior by themselves. They help humans, scripts, registries, scanners, CI/CD systems, and platforms understand an image.

## Quick Memory

```dockerfile
LABEL key="value"
LABEL key1="value1" key2="value2"

LABEL org.opencontainers.image.title="api-service" \
      org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.source="https://github.com/company/api"
```

Think of labels as image metadata:

- Who owns this image?
- What version is it?
- Where is the source code?
- When was it built?
- Which git commit created it?
- Which team, service, license, or environment does it belong to?

## Why Labels Matter

Labels are useful for:

- Documentation: title, description, owner, contact.
- Traceability: version, build date, git commit, CI build URL.
- Automation: filter images/containers by labels.
- Governance: license, vendor, compliance, security scan status.
- Operations: service name, team, support channel, cost center.

Example without labels:

```dockerfile
FROM nginx:1.25-alpine
COPY . /usr/share/nginx/html
```

Example with useful labels:

```dockerfile
FROM nginx:1.25-alpine

LABEL org.opencontainers.image.title="static-site" \
      org.opencontainers.image.description="Company landing page" \
      org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.source="https://github.com/company/site" \
      org.opencontainers.image.authors="web-team@company.com"

COPY . /usr/share/nginx/html
```

## Syntax Rules

Basic syntax:

```dockerfile
LABEL <key>=<value>
LABEL <key>=<value> <key>=<value>
```

Recommended multi-line style:

```dockerfile
LABEL org.opencontainers.image.title="my-app" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.description="Production API service"
```

Important rules:

- Use quotes when values contain spaces.
- Use reverse DNS or OCI names for important labels.
- Group related labels together for readability.
- Labels are stored in image metadata and can be inspected later.
- Labels are visible to anyone who can inspect or pull the image.

Avoid this:

```dockerfile
LABEL description=Production API service
```

Use this:

```dockerfile
LABEL description="Production API service"
```

## Label Keys

Good label keys:

```dockerfile
LABEL org.opencontainers.image.version="1.2.3"
LABEL com.company.team="platform"
LABEL com.company.cost-center="engineering"
LABEL app.name="payment-api"
```

Avoid generic keys for serious images:

```dockerfile
LABEL version="1.2.3"
LABEL team="platform"
```

Generic keys work, but namespaced keys are clearer and safer because base images or tools may use similar names.

## Industry Standard: OCI Labels

OCI means Open Container Initiative. OCI labels are the common industry standard for container image metadata.

Use these first when they match your need:

| OCI Label | Meaning | Example |
|-----------|---------|---------|
| `org.opencontainers.image.title` | Human-readable image name | `payment-api` |
| `org.opencontainers.image.description` | Short image purpose | `Payment REST API` |
| `org.opencontainers.image.version` | App/image version | `1.2.3` |
| `org.opencontainers.image.created` | Build timestamp in RFC 3339 format | `2026-06-28T09:00:00Z` |
| `org.opencontainers.image.authors` | Maintainer or team | `team@company.com` |
| `org.opencontainers.image.source` | Source repository | `https://github.com/company/api` |
| `org.opencontainers.image.revision` | Git commit SHA | `abc123...` |
| `org.opencontainers.image.url` | Project/product URL | `https://company.com/api` |
| `org.opencontainers.image.documentation` | Documentation URL | `https://docs.company.com/api` |
| `org.opencontainers.image.vendor` | Vendor/company name | `Company Inc` |
| `org.opencontainers.image.licenses` | License using SPDX format | `MIT`, `Apache-2.0` |
| `org.opencontainers.image.ref.name` | Tag/branch/reference name | `v1.2.3` |
| `org.opencontainers.image.base.name` | Base image name | `node:20-alpine` |
| `org.opencontainers.image.base.digest` | Base image digest | `sha256:...` |

## Minimum Recommended Labels

For most production images, start with this set:

```dockerfile
LABEL org.opencontainers.image.title="my-app" \
      org.opencontainers.image.description="Short purpose of the image" \
      org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.source="https://github.com/company/my-app" \
      org.opencontainers.image.revision="abc123def" \
      org.opencontainers.image.authors="team@company.com" \
      org.opencontainers.image.licenses="MIT"
```

Add company labels only when useful:

```dockerfile
LABEL com.company.team="backend" \
      com.company.owner="backend-team@company.com" \
      com.company.cost-center="engineering" \
      com.company.service="payment-api"
```

## Dynamic Labels With ARG

Use `ARG` when label values come from CI/CD or the build command.

```dockerfile
ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT
ARG SOURCE_URL

FROM node:20-alpine

ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT
ARG SOURCE_URL

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.source="${SOURCE_URL}"
```

Build command:

```bash
docker build \
  --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --build-arg VERSION="1.2.3" \
  --build-arg GIT_COMMIT="$(git rev-parse HEAD)" \
  --build-arg SOURCE_URL="https://github.com/company/my-app" \
  -t my-app:1.2.3 .
```

Important logic:

- `ARG` before `FROM` can be used in the `FROM` line.
- If you want to use an `ARG` after `FROM`, declare it again in that stage.
- `ARG` is build-time only.
- `LABEL` stores the final resolved value in the image metadata.

## How Labels Work

### Labels Are Inherited

Labels from a base image are inherited by child images.

```dockerfile
FROM company/base:1.0
LABEL app.name="order-service"
```

The final image keeps labels from `company/base:1.0` and adds `app.name`.

### Labels Can Be Overridden

If a child image uses the same label key, the child value wins.

```dockerfile
FROM company/base:1.0
LABEL org.opencontainers.image.vendor="New Company Name"
```

### Labels Cannot Be Removed Cleanly

Docker does not provide a simple `UNLABEL` instruction. To remove unwanted labels, rebuild from a base image that does not contain them or override the value.

## Inspect And Filter Labels

View all labels on an image:

```bash
docker inspect my-app:1.2.3 --format='{{json .Config.Labels}}' | jq
```

View one label:

```bash
docker inspect my-app:1.2.3 \
  --format='{{index .Config.Labels "org.opencontainers.image.version"}}'
```

List images that have a label:

```bash
docker images --filter "label=org.opencontainers.image.version"
```

List images with a specific label value:

```bash
docker images --filter "label=com.company.team=backend"
```

List containers with a label:

```bash
docker ps --filter "label=app.name=payment-api"
```

Show labels in image list output:

```bash
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Labels}}"
```

## Best Practices

Use OCI labels for common metadata.

```dockerfile
LABEL org.opencontainers.image.title="payment-api" \
      org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.source="https://github.com/company/payment-api"
```

Use company namespace for company-specific metadata.

```dockerfile
LABEL com.company.team="payments" \
      com.company.owner="payments-team@company.com"
```

Keep labels short and machine-readable where possible.

```dockerfile
LABEL com.company.environment="production"
LABEL com.company.tier="backend"
```

Do not store secrets.

```dockerfile
# Never do this
LABEL db.password="secret"
LABEL api.token="token-value"
```

Group labels logically.

```dockerfile
LABEL org.opencontainers.image.title="api" \
      org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.revision="abc123"

LABEL com.company.team="backend" \
      com.company.service="api"
```

Prefer stable labels over noisy labels. A build timestamp is useful, but too many changing labels reduce cache reuse for later Dockerfile steps if placed early.

Place labels near the final stage metadata, usually after `FROM` and `ARG` declarations in the final stage.

## Tips And Tricks

Use labels for traceability:

```dockerfile
LABEL org.opencontainers.image.revision="${GIT_COMMIT}" \
      com.company.ci-build-url="${CI_BUILD_URL}"
```

Use labels for ownership:

```dockerfile
LABEL com.company.team="platform" \
      com.company.support="slack:#platform-support"
```

Use labels for automation filters:

```dockerfile
LABEL com.company.cleanup="true" \
      com.company.environment="dev"
```

Then clean up matching dev images:

```bash
docker images --filter "label=com.company.cleanup=true"
```

Use SPDX license identifiers for `org.opencontainers.image.licenses`:

```dockerfile
LABEL org.opencontainers.image.licenses="Apache-2.0"
```

Use RFC 3339 UTC timestamp for `created`:

```bash
date -u +%Y-%m-%dT%H:%M:%SZ
```

Avoid storing large JSON blobs in labels unless a tool really needs them. Labels are metadata, not a database.

## Production Template

```dockerfile
# syntax=docker/dockerfile:1

ARG NODE_VERSION=20
ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT
ARG SOURCE_URL

FROM node:${NODE_VERSION}-alpine AS runtime

ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT
ARG SOURCE_URL

LABEL org.opencontainers.image.title="my-app" \
      org.opencontainers.image.description="Production Node.js service" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.authors="backend-team@company.com" \
      org.opencontainers.image.vendor="Company Inc" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="node:${NODE_VERSION}-alpine"

LABEL com.company.team="backend" \
      com.company.service="my-app" \
      com.company.owner="backend-team@company.com"

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .

USER node
EXPOSE 3000
CMD ["node", "server.js"]
```

## Common Mistakes

### Mistake: Using `MAINTAINER`

Old way:

```dockerfile
MAINTAINER John Doe <john@example.com>
```

Modern way:

```dockerfile
LABEL org.opencontainers.image.authors="John Doe <john@example.com>"
```

### Mistake: Expecting Labels To Configure The App

This does not set an environment variable:

```dockerfile
LABEL app.port="3000"
```

Use `ENV` for runtime environment variables:

```dockerfile
ENV PORT=3000
```

### Mistake: Forgetting ARG Scope

Wrong:

```dockerfile
ARG VERSION=1.0
FROM node:20-alpine
LABEL org.opencontainers.image.version="${VERSION}"
```

Better:

```dockerfile
ARG VERSION=1.0
FROM node:20-alpine
ARG VERSION
LABEL org.opencontainers.image.version="${VERSION}"
```

### Mistake: Putting Secrets In Labels

Labels are inspectable:

```bash
docker inspect image-name
```

Never put passwords, tokens, private keys, or internal secrets in labels.

## Troubleshooting

### Labels Are Empty Or Missing

Check:

- Did the Dockerfile contain `LABEL` in the final stage?
- Did you inspect the correct image tag?
- Did the build use the correct Dockerfile?
- Did `ARG` values exist in the stage where labels are set?

### Build Args Are Not Substituted

Declare `ARG` in the same stage where the `LABEL` uses it.

```dockerfile
FROM alpine:3.20
ARG VERSION
LABEL org.opencontainers.image.version="${VERSION}"
```

### Label Value With Spaces Fails

Use quotes:

```dockerfile
LABEL org.opencontainers.image.description="Production API service"
```

### Need To Compare Labels Between Images

```bash
diff \
  <(docker inspect image-a --format='{{json .Config.Labels}}' | jq -S) \
  <(docker inspect image-b --format='{{json .Config.Labels}}' | jq -S)
```

## Interview Questions

### 1. What is the purpose of `LABEL` in a Dockerfile?

`LABEL` adds metadata to an image as key-value pairs. It is used for documentation, ownership, versioning, automation, filtering, compliance, and traceability.

### 2. Do labels affect how the container runs?

No. Labels are metadata. They do not start processes, expose ports, set environment variables, or change application behavior unless an external tool reads them and acts on them.

### 3. What is the difference between `LABEL` and `ENV`?

`LABEL` stores image metadata. `ENV` sets environment variables available during build steps after it and inside the running container.

### 4. What is the replacement for deprecated `MAINTAINER`?

Use `LABEL`, preferably OCI `authors`:

```dockerfile
LABEL org.opencontainers.image.authors="team@example.com"
```

### 5. What are OCI labels?

OCI labels are standard image metadata keys defined by the Open Container Initiative, such as `org.opencontainers.image.version`, `source`, `revision`, `created`, `licenses`, and `authors`.

### 6. Are labels inherited from base images?

Yes. Labels from the base image are inherited. If the child image sets the same key, the child value overrides the base value.

### 7. Can labels store secrets?

Technically yes, but you must never do it. Labels are visible through image inspection and registries. Use secret management tools instead.

### 8. How do you inspect labels?

```bash
docker inspect image-name --format='{{json .Config.Labels}}' | jq
```

### 9. How do you filter images by label?

```bash
docker images --filter "label=com.company.team=backend"
```

### 10. Why use build args with labels?

Build args let CI/CD inject dynamic values like build date, git SHA, version, branch name, and pipeline URL into image metadata.

### 11. Where should labels be placed in a multi-stage Dockerfile?

Put final image labels in the final stage. Labels in intermediate stages are not useful unless you intentionally build or publish those stages.

### 12. Do labels increase image size?

Only slightly because they are metadata. They do not add application files or large layers unless you put very large values in them.

## Final Refresh Checklist

For production images, remember:

- Use `LABEL` for metadata, not runtime config.
- Prefer OCI keys: `org.opencontainers.image.*`.
- Use `ARG` for dynamic build metadata.
- Include version, source, revision, authors, license, and description.
- Use company namespace for internal labels.
- Never store secrets in labels.
- Inspect labels with `docker inspect`.
- Filter with `docker images --filter label=...` or `docker ps --filter label=...`.
- Put important labels in the final stage of multi-stage builds.

## Related Files

- [All Dockerfile Instructions](./00-all-docker-file-instructions.MD)
- [ADD vs COPY](./02-ADD-vs-COPY.MD)
- [ARG](./03-ARG.MD)

## Official References

- [Dockerfile LABEL reference](https://docs.docker.com/reference/dockerfile/#label)
- [Docker object labels](https://docs.docker.com/engine/manage-resources/labels/)
- [OCI image annotations](https://github.com/opencontainers/image-spec/blob/main/annotations.md)
