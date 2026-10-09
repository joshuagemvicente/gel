# S2 · X post — Context

## Why it exists

The briefing requires an X or LinkedIn **video** post tagging Devin / Cognition with `#AppBuildersPH`; its URL is a submission field. The user chose **X only**. It also carries Gel to the People's Choice audience ([S7](../peoples-choice/spec.md)).

## Where it sits

- **Upstream:** [S3 demo-video](../demo-video/spec.md) (the attached file, exported for X), `docs/project/product.md` (one-liner).
- **Downstream:** [S1 submission-form](../submission-form/spec.md) needs the post URL; [S7](../peoples-choice/spec.md) can point people to it.
- **Owner:** Claude writes `post.md`; the user posts and sends back the URL.

## Current state

Nothing drafted. The video doesn't exist yet (recording ~06:00, Oct 10).

## Facts and gotchas

- Free X accounts: 280 characters; a link counts as 23 characters; video up to 2 min 20 s, MP4/MOV, H.264 + AAC. S3's export targets this.
- The exact official X handles for **Devin** and **Cognition** must be confirmed on x.com before posting. Claude looks them up; the user checks the profile is the verified official one. A wrong handle doesn't count as a tag.
- `#AppBuildersPH` exactly; check whether the organizers' own handle should be tagged too (Telegram group or the event page).
- The post must be **public** (not a protected account) or judges can't open the URL.
- Post by ~07:45 so S1 can be submitted with the URL well before 10:00.

## Related

[spec](spec.md) · [tasks](tasks.md) · [S3 demo-video](../demo-video/spec.md) · [S1 submission-form](../submission-form/spec.md)
