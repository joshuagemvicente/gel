# S9 · Website — Tasks

Legend: `[x]` done and verified · `[~]` done, not verified · `[ ]` not started. Owner in brackets.

- [x] **T0 Research.** [Claude] References, registries, exemplars and stack facts in [research.md](research.md). **Verify:** every claim cites a source.
- [x] **T1 Agree the spec.** _(Approved Oct 10; HTML recreations for visuals; build stays uncommitted.)_ [user] Read [spec.md](spec.md) and [design.md](design.md), then confirm or change them. **Verify:** the user says yes.
- [x] **T2 Scaffold.** _(Next.js 16.4.0, React 19.3, shadcn 4.21.4 on Base UI (`base-nova`), npm. Build passes.)_ [Claude] `npx create-next-app@latest website` (TypeScript, Tailwind, App Router, no `src/`), then `npx shadcn@latest init` and the core components. Add `website/` entries to `.gitignore` (`node_modules`, `.next`, `.env*.local`). **Verify:** `npm run build` passes on the empty page.
- [x] **T3 Tokens and type.** _(Tokens in `app/globals.css`; Geist via `next/font`; `next-themes` toggle. Checked by screenshot in both modes; contrast fixed per Lighthouse (D-061).)_ [Claude] Write the design.md tokens into `globals.css` (light and dark), load Geist through `next/font`, add `next-themes` and the toggle. **Verify:** a token test page renders correctly in both modes; contrast spot-checked.
- [x] **T4 Release config.** _(`lib/release.ts`, `.env.example`. Unset → buttons go to `#install` and the note shows (dev). Set → all three buttons link to the URL (production build). Hash and size match `dist/`.)_ [Claude] `lib/release.ts`, `.env.example`, Download button behaviour with and without the env var. **Verify:** both cases checked in the browser; the hash and size match `dist/`.
- [x] **T5 Registry components.** _(Kibo Snippet, Magic UI Blur Fade, motion-primitives Text Shimmer kept and patched; Cult terminal and Magic UI Dot Pattern replaced (D-060).)_ [Claude] Add `@kibo-ui/snippet`, `@cult-ui/terminal-animation`, `@magicui/blur-fade`, `@magicui/dot-pattern` and `@motion-primitives/text-shimmer`; read each file; restyle to the tokens. Log any swap in `decisions.md`. **Verify:** each renders on a scratch page; there are no raw hex values left.
- [x] **T6 Brand pieces.** _(`gel-drop.tsx` (the `GelDropPath` curve and `Brand.swift` colours), `window-frame.tsx`, `launcher-demo.tsx`, `leak-overlay.tsx` (summary is real `gelcli detect` output).)_ [Claude] The Gel drop SVG, window frame, launcher recreation and leak-overlay recreation. **Verify:** compared side by side with the polish design; the reduced-motion state is correct.
- [x] **T7 Sections.** _(All nine sections; screenshots at 1440 and 375 px, light and dark; no element wider than the viewport.)_ [Claude] Build sections 1–9 in order with the design.md copy. Copy the DMG art and icon into `public/` and `app/`. **Verify:** screenshots at 1440 px and 375 px, light and dark.
- [x] **T8 Motion and accessibility pass.** _(Reduced motion: launcher and terminal complete, no transforms, drop still, no hydration error (D-062). Keyboard: 39 tab stops, all with a visible ring (production).)_ [Claude] Entrances, the terminal on view, reduced motion, focus rings, keyboard order, alt text. **Verify:** the spec's reduced-motion and keyboard criteria are observed.
- [x] **T9 Truth pass.** _(Table below. Three claims softened: the redaction-failure gate, "offline" and multi-folder UI.)_ [Claude] List each claim on the page next to the feature task that backs it. Remove or soften anything unbacked. **Verify:** the table is written here, and every row points to a `[x]` task.
- [x] **T10 Production check.** _(Lighthouse desktop, production: dark 100/100/100 (perf/a11y/best practices), light 100/97/100. DMG, `.env*.local`, `node_modules` and `.next` are ignored.)_ [Claude] `npm run build && npm start`, Lighthouse desktop, `git status` for stray files. **Verify:** 95+ on the three scores; no DMG or env file is tracked.
- [x] **T4b Bundle the DMG.** _(D-063. Copied from `dist/`, byte-identical. Guard fails on a missing or altered file and is skipped with an override URL. Browser download from the production build: hash matches, `hdiutil verify` valid, mounts, `Gel.app` strict-signed.)_ [Claude] Serve the DMG from `website/public/` as the default download. **Verify:** as in the spec's download criteria.
- [ ] **T11 Deploy.** [user] Set the Vercel root directory to `website/` and deploy (commit `website/public/Gel-macOS-arm64.dmg` first if Vercel deploys from Git). **Verify:** download from the live site, check `shasum -a 256`, and open on a Mac that has never run Gel.

Done when: all [spec.md](spec.md) acceptance criteria hold.

## T9 truth pass

| Claim on the page | Backed by |
| --- | --- |
| Cited answers from your own documents; numbered sources | query-citations T3 `[x]`, launcher T2–T3 `[x]` |
| Ask in English or Taglish | query-citations T3, T11 `[x]` (the demo question is Taglish) |
| Reads PDFs, scans (on-device OCR), images and Word files | indexing T2, T9 `[x]` |
| ⌥Space launcher; Local badge | launcher T2–T3 `[x]`; test-scenarios B2 ✅ (launcher T1, the hotkey task, is still `[~]`) |
| Click a citation → page with the passage highlighted | library-viewer T3 `[x]`, launcher T3 `[x]` |
| Redaction writes a new file; original unchanged | detection-redaction T6, T10 `[x]` |
| Leak Guard warns on copy in the browser, offers a redacted paste | leak-guard T3, T4 `[x]` (the paste itself, T5, is `[~]`: the page shows the button, not the outcome) |
| Leak Guard log keeps counts, not content | leak-guard T7 `[x]` |
| Cloud fallback off by default; your endpoint; redacted text only | `GelSettings.cloudEnabled` defaults to false (Settings.swift:76); model-fallback T10 `[x]` |
| "58 files ready" | demo-download: 58 HR files indexed `[x]` |
| Leak overlay summary text | `gelcli detect --packs hr,personal` on `employee_record.txt`, observed Oct 10 |
| Requirements, model names, install commands | `start-here-dmg.md`; checked character for character |

**Removed:** "If redaction fails, no request is made" (model-fallback T3 is open), "work offline" (scenario A1 is 🟡), and "Add one folder or several" (multi-folder UI T4–T5 are `[~]`). Voice is not mentioned anywhere (voice T2–T5 are `[~]`).
