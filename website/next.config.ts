import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  cacheComponents: true,
  partialPrefetching: true,
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
  // The bundled DMG (public/) downloads as a disk image instead of opening in the browser.
  async headers() {
    return [
      {
        source: "/Gel-macOS-arm64.dmg",
        headers: [
          { key: "Content-Type", value: "application/x-apple-diskimage" },
          { key: "Content-Disposition", value: 'attachment; filename="Gel-macOS-arm64.dmg"' },
        ],
      },
    ];
  },
};

export default nextConfig;
