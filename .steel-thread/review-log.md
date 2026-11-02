2026-10-29 · T-002 · MAJOR · Week-start UI tests passed even if the override did nothing · fixed
2026-10-29 · T-002 · MINOR · Weekday column order computed in a view · fixed
2026-10-29 · T-002 · MINOR · A failed first-launch registration permanently dropped the login default · fixed
2026-10-29 · T-002 · MINOR · Two copies launched at once could both quit · fixed
2026-10-29 · T-002 · QUESTION · Switch may not redraw after a failed register · fixed
2026-10-29 · T-002 · QUESTION · Esc from Settings with Keyboard navigation on · fixed
2026-10-29 · T-003 · MINOR · Save-failure banner hidden when the list is empty · fixed
2026-10-29 · T-003 · MINOR · Reason for unreadable data not logged · fixed
2026-10-29 · T-003 · MINOR · 40/280 limits not proven in the real fields (and the field didn't clamp) · fixed
2026-10-29 · T-003 · MINOR · UC-3 earlier-month fix untested · fixed
2026-10-29 · T-003 · MINOR · Unknown-weekday rejection untested · fixed
2026-10-29 · T-003 · MINOR · v1 reader accepted duplicate ids, empty or repeated days, repeated check-offs · fixed
2026-10-29 · T-003 · MINOR · Name selected on Edit (B.9) not proven · fixed
2026-10-29 · T-003 · QUESTION · Tab with Keyboard navigation off · spec changed
2026-10-30 · T-006 · MINOR · Day cell repeated the column width literal · fixed
2026-10-30 · T-006 · MINOR · Row spacing 0 also tightens the gap under the weekday initials · accepted risk
2026-10-30 · T-007 · MAJOR · Launch at login caption squeezed and truncated at 280 pt · fixed
2026-10-30 · T-007 · MINOR · Long schedule label wraps under the name · fixed
2026-10-30 · T-007 · MINOR · Unreadable-data heading may not fit · fixed
2026-10-30 · T-007 · QUESTION · Strip squares 16% smaller; ring overlapped by neighbors · fixed (ring); size accepted risk
2026-10-30 · T-008 · MINOR · README command for the icon script crashed outside the repo root · fixed
2026-10-30 · T-008 · MINOR · Nothing in the SVG warns to regenerate the PDF · fixed
2026-10-30 · T-012 · MAJOR · Folding away a focused strip (or a day change) could leave Esc dead · not reproduced; defensive fix and guard test
2026-10-30 · T-012 · MAJOR · Edit half of B.4 untested; named test missing · fixed
2026-10-30 · T-012 · MINOR · Folded row isn't a Tab stop with Keyboard navigation off · spec changed
2026-10-30 · T-012 · MINOR · Saved habit may sit below the scroll in a long list · spec changed
2026-10-30 · T-012 · MINOR · B.5 unproven at view level; manual tests stale · fixed (manual test)
2026-10-30 · T-012 · MINOR · "Above" not proven in Nothing-due test · fixed
2026-10-30 · T-016 · MINOR · Score card read "— of due days done" when nothing was due yet · fixed
2026-10-30 · T-016 · QUESTION · Rounding showed 100% for a record with misses · fixed (100% only when perfect)
2026-10-30 · T-021 · MINOR · Hover highlight stuck after closing the popover under the pointer · fixed
2026-10-30 · T-021 · QUESTION · Custom style may change borderless buttons' colors · deferred to screenshot pass
2026-10-30 · T-021 · QUESTION · Disabled buttons may be double-dimmed · deferred to screenshot pass
2026-10-30 · T-021 · QUESTION · No visible focus with Keyboard navigation on · fixed (focus shows the highlight)
2026-10-30 · T-022 · MAJOR · Habit saved on a selected past day vanished into the folded row · fixed
2026-10-30 · T-022 · MINOR · Not-due habit on a future day said "can't check off" · fixed
2026-10-30 · T-022 · MINOR · 42 day buttons become Tab stops with Keyboard navigation on · deferred (backlog proposed)
2026-10-30 · T-022 · QUESTION · Header's spoken date abbreviated · moot (customer dropped the date)
2026-10-30 · T-028 · MAJOR · Schedule edit on the day added applied the new schedule to every past day · fixed
2026-10-30 · T-028 · MINOR · Stale comments on addedOn and add · fixed
2026-10-30 · T-028 · MINOR · Strip states before the habit was added untested · fixed
2026-10-30 · T-028 · MINOR · Walks start at the oldest check-off · accepted risk
2026-10-30 · T-028 · QUESTION · New habit scores 0% in rolling windows; tests hid it · fixed (test names it)
2026-10-30 · T-029 design · MAJOR · Switching apps wouldn't close a MenuBarExtra · fixed (resign-active close)
2026-10-30 · T-029 design · MAJOR · Code close from contentView unproven · fixed (first responder, as spiked)
2026-10-30 · T-029 design · QUESTION · isInserted may make the icon removable · fixed (dropped)
2026-10-30 · T-029 design · MINOR · Display wake would reset a half-typed form · fixed
2026-10-30 · T-029 design · MINOR · Refocus hooks' removal half justified · fixed (conditional)
2026-10-30 · T-029 design · MINOR · Esc monitor would steal input-method Esc · fixed
2026-10-30 · T-029 design · MINOR · More UI test changes needed · fixed
2026-10-30 · T-029 design · MINOR · First open could miss its reset · fixed
2026-10-30 · T-029 design · MINOR · Single-instance check order undocumented · fixed
2026-10-30 · T-029 design · MINOR · Stale design spots · fixed
2026-11-01 · T-041 · MINOR · Comments still described the month strip and its focus · fixed
2026-11-01 · T-041 · MINOR · TESTING.md and ARCHITECTURE.md described the old strip · fixed
2026-11-01 · T-041 · MINOR · A UI assertion couldn't fail (the identifier was gone) · fixed
2026-11-01 · T-041 · MINOR · Spec E.3 said "missed" where B.5a says faint · spec changed
2026-11-01 · T-041 · MINOR · Rewritten streak test clicked before the list updated · fixed
2026-11-01 · T-035 · MAJOR · Error-path UI tests couldn't fail (alerts silenced in tests) · fixed
2026-11-01 · T-035 · MINOR · Swift 6 Sendable warning on closePopoverThen · fixed
2026-11-01 · T-035 · MINOR · Design claimed sync runs during a modal dialog · spec changed
2026-11-01 · T-035 · QUESTION · Does Esc cancel the confirmation? · accepted risk
2026-11-01 · T-035 · MINOR · E.3 alert had text the spec doesn't · fixed
2026-11-01 · T-035 · MINOR · Size limit bypassed when the size is unknown · fixed
2026-11-01 · T-035 · MINOR · A stale pending dialog could fire on a later close · fixed
2026-11-01 · T-039 · MAJOR · The final first-sync pass dropped deletes iCloud has · fixed
2026-11-01 · T-039 · MAJOR · Name pairing per batch could pair twice · fixed
2026-11-01 · T-039 · MAJOR · Failed sends showed "Synced" and counted as sent · fixed
2026-11-01 · T-039 · MINOR · sync-state.json decode failed on any new field · fixed
2026-11-01 · T-039 · MINOR · Sign-in after sign-out queued no zone; switch kept the old engine state · fixed
2026-11-01 · T-039 · MINOR · didFetchChanges after a partial fetch could finish the first sync early · accepted risk
2026-11-01 · T-039 · MINOR · SyncPolicy tests checked constants, not the event sequence · fixed
2026-11-01 · T-039 · QUESTION · B.8b with one copy timestamped and one not · fixed
