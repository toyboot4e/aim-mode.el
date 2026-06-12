# An evil-shaped Kernel, implemented fresh with enforced layering

The Kernel copies evil's proven architecture rather than depending on evil or
inventing a new model: States activate keymaps via `emulation-mode-map-alists`
(reliably outranking minor-mode maps), operator-pending is a real State,
commands are defined through `aim-define-operator` / `aim-define-motion` /
`aim-define-text-object` macros, motions declare a type
(exclusive/inclusive/linewise) that mediates between motions and operators,
and `.` repeat works by recording the last editing command plus insert-state
input at the macro layer — which is why repeat was designed before any command
was written. We rejected depending on evil (its size and full-fidelity
mandate are what aim-mode exists to avoid), minor-mode-per-state keymaps
(meow's approach; loses precedence fights), and a Kakoune-style
selection-first core under a Vim veneer (breeds subtle Common Core
incompatibilities).

The Kernel layers are one-directional — core → repeat → macros, with Leaves
on top — and the ordering is enforced mechanically: `just compile` builds
files in layer order, each in a fresh `emacs -Q -batch` whose load path
contains only already-compiled lower layers (an upward `require` cannot
load), with `byte-compile-error-on-warn` catching calls into layers never
required. Normal state is the default everywhere, including special buffers
(dired, magit, help); core ships the per-major-mode auxiliary keymap
mechanism, and curated bindings for specific modes live in separate
`aim-x-*.el` Leaf files, not in the Kernel.

## Consequences

- Every editing command must be defined via the Kernel macros to get repeat,
  counts, and type handling for free; raw `defun` commands are second-class.
- Visual-block support means every operator eventually handles a blockwise
  range case — accepted, scheduled for a later Milestone.
- An illegal dependency is a compile failure, not a review comment.
