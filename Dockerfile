# ---- Stage 1: Dependencies ----
FROM node:20-alpine AS deps
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@9.12.3 --activate
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

# ---- Stage 2: Build ----
FROM node:20-alpine AS build
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@9.12.3 --activate
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build server first so TypeScript errors are obvious
RUN pnpm run build:server
# Show what was produced
RUN ls -la dist || true

# Then build client
RUN pnpm run build:client
RUN ls -la build || true

# ---- Stage 3: Runtime ----
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

COPY --from=build /app/dist ./dist
COPY --from=build /app/build ./build
COPY package.json pnpm-lock.yaml* ./
COPY --from=deps /app/node_modules ./node_modules

RUN corepack enable && corepack prepare pnpm@9.12.3 --activate && pnpm prune --prod

EXPOSE 3000
CMD ["node", "dist/index.js"]

