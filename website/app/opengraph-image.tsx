import { readFile } from "node:fs/promises"
import { join } from "node:path"
import { ImageResponse } from "next/og"

export const alt = "Gel: ask your files, keep them on your Mac."
export const size = { width: 1200, height: 630 }
export const contentType = "image/png"

const icon = await readFile(join(process.cwd(), "public/gel-icon.png"), "base64")

export default async function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          padding: "0 96px",
          background: "#f7f5f0",
          color: "#1f1d1a",
        }}
      >
        <img src={`data:image/png;base64,${icon}`} width={128} height={128} alt="" />
        <div style={{ marginTop: 40, fontSize: 76, fontWeight: 600, letterSpacing: "-0.03em", lineHeight: 1.05 }}>
          Ask your files. Keep them on your Mac.
        </div>
        <div style={{ marginTop: 28, fontSize: 30, color: "#6f6a61" }}>
          Private AI for your Mac · cited answers · redaction · Leak Guard
        </div>
      </div>
    ),
    size,
  )
}
