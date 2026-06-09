import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Produces a minimal, self-contained `.next/standalone` build for Docker.
  // See node_modules/next/dist/docs/.../config/01-next-config-js/output.md
  output: "standalone",
};

export default nextConfig;
