# S9 · Website — Context

## Why it exists

The [demo download](../demo-download/) produced `dist/Gel-macOS-arm64.dmg`, and its context notes say the user will host it on a download website (Vercel or Cloudflare) that gets its own spec folder. Judges and People's Choice voters need a link they can open, read in a minute, and install from.

## Decisions so far (user, Oct 10 2026)

| Question | Answer |
| --- | --- |
| Where the site lives | `website/` in this repo, next to `Gel/`. Vercel points at that subfolder. |
| Scope | One page: landing and download together. |
| Visual direction | Gel's brand (canvas `#F7F5F0`, green `#1F7A4D`, the drop), refined with patterns from styles.refero.design. Light and dark modes. |
| Download link | Read from `NEXT_PUBLIC_DMG_URL`; the user sets it after uploading the DMG. SHA-256, size and build live in one config file. |
| v2 visual direction (later Oct 10) | Redesign to the user's Linear style reference ("midnight precision instrument"): near-black canvas, Inter at tight tracking, hairline borders, 6/12 px radii. Supersedes the "warm paper" direction above. |
| v2 accent | Acid lime `#e4f222` only on the Download button; the green Gel drop stays as the logo; everything else greyscale. Product recreations keep the app's own colours. |
| v2 theme | Dark only; the light theme and toggle go. |
| v2 scope | Restyle plus the reference's layout (left-aligned hero, showcase frame, text-left/visual-right pairs, no 3-column grids). Content and copy stay. |
| v2 logo strip | A "Runs on your Mac with" strip of the on-device components (text, not logos) instead of customer logos, which Gel doesn't have. |

## Inputs

- **Research:** [research.md](research.md), covering the user's references (styles.refero.design, designeer.xyz, beautifului.dev), shadcn registries, macOS download-page exemplars and the stack's current versions.
- **Brand tokens:** `Gel/Gel/App/Theme.swift`, [polish design](../../features/polish/design.md), [DMG design](../demo-download/design.md).
- **Install copy:** [start-here-dmg.md](../demo-download/start-here-dmg.md) is the source of truth for steps and model names.
- **Build facts:** DMG `Gel-macOS-arm64.dmg`, 14,423,750 bytes (14.4 MB), SHA-256 `23ae6581dc2f4e2b3852b62e04e24a27ceaaad95b1c97b10059e4620a416f72f`, source revision `981b872`, arm64, macOS 15.0+, ad-hoc signed, not notarized. There is no marketing version number, so the page says "Demo build · 981b872".
- **DMG art:** `dist/dmg-window@2x.png` and `dist/dmg-window-dark.png` (git-ignored; copied into `website/public/` for the install step).

## Gotchas

- **No app screenshots exist yet.** `media/frames` is empty. The hero and how-it-works visuals are built as HTML recreations of the launcher and leak overlay from the polish design, using the demo dataset. The user can swap in real screenshots later through `website/public/screenshots/`.
- **The DMG ships with the site** (user request, Oct 10, D-063): `website/public/Gel-macOS-arm64.dmg`, 14.4 MB. A Git-connected Vercel project only gets it if it's committed; a CLI deploy uploads it from disk. If the DMG grows a lot, move it to a GitHub Release or Blob and set `NEXT_PUBLIC_DMG_URL`.
- **Repo visibility.** `github.com/joshuagemvicente/gel` is private until the user flips it. The source link only works once it's public.
- **Gatekeeper.** "Open Anyway" appears for about an hour after the first launch attempt ([Apple Support](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac)). On macOS 15, Control-click → Open no longer bypasses the prompt.
- **shadcn defaults to Base UI** since July 2026. Kibo's Snippet uses Radix Tabs, so it either pulls in `radix-ui` or gets rebuilt on the project's own `tabs` (research §4).
- **Only npm is installed** on this Mac (no pnpm or bun), so every command uses `npx` and `npm`.
- **Code freeze.** Deliverables rule 5: no commits after 10:00 AM on Oct 10. Website work after that stays uncommitted unless the user says otherwise.

## Current state

**v2 (Oct 10):** the dark "midnight instrument" redesign is built and verified locally, uncommitted. Every v2 criterion in [spec.md](spec.md) passed; Lighthouse desktop on the production build: 99 / 97 / 100 / 100 (D-076). Deviations: D-073 to D-076. The v1 notes below still apply except where v2 replaced them (fonts, theme, layout).

Built in `website/` and verified locally on Oct 10; uncommitted, as the user asked. Every acceptance criterion in [spec.md](spec.md) passed, including the bundled-download criteria added the same day; evidence is in [tasks.md](tasks.md).

- **Stack:** Next.js 16.4.0, React 19.3, Tailwind 4, shadcn 4.21.4 on Base UI, `motion` 14, `next-themes`, npm.
- **Run:** `cd website && npm run dev`. Production: `npm run build && npm start`.
- **Lighthouse (desktop, production):** dark 100 / 100 / 100 / 100 and light 100 / 97 / 100 / 100 (performance / accessibility / best practices / SEO). The light 97 is one contrast sample taken while the Local badge was still at opacity 0, mid-fade.
- **Deviations:** D-060 (registry swaps), D-061 (visual tokens), D-062 (build details).
- **Download:** the site serves `public/Gel-macOS-arm64.dmg` itself (D-063). Verified on the production build: all three Download buttons save `Gel-macOS-arm64.dmg` with SHA-256 `23ae6581…f72f`; the downloaded file passes `hdiutil verify`, mounts with `Gel.app`, `Applications`, `Gel Sample Files`, `START-HERE.md` and `About This Build`, and `Gel.app` passes `codesign --verify --deep --strict`. Range requests return 206, so interrupted downloads can resume.
- **Left to the user (T11):** set Vercel's root directory to `website/` and deploy, committing `website/public/Gel-macOS-arm64.dmg` if the project deploys from Git. `NEXT_PUBLIC_SITE_URL` is optional.
- **Watch:** another session is adding in-app model setup (`OllamaSetup.swift`, `OllamaPull.swift`). If Gel starts pulling models itself, install step 4 and the FAQ need updating.
