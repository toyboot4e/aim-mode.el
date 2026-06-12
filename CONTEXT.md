# aim-mode

Yet another Vim mode for Emacs: Vim's everyday grammar guaranteed, Emacs's
own subsystems underneath, built as a small layered kernel with orthogonal
leaves.

## Language

**Common Core**:
The everyday Vim vocabulary that aim-mode guarantees matches Vim behavior —
motions, operators, counts, text objects, and their compositions (`dw`,
`ci(`, `3dd`). Outside the Common Core there is no compatibility promise.
_Avoid_: "Vim compatibility" (overpromises), "Vim emulation"

**State**:
One of aim-mode's editing modes: normal, insert, operator-pending, visual
(char/line/block), replace, motion. A buffer is in exactly one State.
_Avoid_: "mode" (collides with Emacs major/minor modes)

**Kernel**:
The mutually-aware bottom layers: core (States, keymaps), repeat recording,
and the definition macros with the motion type system. Layering inside the
Kernel is one-directional and enforced at byte-compile time.

**Leaf**:
A module depending only on the Kernel (or only core) and on no other Leaf:
motions, operators, text objects, Ex Dispatcher, search glue, kmacro glue,
curated mode bindings. Deletable without touching anything else.

**Ex Dispatcher**:
aim-mode's `:` prompt. Not an ex language — a hand-parsed whitelist of
everyday commands with two fallthroughs: a leading `(` evaluates as an
Emacs Lisp expression; anything unrecognized is offered to `M-x`.
_Avoid_: "ex mode", "command line"

**1.0**:
The first stable release: feature-complete against the Common Core, all six
States, repeat (`.`).

**Milestone**:
An incremental 0.x step toward 1.0. Deliberately minimal, coherent, and
usable; may omit features but may not contradict Common Core behavior.
_Avoid_: "v1" (ambiguous between first step and stable release)

## Example dialogue

> **Dev**: A user reports `:g/foo/d` doesn't work. Bug?
>
> **Maintainer**: No. `:g` is outside the Common Core and the Ex Dispatcher's
> whitelist. They can use the `(` fallthrough or M-x. If we ever want it,
> that's a new whitelist entry — a Leaf change, not a Kernel change.
>
> **Dev**: And `dw` deleting one char too many?
>
> **Maintainer**: That's Common Core — always a bug, fix before the next
> Milestone ships.
