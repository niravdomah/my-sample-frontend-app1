# syntax=docker/dockerfile:1

# Multi-stage build for a Next.js (App Router) app using `output: "standalone"`.
# Next.js 16 requires Node.js >= 20.9; we use the current LTS line.

# 1. Install dependencies only when needed
FROM node:22-alpine AS deps
# https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the lockfile for reproducible builds.
COPY package.json package-lock.json ./
RUN npm ci

# 2. Build the application
FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Disable Next.js telemetry during the build.
ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

# 3. Production image — copy only the standalone output and run it
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Run as a non-root user.
RUN addgroup --system --gid 1001 nodejs \
  && adduser --system --uid 1001 nextjs

# `output: "standalone"` does not include public/ or .next/static by design
# (these are ideally served by a CDN), so copy them in explicitly.
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

# server.js honours PORT and HOSTNAME; bind to all interfaces in the container.
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

CMD ["node", "server.js"]
