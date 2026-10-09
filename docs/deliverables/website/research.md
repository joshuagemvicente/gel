# Gel website: design research

Research for the Gel download and landing site (Next.js App Router, Tailwind, shadcn/ui). Gathered 2026-10-10. Every claim cites the page it came from. Where a page couldn't be read, the entry says so.

Method note: pages were read through a text fetch, so colors, fonts and layout on the exemplar sites below come from page text and markup only, unless a Refero style entry lists them. Refero entries give measured tokens; they are the only source of exact visual values here.

## Summary

- **Refero Styles is the most useful reference.** It's a library of "2,000+" design systems extracted from real product sites, each with colors, type, spacing, components and a DESIGN.md for coding agents ([styles.refero.design](https://styles.refero.design/)). Six entries fit Gel: **Cursor** (closest match: warm parchment, a forest green, 4px corners, Download as a dark filled button), **Perplexity** (warm paper, one accent, no bold), **Intercom** (cream editorial, light display weights, mono labels), **ElevenLabs** (eggshell, light display, Geist Mono), **Vercel** (CLI panel with green check marks) and **Apple iPhone Duo** (SF Pro type scale).
- **The light, warm-paper systems agree on a few rules.** Off-white canvas, never pure white. One accent used sparingly. Hairline borders before shadows. Negative tracking that grows with size. Headlines at weight 300–500, not bold. Gel's tokens (`#F7F5F0`, `#1F7A4D`, hairline `#E7E3DA`) already sit in this family; Cursor's canvas is `#f7f7f4` and its green is `#34785c` ([Cursor style](https://styles.refero.design/style/4e3b4717-84c8-4599-baaf-a343c3d619b6)).
- **designeer.xyz and beautifului.dev are directories, not style sources.** designeer is a curated link list. Its Components page flags which libraries are shadcn-compatible ([designeer.xyz/components](https://www.designeer.xyz/components)). Beautiful UI is a set of 21 MIT-licensed AI-interface primitives (streaming text with sources, context cards, code block), but it shows no install path ([beautifului.dev](https://www.beautifului.dev/), [license](https://www.beautifului.dev/license)).
- **The shadcn CLI now has a built-in registry directory, so most libraries install with `npx shadcn@latest add @namespace/item`** ([ui.shadcn.com/docs/directory](https://ui.shadcn.com/docs/directory); [registries.json](https://ui.shadcn.com/r/registries.json)). The best pieces for Gel are Kibo UI **Snippet** (tabbed copyable commands, no motion), Cult UI **Terminal Animation** (tabbed typed install scenarios, no motion), Magic UI **Terminal / Blur Fade / Number Ticker**, and motion-primitives **Text Effect / In View**.
- **shadcn now defaults to Base UI, not Radix (July 2026).** Use `-b radix` to keep Radix ([changelog](https://ui.shadcn.com/docs/changelog/2026-07-base-ui-default)). The CLI is at 4.21.4, Tailwind at 4.3.3 and Next.js at 16.4.0 ([npm dist-tags](https://registry.npmjs.org/-/package/shadcn/dist-tags)). `create-next-app` defaults to TypeScript, ESLint, Tailwind, App Router, Cache Components and AGENTS.md ([create-next-app docs](https://nextjs.org/docs/app/api-reference/cli/create-next-app)).
- **None of the macOS landing pages checked puts a full requirements line, checksum and install steps next to the download.** Ghostty comes closest: version, "universal binary", "Requires macOS 13+" ([ghostty.org/download](https://ghostty.org/download)). Ollama shows the install command beside the DMG button ([ollama.com/download/mac](https://ollama.com/download/mac)). Gel can do better with one block: DMG button, then version, size, "macOS 15+ · Apple silicon", then SHA-256 with copy.
- **The privacy sections that work are short and specific.** Wispr Flow uses "Your voice stays yours." ([wisprflow.ai](https://wisprflow.ai/)). Arc says "We don't know what sites you visit or what you search for." ([arc.net](https://arc.net/)). LM Studio says "processed locally and never leaves your device" ([lmstudio.ai](https://lmstudio.ai/)). Gel can go further and show exactly what leaves the Mac.
- **Recommendation:** a warm-paper, Cursor-and-Perplexity-style page in Gel's own tokens. Geist Sans and Geist Mono (OFL), because SF Pro's license forbids website use ([Apple fonts license](https://developer.apple.com/fonts/)). shadcn on Base UI with Gel colors in oklch, `--radius: 0.625rem`, and motion limited to entrances and the Gel drop. Details are under Recommendation.

---

## 1. User-supplied references

### 1.1 Refero Styles: styles.refero.design

**What it is.** "Over 2,000 AI-readable design systems taken from product websites." Each includes colors, typography, spacing, components and a DESIGN.md for agents such as Cursor, Claude Code, Codex, v0 and Lovable. It's in beta, with new styles weekly ([styles.refero.design](https://styles.refero.design/)). It also has an MCP connector at [refero.design/mcp](https://refero.design/mcp).

**How entries are structured.** The home page shows cards with a preview, the source favicon, a name and a one-line mood ("warm paper notebook under…"). Each card links to `/style/{uuid}`. Category chips include "Deep forest green", "Earthy apothecary" and "Terminal & monospace". Each style page has the same sections: theme and overview, a color table (name, hex, `--color-*` token, role), font families with weights, sizes, line heights, tracking and OpenType features, a type scale with `--text-*` tokens, spacing (base unit, scale, max width, section gap), radius per element, shadows, surfaces, components, motion, do's and don'ts, and an agent prompt guide. It also exports CSS custom properties and a Tailwind v4 `@theme` block ([Raycast entry](https://styles.refero.design/style/3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8); [Notion entry](https://styles.refero.design/style/2bf4c61f-de10-4614-ba1b-20c0453bd2a9)). The pages flag their own inconsistencies, such as truncated hex values and range strings in CSS variables. Treat the tables as measured data, not a finished spec.

#### Picks for Gel (ranked by fit)

**1. Cursor: "Warm parchment atelier." The closest match.** [Style page](https://styles.refero.design/style/4e3b4717-84c8-4599-baaf-a343c3d619b6), source [cursor.com](https://cursor.com).
- Colors: Parchment `#f7f7f4` (canvas), Bone `#f2f1ed` (cards), Linen `#e6e5e0` (secondary button), Stone `#cdcdc9` (hairlines), Driftwood `#84847e` (secondary text), Ink `#26251e` (text and primary button), Ember `#f54e00` (links only), Forest `#34785c` (filled green action), Verdant `#1f8a65`.
- Type: CursorGothic 400/500 (fallback Inter), with tracking 0.01em at 14px, −0.012em at 26px, −0.02em at 36px and −0.03em at 72px. EB Garamond 400 at 16–19px for editorial subheads. berkeleyMono 12–13px for code and metadata. Scale: display 72/1.1/−2.16px, heading-lg 36/1.2/−0.72px, heading 26/1.25, body-sm 14/1.5.
- Spacing: 4px base, scale 4–64, max width 1300px, section gap 64–96px, card padding 24px.
- Radius: 4px on cards, inputs and buttons; 8px on modals.
- Motion: color and background transitions at 150ms `cubic-bezier(0.4, 0, 0.2, 1)`.
- Components to borrow: the **primary button is "Download"**: Ink fill, parchment text, 14px/400. It pairs with a Linen secondary button. The **window mockup frame** is a Bone card with grey traffic lights, a 13px centred title and 12px mono tabs. The **terminal / code block** has a 1px border at 10% ink, 10px 12px padding, 12px mono and a grey prompt glyph.
- Rules: no pure white or black, no 600–700 headings, no pills, no gradients or glows, no cool-tinted shadows.
- For Gel: the canvas and ink are nearly Gel's (`#F7F5F0` / `#1F1D1A`). Forest green plays the role of Gel's `#1F7A4D`. Borrow the button pair, the window frame and the code block. Keep Gel's 8px button radius rather than 4px.

**2. Perplexity AI: "scholar's parchment."** [Style page](https://styles.refero.design/style/81afaa5c-73ac-4ef4-9a99-296da325ea6c), source [perplexity.ai](https://perplexity.ai).
- Colors: Parchment `#faf8f5`, Soft Paper `#fdfbfa` (cards), Warm Mist `#d1d1cd` (hairlines), Ink `#27251e`, Graphite `#72706b`, Ash `#92918b`, and one accent, Deep Teal `#016a71`.
- Type: pplxSans 400/500 only, no bold (substitute Inter), with tracking at 0. Hierarchy comes from color and spacing.
- Radius: buttons 6px, inputs 12px, cards 16px, chips 9999px.
- Shadow: a single `rgba(0,0,0,0.08) 0 1px 2px 0`, on cards only.
- Max width 900px.
- For Gel: it shows a citation-first AI product in a warm, quiet palette with one accent and no bold. Gel's answer-with-sources screenshot belongs in the same register.

**3. Intercom: "Warm cream editorial spread."** [Style page](https://styles.refero.design/style/12255b63-e506-4bc1-a4cd-d05487de32f3), source [intercom.com](https://intercom.com).
- Colors: Canvas Cream `#faf9f6`, Linen `#f1eee9` (alternating bands), Hairline `#dedbd6`, Ink `#111111`, Iron `#414141`, Graphite `#585858`. The single accent `#0007cb` is used once or twice a screen.
- Type: Saans 300 for display. Scale: display-lg 80/0.95/−2.4px, display 54/1/−1.62px, heading-lg 40/1.25/−1.2px, body 16/1.5/−0.16px. SaansMono 12px with +1.2px tracking for labels. Fallbacks Inter / Söhne, and JetBrains Mono / Geist Mono.
- Spacing: max width 1200px, section gap 64–96px, sections separated by tone shifts with no divider lines. 4px radius everywhere, no shadows.
- For Gel: separate sections with tone bands (Gel canvas `#F7F5F0` against its viewer tint `#EFECE6`). Use small mono uppercase eyebrows, like the DMG's "TRY THE DEMO" label.

**4. ElevenLabs: "Warm cream editorial."** [Style page](https://styles.refero.design/style/031056ff-7af1-46db-8daa-115f731c5d26), source [elevenlabs.io](https://elevenlabs.io).
- Colors: Eggshell `#fdfcfc`, Warm Taupe `#f5f3f1` (feature cards), Stone `#ebe8e4` (hairlines and icon plates), Ink `#000000`, Graphite `#44403b`, Smoke `#777169`. Color appears only in product art.
- Type: Waldenburg 300 for headings, tracking −0.02em (substitute Inter 300). Inter 400/500 for body, 14–16px at +0.01em. Geist Mono 13px for technical micro-copy.
- Radius: buttons 9999px, cards 20px, large cards 24px.
- Shadow: `rgba(0,0,0,0.4) 0 0 1px 0, rgba(0,0,0,0.04) 0 1px 1px 0, rgba(0,0,0,0.04) 0 2px 4px 0`, a whisper shadow that works for Gel's floating launcher screenshot.
- For Gel: borrow the "colour only in the artwork" rule (the green drop is Gel's artwork) and the whisper shadow.

**5. Vercel: "Typeset terminal on white paper."** [Style page](https://styles.refero.design/style/f24daf3a-d43f-4dec-85a9-8ac1d5148a03), source [vercel.com](https://vercel.com).
- Colors: canvas `#fafafa`, hairline `#ebebeb`, text Obsidian `#171717` and Charcoal `#4d4d4d`. The single accent is **Terminal Green `#297a3a`**, used for links and success check marks.
- Type: Geist Sans 400–500 with display 64/1/−3.84px and heading 30/1.1/−1.5px. Geist Mono at 11px uppercase with 0.071em tracking for eyebrows and metadata.
- Radius 6px. Depth from hairline rings (`0 0 0 1px rgba(0,0,0,0.08)`), no drop shadows.
- Component to borrow: the **CLI output panel** in Geist Mono 12–13px, with commands prefixed `▲` and confirmations prefixed `✓` in `#297a3a`.
- For Gel: this is the install-steps pattern. Gel's green is within a shade of Vercel's.

**6. Apple iPhone Duo: Apple's own web type scale.** [Style page](https://styles.refero.design/style/a73148b9-449b-42cd-9f38-86ef694f500e), source [apple.com/iphone-duo](https://www.apple.com/iphone-duo).
- Colors: Ink `#1d1d1f`, Studio Mist `#f5f5f7` bands, hairline `#d6d6d6`, link blue `#0066cc`.
- Type: SF Pro Display hero 80px/600, 84px line height, −1.2px tracking. Feature heading 40/600. SF Pro Text body 17px/1.47/−0.374px, body-small 14px/−0.224px, nav 12px/−0.12px.
- Spacing: section gap 90px, related elements 20px apart.
- Radius: cards and media 28px, no shadows. Buttons 9999px.
- For Gel: the reference for how SF Pro is tracked on the web. Apply the same tracking curve to Geist (see Recommendation).

**Also checked, not picked.**
- **Notion** has almost Gel's canvas: Paper Warmth `#f6f5f4`, cards `#ffffff`, borders `rgba(0,0,0,0.08)`, radii 8 / 12 / 9999, standard motion 200ms ease. But it relies on a multi-accent illustration system ([Notion entry](https://styles.refero.design/style/2bf4c61f-de10-4614-ba1b-20c0453bd2a9)).
- **Raycast** is dark (`#040506`) with a coral accent. Worth borrowing are its "App Window Mockup" (12px outer radius, 8px list rows, one highlighted row) and its inset key shadows. Don't borrow its palette ([Raycast entry](https://styles.refero.design/style/3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8)).
- **Wise** is green (`#163300`, lime `#9fe870`) but loud: 900-weight display at 105px ([Wise entry](https://styles.refero.design/style/367c0c6e-73a7-441c-a8ff-91d139ac60dc)).
- **Dala** is a dark violet AI brand ([Dala entry](https://styles.refero.design/style/e5f5f8cf-e68d-4ed1-bbf5-6b67569af648)).

### 1.2 designeer.xyz

A link directory: "A curated collection of interface craft, component libraries, AI tools, and resources for builders." Sections are Inspiration, Components, Build, Visuals, Utilities and Design Engineers. Four entries are sponsored ([designeer.xyz](https://www.designeer.xyz/)). It has no style system of its own.

What's useful:
- **Galleries for hero, CTA and footer patterns:** cta.gallery, navbar.gallery, footer.design, Land-book, Minimal Gallery, SaaSFrame, Landing Love ([designeer.xyz](https://www.designeer.xyz/)).
- **Component library list with a shadcn-compatible flag.** It marks shadcn/ui, 21st.dev, shadcnblocks, Animate UI, Kokonut UI, Sera UI, Shadcn Studio and others as compatible. It does **not** flag Magic UI, Aceternity, Cult UI or Kibo UI, all of which are in shadcn's official registry directory (see §2). So the flag is incomplete ([designeer.xyz/components](https://www.designeer.xyz/components)).
- **Motion tools:** Motion, GSAP, Rive, Lottie, Easing Wizard ([designeer.xyz/components](https://www.designeer.xyz/components)).

### 1.3 beautifului.dev

"Crafted primitives for AI-native interfaces": 21 component demos ([beautifului.dev](https://www.beautifului.dev/)). The relevant ones for Gel:
- **03 Streaming Text:** streamed answers with sources and follow-ups.
- **10 Context Cards:** retrieved knowledge chunks.
- **18 Code Block:** line numbers and diff views.
- **01 Loading State:** pixel-grid loader with a timer.

MIT license, "Copyright (c) 2026 Shane Levine" ([license](https://www.beautifului.dev/license)). There's no npm package, CLI or registry. The site only says "copy-paste ready." Its demo icons use a green `#1f7a5f` close to Gel's ([beautifului.dev](https://www.beautifului.dev/)).

For Gel, use it as a visual reference for an animated "answer with citations" demo in the hero or how-it-works section, built by hand. It isn't a dependency.

---

## 2. Additional component registries

All of these are in shadcn's built-in **Registry Directory**, so `npx shadcn@latest add @<namespace>/<item>` works with no setup. shadcn warns that "Community registries are maintained by third-party developers" and to "Always review code on installation" ([directory](https://ui.shadcn.com/docs/directory); URL templates from [registries.json](https://ui.shadcn.com/r/registries.json)). Dependency facts were read from each item's registry JSON.

| Registry | Install format | License | Motion dependency | Components for Gel |
| --- | --- | --- | --- | --- |
| **Magic UI**, [magicui.design](https://magicui.design) | `npx shadcn@latest add @magicui/terminal` (URL template `https://magicui.design/r/{name}`) ([terminal docs](https://magicui.design/docs/components/terminal)) | MIT, 22.5k stars ([GitHub](https://github.com/magicuidesign/magicui)) | Per component: `number-ticker`, `blur-fade` and `border-beam` need `motion`. `terminal`, `marquee`, `shimmer-button`, `safari` and `dot-pattern` declare no dependency ([magicui.design/r/*.json](https://magicui.design/r/terminal.json)). | **Terminal** (macOS-style, auto-sequenced `TypingAnimation` / `AnimatedSpan`, `startOnView`). **Blur Fade** for section entrances. **Number Ticker** for stats. **Dot Pattern** for a quiet hero texture ([docs](https://magicui.design/docs/components/terminal)). |
| **Kibo UI**, [kibo-ui.com](https://www.kibo-ui.com/) | `npx kibo-ui add snippet` on the docs page ([snippet](https://www.kibo-ui.com/components/snippet)); also `@kibo-ui/snippet` through the directory ([registries.json](https://ui.shadcn.com/r/registries.json)) | MIT. The repo moved to `shadcnblocks/kibo`; last push May 2026 ([GitHub API](https://api.github.com/repos/haydenbleasel/kibo)) | None. Snippet needs `lucide-react` plus shadcn `button` and `tabs`. Code Block needs `shiki` ([snippet.json](https://www.kibo-ui.com/r/snippet.json), [code-block.json](https://www.kibo-ui.com/r/code-block.json)) | **Snippet**: tabbed code with a copy button. Use it for `brew install ollama` / `ollama pull …` and for the SHA-256 check. **Code Block** (Shiki). **Status** and **Pill** for "macOS 15+ · Apple silicon" ([snippet](https://www.kibo-ui.com/components/snippet)). |
| **Cult UI**, [cult-ui.com](https://www.cult-ui.com) | `pnpm dlx shadcn@latest add @cult-ui/terminal-animation` ([docs](https://www.cult-ui.com/docs/components/terminal-animation)) | MIT ([GitHub](https://github.com/nolly-studio/cult-ui)) | Mixed. `terminal-animation` and `texture-button` need no motion. `dock` needs `motion` ([registry JSON](https://cult-ui.com/r/terminal-animation.json)) | **Terminal Animation**: tabbed scenarios that type a command and its output, "for … install guides", with `animateOnVisible`. **Mac Screen** and **Browser Window** mockups. **Copy Button** ([docs](https://www.cult-ui.com/docs/components/terminal-animation)). |
| **motion-primitives**, [motion-primitives.com](https://motion-primitives.com) | `@motion-primitives/<name>`; URL template `https://motion-primitives.com/c/{name}.json` ([registries.json](https://ui.shadcn.com/r/registries.json)) | MIT ([GitHub](https://github.com/ibelick/motion-primitives)) | Yes, every item checked needs `motion` ([text-effect.json](https://motion-primitives.com/c/text-effect.json)) | **Text Effect** (headline reveal). **In View** (scroll entrances). **Text Shimmer** (a "thinking…" line that matches the app's launcher shimmer). **Animated Number** ([docs](https://motion-primitives.com/docs)). |
| **Aceternity UI**, [ui.aceternity.com](https://ui.aceternity.com) | `npx shadcn@latest add @aceternity/terminal` ([terminal](https://ui.aceternity.com/components/terminal)) | Custom "Aceternity License": commercial end products allowed, no redistribution or template resale. Paid "All-Access" tier for blocks ([licence](https://ui.aceternity.com/licence)) | Built on Motion ([components](https://ui.aceternity.com/components)). `macbook-scroll` needs `motion`. `terminal` and `bento-grid` declare none ([registry JSON](https://ui.aceternity.com/registry/macbook-scroll.json)) | **Terminal**: a "mac style terminal component with bash syntax highlighting and typewriter effect". Sound is on by default; set `enableSound={false}`. **Bento Grid.** Skip the beams and sparkles effects as off-brand ([terminal](https://ui.aceternity.com/components/terminal)). |
| **coss.com/origin** (formerly Origin UI) | Per-component URL `npx shadcn@latest add https://coss.com/origin/r/comp-01.json` (returns 200). The old `originui.com/r/*` URLs now redirect to coss.com/ui | MIT for `apps/origin` and `apps/ui`; the rest of the repo is AGPL-3.0 ([README](https://github.com/cosscom/coss)) | No | A "legacy snapshot … support and maintenance are limited". Active work moved to coss ui on Base UI (`@coss/*`) ([apps/origin README](https://github.com/cosscom/coss/tree/main/apps/origin)). Useful for plain **Accordion**, **Tabs**, **Stepper** and **Badge** variants. Low priority. |
| **ReUI**, [reui.io](https://reui.io) | `pnpm dlx shadcn@latest add @reui/<item>`; URL template `https://reui.io/r/{style}/{name}.json` ([reui.io](https://reui.io/); [registries.json](https://ui.shadcn.com/r/registries.json)) | MIT for components and primitives. Pro blocks are paid, "From $249, once" ([reui.io](https://reui.io/)) | No for the Base UI items checked ([badge.json](https://reui.io/r/base-nova/badge.json)) | **Stepper** (the 4-step install), **Timeline**, **Code Block**, **Badge** ([reui.io](https://reui.io/)). |
| **shadcnblocks**, [shadcnblocks.com](https://shadcnblocks.com) | `@shadcnblocks/<item>` ([registries.json](https://ui.shadcn.com/r/registries.json)) | Paid licence for pro blocks. Free blocks fall under the site's Terms. Components may not be redistributed outside an end product ([license](https://www.shadcnblocks.com/license)) | Varies | Marketing sections (hero, feature, FAQ, footer) as layout starting points. Optional. |

Not used: **Animate UI**. Its repo reports no standard license (`NOASSERTION`) and was last pushed December 2025 ([GitHub API](https://api.github.com/repos/imskyleen/animate-ui)).

---

## 3. macOS landing page exemplars

Each entry is what the live page shows in its text. Where the text extraction couldn't show something, the entry says so.

| Site | What Gel should borrow | Source |
| --- | --- | --- |
| **Ghostty** download | The model requirements line. "Version 1.3.1" with a release-notes link. "A universal binary that works on both Apple Silicon and Intel machines". "Requires macOS 13+ (Ventura or later)". A primary `.dmg` button plus a secondary "Package Manager" link. No checksum shown, which is a gap Gel can fill. | [ghostty.org/download](https://ghostty.org/download) |
| **Ollama** download | The install command sits next to the DMG button. The page title is "Download Ollama on macOS". OS tabs hold a command block (`curl -fsSL https://ollama.com/install.sh \| sh`) and a "Download manually" button linking straight to `/download/Ollama.dmg`. No system requirements and no `brew` command, so Gel must supply its own `brew install ollama` step. | [ollama.com/download/mac](https://ollama.com/download/mac) |
| **Ollama** home | Privacy in one sentence, in the hero: "Access the latest open models with complete privacy locally or in the cloud. Your prompts are never stored or trained on." Stats strip (9M+ monthly installs, 1B+ model downloads). | [ollama.com](https://ollama.com/) |
| **Linear** download | One dedicated download page. "Available for web, macOS, Windows, iOS, and Android." Desktop blocks each have one "Download" button linking to a stable `releases.linear.app/mac` URL. No requirements and no Apple silicon/Intel split. A stable `/download` URL is worth copying. | [linear.app/download](https://linear.app/download) |
| **Raycast** | A quiet, single-promise hero: "Your shortcut to everything." The four short claims under it ("Fast. Think in milliseconds.", "Reliable. 99.8% crash-free rate.") work as a model for Gel's three claims. The text extraction showed no download button in the nav or hero, only a closing "Take the short way. Download and use Raycast for free." It may be rendered client-side. | [raycast.com](https://www.raycast.com/) |
| **Wispr Flow** | A privacy section with a human headline, "Your voice stays yours.", then concrete commitments ("Your data is never sold…", certifications) and a "Learn more" link. Hero CTA "Download for free." with the line "Available on Mac, Windows, iPhone, and Android." Ends with an FAQ ("Good questions."). | [wisprflow.ai](https://wisprflow.ai/) |
| **Arc** | Privacy as a plain claim: "Arc is built from the ground up to be private and secure. We don't know what sites you visit or what you search for." Feature blocks put one screenshot directly under each short headline. | [arc.net](https://arc.net/) |
| **Superwhisper** | Local vs cloud said honestly, in the FAQ: "Intel Macs work best with Cloud models. Offline models only run really well on Apple Silicon macs." Also "Superwhisper works offline … No Wi-Fi, no problem." Gel should put its Apple-silicon requirement in the same plain words. | [superwhisper.com](https://superwhisper.com/) |
| **CleanShot X** | Mac-native positioning: "Built specifically for Mac with speed, low memory use and battery life in mind." On-device processing called out in a feature ("Fast and private by design", OCR "fast on-device"). The CTA names the platform: "Get CleanShot for Mac." Section order is feature, image card, one-line caption, repeated. | [cleanshot.com](https://cleanshot.com/) |
| **LM Studio** | A local-first privacy line: "Your voice and audio data is processed locally and never leaves your device." and "Natively local." Caveat: the home page and `/download` both served a Windows CTA to the fetcher (`win32/x64`, "Download LM Studio for Windows 0.4.26"), so the Mac block couldn't be seen. | [lmstudio.ai](https://lmstudio.ai/), [lmstudio.ai/download](https://lmstudio.ai/download) |
| **Things 3** | Restraint. The hero is the name and icon. One screenshot collage. Platform cards each show a "Requirements" line and a "Price" line. The requirement values weren't in the extracted text, and the Mac App Store page shows only "Go to App Store". | [culturedcode.com/things](https://culturedcode.com/things/), [Mac page](https://culturedcode.com/things/mac/appstore/) |
| **Jan** | The closest local-AI peer. "Download for Mac" in the hero and again at the end, with "6.9M+ downloads, Free & Open source" beside it. Its friendly illustration style doesn't fit Gel's restraint. | [jan.ai](https://www.jan.ai/) |

Couldn't read: the **MacWhisper** Gumroad page returned only its title ([goodsnooze.gumroad.com/l/macwhisper](https://goodsnooze.gumroad.com/l/macwhisper)).

**Gatekeeper copy to reuse.** Apple's current steps:
1. Apple menu > System Settings > "Privacy & Security".
2. In "Security", click "Open".
3. Click "Open Anyway".
4. Enter your password and click "OK".

The button "is available for about an hour after you try to open the app" ([Apple Support](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac)). Gel's install step should say to try opening Gel first, then go to Settings within the hour.

---

## 4. shadcn / Next.js facts

- **Next.js.** Latest stable is **16.4.0** on npm; the canary is 16.5.0-canary.6 ([npm](https://registry.npmjs.org/-/package/next/dist-tags)). 16.4 was released 2026-10-06 with React 19.3 (stable View Transitions). It turns Cache Components on by default in new `create-next-app` projects ([nextjs.org/blog](https://nextjs.org/blog)). Next.js announced an out-of-band security release for 2026-10-14, so pin a patched 16.4.x when it lands ([nextjs.org/blog](https://nextjs.org/blog)).
- **`create-next-app` defaults** (docs v16.4.0): "TypeScript, ESLint, No React Compiler, Tailwind CSS, No src/ directory, App Router, Cache Components, AGENTS.md, Agent feedback". The import alias is `@/*` and Turbopack is on by default. Biome is offered as a linter ([create-next-app](https://nextjs.org/docs/app/api-reference/cli/create-next-app)). The default template loads **Geist** and **Geist Mono** through `next/font/google` ([template layout.tsx](https://github.com/vercel/next.js/blob/canary/packages/create-next-app/templates/app-tw/ts/app/layout.tsx)).
- **shadcn init.** There are three paths ([installation/next](https://ui.shadcn.com/docs/installation/next)):
  - `pnpm dlx shadcn@latest init --preset [CODE] --template next`, from the visual builder at `/create`.
  - `pnpm dlx shadcn@latest init -t next`.
  - `pnpm create next-app@latest`, then `pnpm dlx shadcn@latest init`.

  The CLI's latest version is **4.21.4** ([npm](https://registry.npmjs.org/-/package/shadcn/dist-tags)).
- **Base UI is the default** since July 2026. Radix is still supported with `pnpm dlx shadcn init -b radix` ([changelog](https://ui.shadcn.com/docs/changelog/2026-07-base-ui-default)). Most third-party registry items above use plain React plus `motion`, not Radix. Kibo's Snippet uses Radix Tabs ([snippet](https://www.kibo-ui.com/components/snippet)), so a Base UI project will pull `radix-ui` in for that one item. That's acceptable, or rebuild Snippet on the project's own `tabs`.
- **Other changelog items.** As of September 2026, components import `cn` from the `cn` package. Registries support server-side search. Private GitHub registries are supported ([changelog](https://ui.shadcn.com/docs/changelog)).
- **Tailwind v4.** All components target Tailwind v4 and React 19. Themes use `@theme inline`, colors are OKLCH, `tw-animate-css` replaces `tailwindcss-animate`, every primitive has a `data-slot`, and `forwardRef` is gone ([tailwind-v4](https://ui.shadcn.com/docs/tailwind-v4)). Latest Tailwind is **4.3.3** ([npm](https://registry.npmjs.org/-/package/tailwindcss/dist-tags)).
- **Theming.** Colors come in semantic pairs: `background`/`foreground`, `card`, `popover`, `primary`, `secondary`, `muted`, `accent`, each with a `-foreground`. Then `destructive`, `border`, `input`, `ring`, `chart-1…5` and the `sidebar-*` set. Base colors are Neutral, Stone, Zinc, Mauve, Olive, Mist and Taupe. `--radius` drives a scale: `sm` = ×0.6, `md` = ×0.8, `lg` = ×1, `xl` = ×1.4, `2xl` = ×1.8 ([theming](https://ui.shadcn.com/docs/theming)).
- **Motion.** The `motion` package is at **14.0.0** ([npm](https://registry.npmjs.org/-/package/motion/dist-tags)). Registry items that need it list `motion`, not `framer-motion`.

---

## 5. Recommendation

### Direction

"Warm paper, one green." A Cursor-like and Perplexity-like page built in Gel's own tokens:
- Off-white canvas and white cards with hairlines.
- Ink text, and Gel green only for the primary action, links and success ticks.
- The green drop gradient is the one piece of art.
- No glows, beams, particles or dark hero.

The privacy story carries the page, so typography and real screenshots do the work.

### Fonts

- **Geist Sans** for UI and headings, and **Geist Mono** for commands, the SHA-256 and eyebrows. Both are OFL-1.1 ([geist-font](https://github.com/vercel/geist-font)), already wired by `create-next-app` ([template](https://github.com/vercel/next.js/blob/canary/packages/create-next-app/templates/app-tw/ts/app/layout.tsx)), and used by the Vercel and ElevenLabs styles above.
- **Inter** (OFL-1.1, [rsms/inter](https://github.com/rsms/inter)) is the fallback.
- **Don't self-host SF Pro.** Its license limits it to UI mock-ups for Apple platforms and forbids "website content" ([developer.apple.com/fonts](https://developer.apple.com/fonts/)). Product screenshots that show SF Pro inside Gel are fine; the license allows "screen shots."
- **Type scale,** using Apple's tracking curve ([Apple iPhone Duo entry](https://styles.refero.design/style/a73148b9-449b-42cd-9f38-86ef694f500e)) and Gel's semibold-with-negative-tracking headers:

| Role | Size / line height | Weight | Tracking |
| --- | --- | --- | --- |
| Hero | 56/60 (40/44 on mobile) | 600 | −0.03em |
| H2 | 36/42 | 600 | −0.02em |
| H3 | 20/28 | 600 | −0.01em |
| Body | 17/26 | 400 | −0.01em |
| Small | 14/20 | 400 | — |
| Mono eyebrow | 11px, uppercase | — | +0.08em, accent green, like the DMG's "TRY THE DEMO" |

### Color tokens (shadcn variables, oklch converted from `Theme.swift`)

Light mode (`:root`). All pairs checked against WCAG AA: `#6F6A61` on `#F7F5F0` is 4.93:1, white on `#1F7A4D` is 5.32:1, `#1F7A4D` on `#F7F5F0` is 4.88:1.

| Variable | Value | Gel token |
| --- | --- | --- |
| `--background` | `oklch(0.970 0.007 88.6)` | canvas `#F7F5F0` |
| `--foreground` | `oklch(0.232 0.006 78.2)` | textPrimary `#1F1D1A` |
| `--card` / `--popover` | `oklch(1 0 0)` | card `#FFFFFF` |
| `--card-foreground` / `--popover-foreground` | `oklch(0.232 0.006 78.2)` | textPrimary |
| `--primary` | `oklch(0.515 0.110 156.8)` | accent `#1F7A4D` |
| `--primary-foreground` | `oklch(1 0 0)` | white |
| `--secondary` / `--muted` | `oklch(0.944 0.009 84.6)` | viewerBackground `#EFECE6` |
| `--secondary-foreground` | `oklch(0.232 0.006 78.2)` | textPrimary |
| `--muted-foreground` | `oklch(0.526 0.015 82.4)` | textSecondary `#6F6A61` |
| `--accent` | `oklch(0.515 0.110 156.8 / 0.12)` | accentSoft |
| `--accent-foreground` | `oklch(0.515 0.110 156.8)` | accent |
| `--destructive` | `oklch(0.530 0.153 31.4)` | danger `#B3402E` |
| `--border` / `--input` | `oklch(0.916 0.013 86.8)` | hairline `#E7E3DA` |
| `--ring` | `oklch(0.515 0.110 156.8 / 0.5)` | accent at 50% |
| `--gel-drop` (custom) | `linear-gradient(180deg, #4FC48A, #1F7A4D)` | drop gradient |

Dark mode (`.dark`), same variables:

| Variable | Value | Gel token |
| --- | --- | --- |
| `--background` | `oklch(0.231 0.004 84.6)` | `#1E1D1B` |
| `--card` | `oklch(0.270 0.005 67.6)` | `#282624` |
| `--foreground` | `oklch(0.953 0.009 84.6)` | `#F2EFE9` |
| `--muted-foreground` | `oklch(0.714 0.018 84.6)` | `#A8A296` |
| `--primary` | `oklch(0.531 0.113 157.1)` | accentFill `#217F51` (white text 4.98:1) |
| Accent text and links | `oklch(0.684 0.133 158.4)` | `#3FB27A` |
| `--border` | `oklch(0.338 0.008 75.3)` | `#3A3733` |
| `--destructive` | `oklch(0.672 0.144 31.6)` | `#E0705C` |
| Drop gradient | `#5CD49A → #2A8F5C` | dark drop |

### Radii, depth, layout

- **Radius:** `--radius: 0.625rem`. That gives `md` 8px (Gel buttons), `lg` 10px (inputs and code blocks), `xl` 14px (cards; matches the leak-overlay card) and `2xl` 18px (screenshot frames).
- **Depth:** hairlines first. One shadow, for floating screenshots only: ElevenLabs' whisper stack tinted warm, using Gel's `shadow` color `#3A2F1E` at 10% ([ElevenLabs entry](https://styles.refero.design/style/031056ff-7af1-46db-8daa-115f731c5d26)).
- **Layout:** max width 1120–1200px. Section gap 96px desktop, 64px mobile. Separate sections by alternating canvas and the `#EFECE6` band, not divider lines ([Intercom entry](https://styles.refero.design/style/12255b63-e506-4bc1-a4cd-d05487de32f3)).

### Motion rules (from Gel's polish tokens)

- **Hover and press:** 150ms `cubic-bezier(0.4, 0, 0.2, 1)` for color changes ([Cursor entry](https://styles.refero.design/style/4e3b4717-84c8-4599-baaf-a343c3d619b6)). Press scales to 0.97.
- **Entrances:** fade plus 8px rise over about 400ms (Gel `smooth`). Stagger 35ms, at most 8 items. Run once, on view.
- **The Gel drop is the only looping animation,** a breathing scale of 0.98 → 1.06 over 0.9s in the hero. Everything else plays once.
- **The install terminal** types once, on view. It never auto-loops.
- **`prefers-reduced-motion`:** opacity-only 150ms fades. Typing renders as complete text. The drop stays still.
- **Library:** use `motion` only where a registry item needs it (Blur Fade, Text Effect). Hover states stay in CSS.

### Page outline

1. **Nav.** Drop and "Gel" wordmark; links for How it works, Privacy, Install, FAQ; a small "Download" button.
2. **Hero.**
   - Headline about private answers from your own files.
   - One-line subcopy.
   - Primary "Download for Mac" (the DMG), with secondary "Install guide ↓".
   - Meta line in mono: `v0.x · 1xx MB · macOS 15+ · Apple silicon`.
   - Visual: the launcher answering with numbered citation chips, in a macOS window frame with a whisper shadow, on canvas, next to the Gel drop.
3. **Three claims, Raycast-style:**
   - "Answers from your files, with sources."
   - "Personal data stays on this Mac."
   - "Catches leaks before you paste."
4. **How it works.** Three steps (choose folders → ask → open the cited passage), each with one real screenshot under a short headline, in the Arc and CleanShot pattern.
5. **Privacy.** A Wispr-style human headline, then a concrete "What leaves your Mac" table: local model vs cloud, what's redacted, what's stored ("Counts only"). Include a leak-guard screenshot.
6. **Install.** A numbered stepper:
   1. Download and verify: SHA-256 with a copy button, plus a `shasum -a 256 Gel.dmg` snippet.
   2. Drag Gel to Applications (show the DMG window art).
   3. First launch: Gatekeeper "Open Anyway", in Apple's exact wording and with its one-hour window.
   4. Install Ollama and the models: `brew install ollama`, `ollama pull qwen3:4b-instruct-2507-q4_K_M`, `ollama pull bge-m3` (from [start-here.md](../demo-download/start-here.md)).
7. **Requirements card.** macOS 15+, Apple silicon, RAM and disk for the models, Ollama. State plainly that Intel Macs aren't supported, as Superwhisper does.
8. **FAQ.** Accordion: notarization, which models, does anything go to the cloud, uninstall.
9. **Footer.** Build info, SHA-256 again, hackathon credit (AppBuildersPH 2026), source link.

### Component shortlist

- **shadcn core** (Base UI): `button`, `card`, `tabs`, `accordion`, `badge`, `separator`, `tooltip`, `sonner` (for the "Copied" toast).
- **Kibo UI `@kibo-ui/snippet`** for every copyable command and the hash. It has no motion.
- **Cult UI `@cult-ui/terminal-animation`** for a tabbed "Install Ollama / Pull models" animation. It has no motion. Alternative: **Magic UI `@magicui/terminal`**, if a single sequence is enough.
- **Magic UI `@magicui/blur-fade`** for section entrances, and **`@magicui/dot-pattern`** at very low opacity behind the hero. Optional: **`@magicui/number-ticker`** if a stats row is added.
- **motion-primitives `@motion-primitives/text-shimmer`** for a "Thinking…" line in the hero demo, matching the app's launcher shimmer.
- **ReUI `@reui/…` Stepper** for the install steps, if the shadcn core doesn't cover it.
- **Window frame:** build it by hand after Cursor's mockup (traffic lights, 13px centred title, Bone-like card) rather than pull a device-mock package.
- **Avoid:** Aceternity beams, sparkles and lamp effects; marquees of fake logos; shadcnblocks pro blocks (license); and coss/origin as a primary source (legacy).

---

## Sources

**User-supplied**
- https://styles.refero.design/
- https://styles.refero.design/style/4e3b4717-84c8-4599-baaf-a343c3d619b6 (Cursor)
- https://styles.refero.design/style/81afaa5c-73ac-4ef4-9a99-296da325ea6c (Perplexity AI)
- https://styles.refero.design/style/12255b63-e506-4bc1-a4cd-d05487de32f3 (Intercom)
- https://styles.refero.design/style/031056ff-7af1-46db-8daa-115f731c5d26 (ElevenLabs)
- https://styles.refero.design/style/f24daf3a-d43f-4dec-85a9-8ac1d5148a03 (Vercel)
- https://styles.refero.design/style/a73148b9-449b-42cd-9f38-86ef694f500e (Apple iPhone Duo)
- https://styles.refero.design/style/2bf4c61f-de10-4614-ba1b-20c0453bd2a9 (Notion)
- https://styles.refero.design/style/3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8 (Raycast)
- https://styles.refero.design/style/367c0c6e-73a7-441c-a8ff-91d139ac60dc (Wise)
- https://styles.refero.design/style/e5f5f8cf-e68d-4ed1-bbf5-6b67569af648 (Dala)
- https://www.designeer.xyz/ and https://www.designeer.xyz/components
- https://www.beautifului.dev/ and https://www.beautifului.dev/license

**Registries**
- https://ui.shadcn.com/docs/directory, https://ui.shadcn.com/r/registries.json
- https://magicui.design/docs/components/terminal, https://magicui.design/r/{terminal,number-ticker,marquee,bento-grid,shimmer-button,safari,blur-fade,dot-pattern,border-beam}.json, https://github.com/magicuidesign/magicui
- https://www.kibo-ui.com/components/snippet, https://www.kibo-ui.com/r/{snippet,code-block,marquee}.json, https://github.com/shadcnblocks/kibo
- https://www.cult-ui.com/docs/components/terminal-animation, https://cult-ui.com/r/{terminal-animation,texture-button,dock}.json, https://github.com/nolly-studio/cult-ui
- https://motion-primitives.com/docs, https://motion-primitives.com/c/{text-effect,animated-number,text-shimmer,in-view}.json, https://github.com/ibelick/motion-primitives
- https://ui.aceternity.com/components, https://ui.aceternity.com/components/terminal, https://ui.aceternity.com/licence, https://ui.aceternity.com/registry/{terminal,macbook-scroll,bento-grid}.json
- https://coss.com/origin, https://coss.com/origin/r/comp-01.json, https://github.com/cosscom/coss (README licensing; apps/origin and apps/ui READMEs)
- https://reui.io/, https://reui.io/r/base-nova/badge.json, https://github.com/keenthemes/reui
- https://www.shadcnblocks.com/license
- https://github.com/imskyleen/animate-ui

**macOS exemplars**
- https://ghostty.org/download
- https://ollama.com/download/mac, https://ollama.com/
- https://linear.app/download
- https://www.raycast.com/
- https://wisprflow.ai/
- https://arc.net/
- https://superwhisper.com/
- https://cleanshot.com/
- https://lmstudio.ai/, https://lmstudio.ai/download
- https://culturedcode.com/things/, https://culturedcode.com/things/mac/appstore/
- https://www.jan.ai/
- https://goodsnooze.gumroad.com/l/macwhisper (unreadable)
- https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac

**Stack facts**
- https://ui.shadcn.com/docs/installation/next
- https://ui.shadcn.com/docs/tailwind-v4
- https://ui.shadcn.com/docs/theming
- https://ui.shadcn.com/docs/changelog, https://ui.shadcn.com/docs/changelog/2026-07-base-ui-default
- https://nextjs.org/blog
- https://nextjs.org/docs/app/api-reference/cli/create-next-app
- https://github.com/vercel/next.js/blob/canary/packages/create-next-app/templates/app-tw/ts/app/layout.tsx
- https://registry.npmjs.org/-/package/{next,shadcn,tailwindcss,motion,react}/dist-tags
- https://developer.apple.com/fonts/
- https://github.com/vercel/geist-font, https://github.com/rsms/inter
- Gel tokens: `Gel/Gel/App/Theme.swift`, `docs/features/polish/design.md`, `docs/deliverables/demo-download/design.md`, `docs/deliverables/demo-download/start-here.md`
