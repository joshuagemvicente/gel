import { readFile } from "node:fs/promises"
import { join } from "node:path"
import { ImageResponse } from "next/og"

export const alt = "Gel: use AI without leaking personal data."
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
          background: "#08090a",
          color: "#ffffff",
        }}
      >
        <img src={`data:image/png;base64,${icon}`} width={128} height={128} alt="" />
        <div style={{ marginTop: 40, fontSize: 76, fontWeight: 500, letterSpacing: "-0.022em", lineHeight: 1.05 }}>
          Use AI without leaking personal data.
        </div>
        <div style={{ marginTop: 28, fontSize: 30, color: "#8a8f98" }}>
          Leak Guard at the paste · redaction before you upload · on your Mac
        </div>
      </div>
    ),
    size,
  )
}
