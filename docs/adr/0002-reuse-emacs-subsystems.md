# Reuse Emacs subsystems as thin glue, not reimplementations

Where Vim has a subsystem Emacs also has, aim-mode wraps the Emacs one:
undo is Emacs `undo`/`undo-redo` plus `undo-amalgamate-change-group` so one
operator or insert session is one undo step; `/` and `n`/`N` wrap isearch;
the unnamed register is the kill-ring head and `"a`–`"z` are Emacs registers
(shared with `C-x r`); `q`/`@` record and execute kmacros stored in registers;
marks are Emacs markers in registers. The Ex Dispatcher is a hand-parsed
whitelist (`:w`, `:q`, `:wq`, `:e`, `:<line>`, `:[range]s///` with ranges
limited to numbers/`%`/`.`/`$`) with two fallthroughs: a leading `(` is
evaluated as elisp, anything else is offered to M-x.

We inspected evil-ex.el before deciding: its 940 lines are a grammar-driven
parser whose weight is ranges/marks/offsets/embedded searches — while the one
feature we wanted from it, `:(sexp)` evaluation, is a single grammar production
(~3 lines anywhere). That asymmetry generalizes: the Vim-faithful versions of
these subsystems are each large, and the Emacs ones are already maintained,
already integrated with the rest of the user's setup, and free.

## Consequences

- Vim regex never works in aim-mode; the regex dialect is always Emacs's.
- Kill-ring history (`M-y`-style), isearch extensions, and `C-x r` registers
  interoperate with aim-mode for free.
- Known divergences from Vim in these areas are by design, not bugs (ADR 0001).
