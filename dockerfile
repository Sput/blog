# Stage 1: Build Hugo site
FROM hugomods/hugo:ext AS builder
WORKDIR /src
COPY . .
RUN hugo --minify

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=builder /src/public /usr/share/nginx/html
