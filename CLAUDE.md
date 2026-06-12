# aim-mode.el

Yet another Vim mode for Emacs. Vim's Common Core guaranteed; Emacs built-in
subsystems underneath; a small layered Kernel with orthogonal Leaves.

## Required reading

- `CONTEXT.md` — the project glossary. Use its terms exactly (Common Core,
  State, Kernel, Leaf, Ex Dispatcher, Milestone, 1.0). When a design question
  arises, check whether the glossary already answers it.
- `docs/adr/` — architecture decision records. Do not contradict an ADR
  without an explicit decision to supersede it.

## Hard rules

- Emacs 30.1 is the floor; zero external runtime dependencies (built-ins
  only: `cl-lib`, `seq`, `pcase`, `subr-x`).
- Kernel layering is one-directional: core → repeat → macros → Leaves.
  `just compile` enforces it via staged byte-compilation; never work around
  a layering failure by reordering the layer list without discussion.
- Every editing command is defined via the `aim-define-*` macros once they
  exist; raw `defun` commands are second-class (no repeat/count support).
- All elisp files: lexical binding, `aim-` public / `aim--` private naming,
  checkdoc-clean docstrings, GPL-3.0-or-later headers.

## Workflow

- `just compile` / `just test` / `just lint` / `just ci` (all of them).
- `nix develop` provides the devShell; `nix run` launches the playground
  Emacs with aim-mode loaded.
- Tests are ERT, written with the declarative buffer harness in
  `test/aim-test-utils.el` (`|` marks point).
