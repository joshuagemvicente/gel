// The only place build facts live. Values come from dist/ (see docs/deliverables/website/spec.md → Release config).
// The DMG ships in public/; scripts/check-dmg.mjs fails the build if it doesn't match sha256 and sizeBytes.
export const release = {
  dmgUrl: process.env.NEXT_PUBLIC_DMG_URL || "/Gel-macOS-arm64.dmg",
  fileName: "Gel-macOS-arm64.dmg",
  sizeBytes: 14_423_750,
  sha256: "23ae6581dc2f4e2b3852b62e04e24a27ceaaad95b1c97b10059e4620a416f72f",
  build: "981b872",
  minMacOS: "15",
  repoUrl: "https://github.com/joshuagemvicente/gel",
} as const

export const sizeLabel = `${(release.sizeBytes / 1_000_000).toFixed(1)} MB`

export const metaLine = `Demo build · ${sizeLabel} · macOS ${release.minMacOS}+ · Apple silicon`
