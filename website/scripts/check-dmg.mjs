// Runs before `next build`: the site must never publish a SHA-256 or size that doesn't match the DMG it serves.
// Skipped when NEXT_PUBLIC_DMG_URL points the Download buttons at an external copy.
import { createHash } from "node:crypto"
import { readFile, stat } from "node:fs/promises"
import { join } from "node:path"

const root = join(import.meta.dirname, "..")

if (process.env.NEXT_PUBLIC_DMG_URL) {
  console.log(`check-dmg: skipped, downloads come from ${process.env.NEXT_PUBLIC_DMG_URL}`)
  process.exit(0)
}

const source = await readFile(join(root, "lib/release.ts"), "utf8")
const fileName = source.match(/fileName: "([^"]+)"/)?.[1]
const sha256 = source.match(/sha256: "([0-9a-f]{64})"/)?.[1]
const sizeBytes = Number(source.match(/sizeBytes: ([\d_]+)/)?.[1].replaceAll("_", ""))
if (!fileName || !sha256 || !sizeBytes) {
  console.error("check-dmg: couldn't read fileName, sha256 and sizeBytes from lib/release.ts")
  process.exit(1)
}

const path = join(root, "public", fileName)
const size = await stat(path).then((s) => s.size, () => null)
if (size === null) {
  console.error(`check-dmg: public/${fileName} is missing. Copy it from ../dist/ or set NEXT_PUBLIC_DMG_URL.`)
  process.exit(1)
}

const actual = createHash("sha256").update(await readFile(path)).digest("hex")
const problems = [
  actual !== sha256 && `SHA-256 is ${actual}, release.ts says ${sha256}`,
  size !== sizeBytes && `size is ${size} bytes, release.ts says ${sizeBytes}`,
].filter(Boolean)

if (problems.length) {
  console.error(`check-dmg: public/${fileName} doesn't match lib/release.ts:\n  ${problems.join("\n  ")}`)
  process.exit(1)
}
console.log(`check-dmg: public/${fileName} matches release.ts (${size} bytes, ${actual.slice(0, 12)}…)`)
