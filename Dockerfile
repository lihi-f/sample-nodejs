FROM node:22.23.2-bookworm-slim AS dependencies

WORKDIR /app

COPY app/package.json app/package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts \
    && npm cache clean --force

FROM gcr.io/distroless/nodejs22-debian13:nonroot

WORKDIR /app

ENV NODE_ENV=production \
    PORT=8080

ARG VERSION=0.0.0
ARG REVISION=""
LABEL org.opencontainers.image.title="sample-nodejs" \
      org.opencontainers.image.description="Sample Express app for Kubernetes" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}"

COPY --from=dependencies --chown=nonroot:nonroot /app/node_modules ./node_modules
COPY --chown=nonroot:nonroot app/app.js ./app.js

USER nonroot
EXPOSE 8080

CMD ["app.js"]
