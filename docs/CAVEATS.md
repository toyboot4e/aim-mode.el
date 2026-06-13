# Caveats

Known divergences and limitations in *shipped* behavior. Anything not yet
implemented belongs in [ROADMAP.md](./ROADMAP.md), not here.

Rules for this file:

- Every shipped divergence from Vim (inside the Common Core) and every
  known limitation gets an entry — silent divergence is a bug.
- Each entry says whether it is **permanent** (by design, usually backed by
  an ADR) or **temporary** (cite the milestone that removes it).

## Permanent (by design)

### Emacs cursor model

Point sits *between* characters, not *on* one (Vim's normal-state model).
Consequences: `$` lands after the last character, `l` can reach end of
line, and point may rest at end of line in normal State. Operator ranges
still match Vim (`d$`, `dl`, `x` behave correctly). Emulating Vim's
on-a-character model would require post-command point adjustment
everywhere; we keep Emacs's model (docs/adr/0002 spirit: Emacs semantics
win outside operator ranges).

### Emacs regex everywhere

Search and (future) `:s///` use Emacs regular expressions, never Vim's
dialect (docs/adr/0002).

### Repeat replays recorded input

`.` records the *input keys* of the last change (operator keys, motion,
read characters, insert-session keystrokes) and replays them through
`execute-kbd-macro` — the command + input recording decided early
(docs/adr/0003). A replayed command that consults state outside the
buffer (completion popups, minibuffer reads other than characters) may
diverge from its original run. Evil shares this property.

### Foreign kills fall back to a heuristic

Text killed by aim-mode carries its charwise/linewise type as a text
property; text killed by other Emacs commands has none, so paste guesses
from a trailing newline. Inherent to sharing the kill-ring
(docs/adr/0002).

## Temporary

### `.` ignores the register prefix

`"adw` repeats as `dw`: the `"` prefix is a separate command whose
register does not enter the repeat record. Fix when repeat learns about
prefix state; no milestone committed yet.

### Block change does not replicate insertion

`c` on a block selection deletes the rectangle and inserts on the first
line only; Vim replays the insertion on every line of the block when
leaving insert. Paste over a block selection is also unsupported.
Planned for the 1.0 completeness pass.

### Block selection highlights linearly

Charwise and linewise visual selections are drawn by a dedicated
overlay matching the true Vim range (inclusive / whole-line). Block
(`C-v`) still shows the plain region — a linear span from the first
corner to the last, not the rectangle that operators actually act on.
A per-line rectangle highlight is its own task.

### Pair and quote objects are context-blind

`i(`/`a"`-style objects scan characters directly: escaped characters
(`\"`) and pairs inside strings or comments are not recognized as
special. Syntax-aware scanning can come with later polish; no milestone
committed yet.
