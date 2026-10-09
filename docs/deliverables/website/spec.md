# S9 · Website — Spec

Status: **approved Oct 10, 2026; built and verified locally the same day (see [tasks.md](tasks.md)). Not deployed.**

## What it is

A single-page Next.js site in `website/` that explains Gel and gets a Mac user from landing to a working install. Layout, tokens and copy are in [design.md](design.md).

## Stack

- **Next.js 16.4** (App Router, TypeScript, Turbopack), created with `create-next-app`. React 19.3. Static output: the page has no server data and renders as a static route.
- **Tailwind CSS v4** with shadcn's `@theme inline` tokens in `app/globals.css`.
- **shadcn/ui** (CLI 4.x, default Base UI primitives): `button`, `card`, `tabs`, `accordion`, `badge`, `separator`, `tooltip`, `sonner`.
- **Registry components** through `npx shadcn@latest add`, each read before it's kept:
  - `@kibo-ui/snippet` for copyable commands and the checksum.
  - `@cult-ui/terminal-animation` for the "Install Ollama / Pull models" walkthrough.
  - `@magicui/blur-fade` for section entrances and `@magicui/dot-pattern` behind the hero.
  - `@motion-primitives/text-shimmer` for the "Thinking…" line in the hero demo.
- **Fonts:** Geist Sans and Geist Mono through `next/font`.
- **Theme switching:** `next-themes`, following the system setting by default, with a toggle in the nav.
- **npm** as the package manager.

## Page sections, in order

1. **Nav.** Gel drop and wordmark, anchor links (How it works, Privacy, Install, FAQ), theme toggle and a small Download button. Sticky, with a hairline border once scrolled.
2. **Hero.** Headline, one-line subcopy, **Download for Mac** (primary) and **Install guide** (secondary, scrolls to Install). A mono meta line: `Demo build · 14.4 MB · macOS 15+ · Apple silicon`. Visual: an HTML recreation of the launcher answering the demo question with three citation chips and a **Local** badge.
3. **Three claims.** Answers from your files with sources · Personal data stays on this Mac · Catches leaks before you paste.
4. **How it works.** Three steps: choose folders → ask → open the cited passage. Each has a short headline and one visual.
5. **Privacy.** A short human headline, then a "What leaves your Mac" table built from `docs/project/demo-and-submission.md` → "Runs locally vs needs internet", plus the leak-overlay recreation.
6. **Install.** Four numbered steps:
   1. Download and verify: the SHA-256 with a copy button and `shasum -a 256 ~/Downloads/Gel-macOS-arm64.dmg`.
   2. Drag Gel to Applications, and drag Gel Sample Files to Documents, showing the DMG window art.
   3. First launch: Gatekeeper's **Open Anyway** in Apple's wording, including the one-hour window.
   4. Install Ollama and the two models: `brew install ollama`, `brew services start ollama`, `ollama pull qwen3:4b-instruct-2507-q4_K_M`, `ollama pull bge-m3`.
7. **Requirements.** Apple silicon (M1 or newer), macOS 15+, 16 GB RAM recommended, about 8 GB free for models and the index, Ollama. It says plainly that Intel Macs aren't supported.
8. **FAQ.** An accordion: why it isn't notarized, which models it uses, whether anything goes to the cloud, how to try the demo, how to uninstall.
9. **Footer.** Build line (revision, SHA-256), "Built for AppBuildersPH Hackathon 2026 · Team 12M", source link, disclosures (models and libraries, from demo-and-submission.md).

## Release config

`website/lib/release.ts` is the only place build facts live:

```ts
export const release = {
  dmgUrl: process.env.NEXT_PUBLIC_DMG_URL || "/Gel-macOS-arm64.dmg",
  fileName: "Gel-macOS-arm64.dmg",
  sizeBytes: 14_423_750,
  sha256: "23ae6581dc2f4e2b3852b62e04e24a27ceaaad95b1c97b10059e4620a416f72f",
  build: "981b872",
  minMacOS: "15",
  repoUrl: "https://github.com/joshuagemvicente/gel",
}
```

**The DMG ships with the site (user request, Oct 10, D-063).** `website/public/Gel-macOS-arm64.dmg` is a copy of `dist/Gel-macOS-arm64.dmg`, served from the site's own origin, so the Download buttons work with no configuration. It's served with `Content-Type: application/x-apple-diskimage` and `Content-Disposition: attachment`.

- **Guard:** `npm run build` first runs `scripts/check-dmg.mjs`. With no `NEXT_PUBLIC_DMG_URL`, the build fails unless the bundled DMG exists and its SHA-256 and size match `release.ts`. The site can't publish a hash that doesn't match its own file.
- **Override:** `NEXT_PUBLIC_DMG_URL` still points the buttons at an external copy (GitHub Release, Blob, R2); the check is skipped then.
- **New build:** copy the new DMG over the bundled one, then update `sizeBytes`, `sha256` and `build` in `release.ts`. The guard catches a missed step.

## Out of scope

Deploying, buying a domain, analytics, a blog or docs routes, i18n, newsletter or waitlist forms, real app screenshots (the user can add them later), and an auto-generated OG image beyond one static `opengraph-image.png`.

## Acceptance criteria

- [x] `npm run build` in `website/` succeeds with no type or lint errors, and `/` prerenders as static.
- [x] `npm run dev` serves the page with all nine sections in order. Checked by screenshot at 1440 px and 375 px, in light and dark mode.
- [x] No horizontal scroll at 375 px.
- [x] Every colour on the page comes from the tokens in [design.md](design.md). A grep for raw hex in `website/components` and `website/app` finds only `globals.css`, the `theme-color` meta and the OG image, none of which can read CSS variables (D-062).
- [x] With `NEXT_PUBLIC_DMG_URL` set, both Download buttons link to it.
- [x] With it unset, the buttons download the bundled DMG from the site itself: the downloaded file's SHA-256 matches `release.ts`, it passes `hdiutil verify`, and it mounts showing `Gel.app` (production build, browser download).
- [x] The build fails when the bundled DMG is missing or doesn't match `release.ts`.
- [x] The SHA-256, size and build on the page match `dist/Gel-macOS-arm64.dmg.sha256` and `stat` of the DMG.
- [x] Every copy button puts the exact command or hash on the clipboard and shows a "Copied" toast (checked in the browser).
- [x] Model names and install commands match `start-here-dmg.md` character for character.
- [x] Truth pass: every capability claimed on the page maps to a `[x]` task in a feature's `tasks.md`. The mapping is listed in `tasks.md` T9.
- [x] With `prefers-reduced-motion: reduce` emulated, nothing moves except opacity fades; the terminal shows complete text; the drop is still.
- [x] Keyboard only: every link, button, tab and accordion item can be reached and shows a visible focus ring.
- [x] Lighthouse on the production build (`npm run build && npm start`): Performance, Accessibility and Best Practices each 95 or higher on desktop.
- [x] No DMG, `.env.local` or `node_modules` in Git (`git status` and `git check-ignore`).
