# U7 · History — Context

## Why it exists

Answers from the launcher disappear when it closes; History keeps them. For cloud answers it's the place that shows **What was sent**, the strongest answer to the judges' "doesn't the cloud fallback break the privacy promise?" (demo step 6, optional).

## Where it sits

- **Upstream:** `Store.history(limit:) -> [AnswerResult]` (saved by `QueryEngine` on every answer), launcher ("Open in Gel" selects an answer).
- **Downstream:** library-viewer (citation chips).

## Current state

- Nothing built in the app target. `AnswerResult` has `id`, `date`, `question`, `text`, `citations`, `provider`, `model`, `sentPayload`.

## Facts and gotchas

- `gelcli ask` writes to the same history when it uses the same `GEL_HOME`; good for seeding the view during development.
- Cut-order position: History is the **first** module cut if behind ([roadmap](../../project/roadmap.md)).

## Related docs

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [model-fallback](../model-fallback/spec.md)
