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

### Text objects are not context-aware

Pair (`i(`), quote (`i"`) and tag (`it`) objects scan characters with
nesting/balance counting; they do not skip delimiters inside strings or
comments, escaped delimiters, etc. This matches Vim's own text objects,
which are char-based and not syntax-aware without plugins. Structural
awareness is deliberately left to the user side (e.g. tree-sitter),
keeping the objects small and dependency-free.

## Temporary

### `.` ignores the register prefix

`"adw` repeats as `dw`: the `"` prefix is a separate command whose
register does not enter the repeat record. Fix scheduled for **0.14**.

### `$A` ragged block append is not special-cased

Vim's `$` in a block selection makes `A` append at each line's own end
(ragged right). aim-mode's block `A` always uses a fixed column,
padding short lines with spaces. Everyday block `I`/`A`/`c` at a fixed
column work; the `$`-extended ragged form is the gap.
