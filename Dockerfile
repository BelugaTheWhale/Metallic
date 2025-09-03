# ---- Stage 1: Dependencies ----
FROM node:20-alpine AS deps
WORKDIR /app

# Enable Corepack and install pnpm
RUN corepack enable && corepack prepare pnpm@9.12.3 --activate

# Copy package manifest and install
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

# ---- Stage 2: Build ----
FROM node:20-alpine AS build
WORKDIR /app

# Enable Corepack and pnpm here too
RUN corepack enable && corepack prepare pnpm@9.12.3 --activate

# Copy source and node_modules
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Run build (tsc + vite)
RUN pnpm run build

# ---- Stage 3: Runtime ----
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

# Enable Corepack and pnpm (optional but safe)
RUN corepack enable && corepack prepare pnpm@9.12.3 --activate

# Copy runtime files
COPY --from=build /app/dist ./dist
COPY --from=build /app/build ./build
COPY package.json pnpm-lock.yaml* ./
COPY --from=deps /app/node_modules ./node_modules

# Trim devDependencies (optional)
RUN pnpm prune --prod

EXPOSE 3000
CMD ["node", "dist/index.js"]
