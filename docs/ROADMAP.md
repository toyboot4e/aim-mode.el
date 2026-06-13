# Roadmap

Milestones toward 1.0 (see CONTEXT.md for the Milestone and 1.0
definitions). Ordering follows the dependency structure in docs/adr/0003:
the repeat layer slots into the Kernel before more commands accrete, then
features grow leaf by leaf. Scope per milestone is a guide, not a
contract — but nothing shipped may contradict Common Core behavior.

Done so far:

- **0.1** — tooling: flake.nix (`nix run` playground), Justfile with
  layering-enforced staged compilation, ERT buffer harness, CI.
- **0.2** — Kernel tracer bullet: normal/insert/operator-pending States,
  motion/operator macros with the type system, counts, core motions,
  `d`/`c`/`y` (+ `dd`/`cc`/`yy`), `x p P u`, insert entries, undo grouping.
- **0.3** — repeat layer (`.` with count override, insert-session
  recording, operator transcripts) as a Kernel layer between core and
  macros; Vim's exclusive-motion adjustment rules; `cw` as `ce`; sticky
  goal column; `cc` keeps indent; `D C Y r ~ J`, `>` `<`, `;` `,`.
- **0.4** — `aim-define-text-object` macro and the i/a objects (word,
  WORD, pairs, quotes, paragraph); syntax-table word vocabulary;
  `W B E` motions. (`t` tag objects deferred.)
- **0.5** — visual States, char and line: selections over Emacs's
  region, operators take the selection as their range, `o` swaps ends,
  `gv` restores, i/a select text objects. (Visual `p` — paste over
  selection — deferred to the register milestone.)
- **0.6** — `/ ? n N *` as isearch glue with Vim wraparound and
  match-start landing; marks `m` `` ` `` `'` over Emacs registers with
  the `` `` `` last-jump mark; `{ } ( ) % H M L C-d C-u` motions.
- **0.7** — the Ex Dispatcher: whitelist (`w q q! wq x e <line> $`,
  `[range]s/pat/rep/[g]`), `(sexp)` evaluation, M-x fallthrough;
  visual `:s` over the selection.
- **0.8** — typed kills (char/line text property; paste stops
  guessing), `"a`–`"z` over Emacs registers, visual `p` over the
  selection, `q`/`@` kmacro glue with `@@` and counts.
- **0.9** — replace State (backspace-restore, repeat, one undo step);
  motion State; `aim-define-key` with per-major-mode auxiliary
  keymaps (and normal State no longer self-inserts unbound keys);
  visual block with block-typed kills/paste; instant terminal ESC via
  an `input-decode-map` filter. Curated `aim-x-*.el` modules deferred
  until concrete per-mode preferences exist.

## Toward 1.0 — exhaustive daily-driver parity (shipped)

1.0 means feature-complete against everyday Vim usage (CONTEXT.md's
Common Core), reached over several Milestones. Every feature below is a
Leaf built on the public API (`aim-define-operator/motion/command/
text-object` + `aim-define-key`) — never in `aim-core.el`; the only
Kernel touches were the doubled-key generalization (0.10) and the
repeat-prefix fix (0.14). Each Milestone self-tests and ships green.

- **0.10 — operators**: case `gu` `gU` `g~` (+ doubled linewise forms,
  + visual `u` `U` `~`); `=` reindent (+ `==` + visual); `gq`/`gw`
  reformat; `!` filter through a shell command.
- **0.11 — commands & small motions**: `s`/`S`, `gJ` (join no space);
  `gp`/`gP` (paste and advance); `gi` (insert at last edit position);
  `&`/`g&` (repeat `:s`); `ZZ`/`ZQ`; increment/decrement commands bound
  to `C-a` and `g C-x` (the Emacs `C-x` prefix is preserved — a
  case-by-case call per ADR 0001); motions `gj` `gk` `g_` `|` `+` `-`
  `_`, and section motions `[[` `]]` `[]` `][`.
- **0.12 — text objects**: tag `it`/`at` (nested char-based matching)
  and sentence `is`/`as`. Objects stay char-scan by design (see
  CAVEATS); structural awareness is left to user-side tree-sitter.
- **0.13 — block completion**: block `I`/`A` insert replicated down the
  block; block `c` replicated; visual `p` over a block selection; a
  per-line rectangle highlight. Clears all block caveats.
- **0.14 — repeat fix**: the `"` register prefix enters the repeat
  record, so `"adw` repeats faithfully (clears that caveat). The one
  Kernel change in the 1.0 run.
- **0.15 — docs & packaging**: expand README; add a generated
  `docs/KEYBINDINGS.md` (every binding per State, derived from the
  keymaps so it cannot drift) and `docs/VIM-COMPARISON.md` (coverage
  and deliberate divergences, cross-referencing CAVEATS); make the
  package MELPA-ready (package-lint clean, autoload audit, metadata).
  Actual MELPA submission is a manual step (needs the public repo and a
  recipe PR).

## 1.0 — release (ready)

0.10–0.15 have shipped and docs/CAVEATS.md holds only permanent
(by-design) entries — no unresolved temporary caveats. The package is
feature-complete against the Common Core and ready to tag 1.0.
Remaining manual step: the MELPA recipe PR (needs the public repo).

## Post-1.0 ideas

- Changelist `g;`/`g,`.
- Vim-style insert-State chords (insert State stays plain Emacs today).
- Optional syntax-aware / tree-sitter text objects as a Leaf.
- Curated `aim-x-*.el` per-major-mode bindings.
