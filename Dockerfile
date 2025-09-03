# ---- Base deps stage: install node modules with pnpm ----
FROM node:20-alpine AS deps
WORKDIR /app

# Copy only lockfiles & package.json first for better caching
COPY package.json pnpm-lock.yaml* ./

# Enable Corepack and pin pnpm (must match your packageManager)
RUN corepack enable && corepack prepare pnpm@9.12.3 --activate \
  && pnpm install --frozen-lockfile

# ---- Build stage: compile TypeScript and build frontend ----
FROM node:20-alpine AS build
WORKDIR /app

# Bring in node_modules and the rest of your source
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build: compiles TS to dist/ and bundles frontend to build/
# (relies on your package.json: "build": "tsc && vite build --outDir build")
RUN pnpm run build

# ---- Runtime stage: copy only what's needed to run ----
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
# Koyeb sets PORT dynamically; keep a default for local runs
ENV PORT=3000

# Copy runtime artifacts
COPY --from=build /app/dist ./dist
COPY --from=build /app/build ./build
COPY package.json pnpm-lock.yaml* ./
COPY --from=deps /app/node_modules ./node_modules

# (Optional) Trim dev deps to shrink image; safe to skip if you prefer
RUN corepack enable && corepack prepare pnpm@9.12.3 --activate && pnpm prune --prod

EXPOSE 3000
CMD ["node", "dist/index.js"]
