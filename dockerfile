# Stage 1 — Build Hugo using Alpine
FROM alpine:latest AS builder

# Install required packages, including Hugo Extended
RUN apk add --no-cache hugo git

WORKDIR /src
COPY . .

# Build the site
RUN hugo --minify

# Stage 2 — Serve the site with Nginx
FROM nginx:alpine
COPY --from=builder /src/public /usr/share/nginx/html
