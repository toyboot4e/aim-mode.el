# aim-mode vs Vim

What of Vim's everyday vocabulary (the *Common Core*, see CONTEXT.md)
aim-mode covers, and where it deliberately differs. Full key list:
[KEYBINDINGS.md](./KEYBINDINGS.md). Known limitations:
[CAVEATS.md](./CAVEATS.md).

## Covered

**States** — normal, insert, operator-pending, visual (char/line/block),
replace, motion.

**Motions** — `h j k l`, `w b e W B E`, `0 ^ $ g_ |`, `+ - _`,
`gj gk`, `f F t T ; ,`, `gg G`, `{ } ( )`, `%`, `H M L`, `C-d C-u`,
`[[ ]] [] ][`, `/ ? n N *`, marks `` ` `` `'` `` `` `` with `m`.

**Operators** — `d c y`, `> <`, `= `, `gu gU g~`, `gq gw`, `!`. All
compose with motions, counts, and text objects; doubled forms
(`dd`, `guu`, `==`, `!!`) act linewise.

**Text objects** — `iw aw iW aW`, `i( i[ i{ i< i" i' i\``  (and `a`
variants, with `b`/`B` aliases), `ip ap`, `is as`, `it at`.

**Edits** — `x s S r ~ J gJ`, `D C Y`, `p P gp gP`, `o O i a A I gi`,
`R`, `u C-r`, `.`, `C-a`/`g C-x` (increment/decrement).

**Registers & macros** — `"a`–`"z` (Emacs registers), `q`/`@`/`@@`.

**Visual** — `v V C-v`, `o`, `gv`, operators and text objects over the
selection, block `I`/`A`/`c`/`p`.

**Ex** — `:w :q :q! :wq :x :e :<line> :$`, `:[range]s/pat/rep/[g]`,
`:(sexp)` evaluation, M-x fallthrough; `& g&`, `ZZ ZQ`.

## Deliberate divergences

These are by design (see CAVEATS.md for the full rationale):

- **Emacs subsystems underneath** (ADR 0002): undo is Emacs
  `undo`/`undo-redo`; `/` is isearch; registers are Emacs registers;
  `:s///` and search use **Emacs regular expressions**, never Vim's
  dialect.
- **Cursor model**: point sits between characters, so `$` rests after
  the last character and `l` can reach end of line. Operator ranges
  still match Vim.
- **Text objects are char-based** (like Vim's own), not syntax-aware —
  structural awareness is left to user-side tree-sitter.
- **`.` replays recorded input**, so a change that reads from a
  completion UI may diverge on repeat.

## Out of scope (deferred past 1.0)

- Changelist `g;`/`g,`.
- Vim-style insert-State chords — insert State is plain Emacs, whose
  built-ins (`C-w`, `C-y`, `M-DEL`, …) are the equivalents.
- `$A` ragged block append (fixed-column block edits are covered).
- The ex *language* beyond the dispatcher whitelist (`:g`, `:normal`,
  marks-in-ranges, …) — use the `:(sexp)` escape hatch or M-x.
