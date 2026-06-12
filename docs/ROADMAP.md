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

## 0.5 — Visual States (char + line)

- `v` and `V` over Emacs's region; operators act on the selection; text
  objects extend it.
- `gv`, `o` (swap ends); region-based Emacs commands work on visual
  selections for free.

## 0.6 — Search and marks

- `/ ? n N *` as thin isearch glue (docs/adr/0002); Emacs regex by design.
- `m`, `` ` ``, `'` over Emacs markers in registers; `` `` ``/`''`
  (last-jump) special marks.
- Paragraph/sentence/scroll motions: `{ } ( )`, `%`, `C-d C-u`, `H M L`.

## 0.7 — Ex Dispatcher

- `:` minibuffer dispatcher (docs/adr/0002): whitelist `w q wq e <line>`
  and `[range]s/pat/rep/[g]` over numbers/`%`/`.`/`$` ranges, translated
  to Emacs replace commands.
- Fallthroughs: leading `(` evaluates as Emacs Lisp; unrecognized input
  is offered to `M-x`.

## 0.8 — Registers and kmacros

- `"a`–`"z` map onto Emacs registers; unnamed register stays the
  kill-ring head. Register *types* (charwise/linewise) retire the paste
  heuristic caveat.
- `q`/`@` as kmacro glue: `qa` records into register `a`, `@a` executes,
  `@@` repeats.

## 0.9 — Remaining States and integration

- Visual block (`C-v`) on rectangle functions — every operator grows a
  blockwise case.
- Replace State (`R`) over `overwrite-mode` with backspace-restore.
- Motion State for read-only contexts.
- `aim-define-key` with per-major-mode auxiliary keymaps; first curated
  `aim-x-*.el` Leaves (normal State everywhere needs them).
- Terminal ESC via `input-decode-map` timeout (retires the Meta caveat).

## 1.0 — Common Core completeness

- Feature-complete against CONTEXT.md's Common Core definition: audit
  motions/operators/text objects/counts against everyday Vim usage.
- Repeat works for every editing command; no temporary caveats left in
  docs/CAVEATS.md.
- Documentation pass; MELPA-ready packaging.
