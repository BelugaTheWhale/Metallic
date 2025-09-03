/// <reference path="./src/types/chemicaljs.d.ts" />
import { ChemicalServer } from "chemicaljs";
import express, { Request, Response } from "express";
import fs from "fs";
import chalk from "chalk";
import path from "path";
import pages from "./src/pages.json";
import themes from "./src/themes.json";

const [app, listen] = new ChemicalServer();

// Absolute path to project root (where /build lives after you compile)
const ROOT = path.resolve();

// ✅ Build should NOT happen at runtime on Koyeb. Remove execSync("npm run build").
// Make sure the /build directory exists (compiled files copied at build time).
if (!fs.existsSync(path.join(ROOT, "build"))) {
  // Optional: log a helpful message if someone runs locally without building.
  console.warn("Warning: build/ not found. Run `npm run build` locally before starting.");
}

// ✅ Use numeric port and bind to 0.0.0.0
const PORT = Number(process.env.PORT) || 3000;
const HOST = "0.0.0.0";

app.use(express.static(path.join(ROOT, "build")));

// ChemicalJS middleware
app.serveChemical();

// Single-page app routing: serve index.html for known routes
app.use((req: Request, res: Response) => {
  const indexHtml = path.join(ROOT, "build", "index.html");
  if (pages.includes(req.url)) {
    return res.sendFile(indexHtml);
  } else {
    // You were returning index.html with 404; many SPAs just return 200.
    // If you really want 404, you can keep the status. Otherwise:
    return res.status(200).sendFile(indexHtml);
  }
});

// Small global error handler so the process doesn’t crash silently
process.on("unhandledRejection", (err) => {
  console.error("UnhandledRejection:", err);
});
process.on("uncaughtException", (err) => {
  console.error("UncaughtException:", err);
});

// ✅ Fix the filter bug (=== instead of =), and guard if not found
const defaultTheme =
  themes.find((t: any) => t.id === "default") ??
  { theme: { primary: "#00a3ff" } };

listen(PORT, HOST, () => {
  const theme = chalk.hex(defaultTheme.theme.primary);
  console.log(chalk.bold(theme("Metallic")));

  console.log(`- Local: http://localhost:${PORT}`);

  if (process.env.REPL_SLUG && process.env.REPL_OWNER) {
    console.log(
      `- Replit: https://${process.env.REPL_SLUG}.${process.env.REPL_OWNER}.repl.co`
    );
  }

  if (process.env.HOSTNAME && process.env.GITPOD_WORKSPACE_CLUSTER_HOST) {
    console.log(
      `- Gitpod: https://${PORT}-${process.env.HOSTNAME}.${process.env.GITPOD_WORKSPACE_CLUSTER_HOST}`
    );
  }
});
