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

## 1.0 — Common Core completeness

- Feature-complete against CONTEXT.md's Common Core definition: audit
  motions/operators/text objects/counts against everyday Vim usage.
- Repeat works for every editing command; no temporary caveats left in
  docs/CAVEATS.md.
- Documentation pass; MELPA-ready packaging.
