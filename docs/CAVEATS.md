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

## Temporary

### `cw` eats trailing whitespace

Vim treats `cw` as `ce`; aim-mode currently changes the same range `dw`
would delete. Fix planned with the repeat/operator polish in **0.3**.

### Terminal Meta chords shadowed in insert State

`ESC` is bound as a raw character, so in `-nw` Emacs (where `M-x` arrives
as `ESC x`) Meta chords are shadowed in insert and operator-pending
States. GUI Emacs is unaffected. The `input-decode-map` timeout
treatment lands in **0.9**.

### Paste guesses linewise-ness

`p`/`P` treat kill-ring text ending in a newline as linewise. Real
register types (so a charwise kill ending in `\n` pastes charwise)
arrive with the register layer in **0.8**.

### Word motions ignore the syntax table

Word characters are hard-coded as `[:alnum:]_` instead of consulting the
buffer's syntax table / anything like Vim's `iskeyword`. Noticeable in
e.g. Lisp modes where `-` is part of symbols. Revisit with text objects
in **0.4**.

### `dw` line-crossing is approximated

Vim's rule "`dw` on the last word of a line stops at end of line" is
implemented as "back up one character when the motion lands at the
beginning of a line in operator-pending State". Multi-count `dw` across
lines may differ from Vim in whitespace handling. Polish in **0.3**.

### `j`/`k` forget the goal column

Each `j`/`k` re-reads the current column, so travelling through a short
line loses the original column (Vim remembers the desired column).
Polish in **0.3**.

### `cc` loses indentation

Vim's `cc` with autoindent keeps the line's indentation; ours leaves an
empty line. Polish in **0.3**.
