# Design Red Flags

Screen the proposed design (§6) and every alternative (§11) against this list before review. A red flag is a reason to revise the shape — not an automatic rejection. Some are justified; if one survives, record why in the design's rationale rather than silently dropping it.

## Shallow module

A shallow module exposes a large interface while hiding little behavior behind it. Judge depth by how much capability or policy sits behind the public surface relative to the size of that surface. A deep call chain (many layers) is not the same defect as a shallow module (thin behavior) — a deep module can still have a long call chain underneath it, as long as the caller never has to see it.

Signs:

- A caller has to make several API calls in a specific order to complete one logical operation, instead of one call that owns the sequencing.
- A function's parameters expose an internal implementation choice the caller shouldn't have to know about (`save_file(path, use_atomic_write: bool)` — atomic-write is a strategy the function should just pick, not a knob the caller sets).
- Reading a function's signature doesn't save the caller from also reading its implementation to know how to call it safely.

Example: if pasting an image requires the UI to call `resolve_path`, then `save_asset`, then `update_links`, in that exact order, that's a shallow module. Collapse it into one operation that owns the whole sequence and returns the result.

## Information leakage

Multiple places depend on the same internal decision, so changing that decision means editing all of them in lockstep.

Watch for:

- A value in an internal representation (a storage key, a raw path, a database ID format) appearing outside the module that owns it — in UI code, in another service, or in persisted state. If the project's conventions name a boundary where that translation happens, a value crossing it untranslated is leakage, not just a style violation.
- One struct's or record's internal field shape driving branching logic in more than one place. If its shape changes, every one of those branches has to change with it.
- A generated or shared type being reshaped, narrowed, or partially hand-copied at a call site instead of used as-is.

## Temporal decomposition

Modules organized by _when_ code runs (load → validate → transform → save) instead of _what they know_, so the same invariant gets re-checked or re-encoded at every stage.

Example: a "load document" path and a "restore after reload" path that each re-implement their own parsing logic are one module in disguise — the thing that owns that parsing — not two pipeline stages that happen to both need it. Give ownership of that invariant one home and call it from both places.

## Pass-through method

A function that forwards the same arguments to another function with the same shape, adding a layer without adding behavior.

A boundary layer the architecture requires, such as a client wrapper around a remote API, is not a red flag on its own. The red flag is a layer with no policy of its own: no error mapping, no translation, no validation, no logging beyond the call it wraps. Merge it into the layer that actually does something.

## Interface depth (tie-breaker for §11 alternatives)

When two real alternatives are otherwise comparable, prefer the one that hides more complexity behind a smaller, simpler public surface — not the one with the shorter call chain. One operation with a richer internal implementation beats three thin ones the caller has to orchestrate itself; that orchestration is exactly the shallow-module pattern above, spread across a call site instead of a module.
