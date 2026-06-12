# The Common Core contract, not full Vim emulation

aim-mode guarantees Vim behavior only for the Common Core — everyday motions,
operators, counts, text objects, and their compositions. Everything outside it
(ex language, Vim regex, visual-block corner cases, obscure registers) carries
no compatibility promise and is decided case-by-case, with no blanket rule for
whether Vim semantics or Emacs built-ins win. We chose this over evil's
"Vim behavior is the spec" stance because the long tail of fidelity is where
evil's size and complexity come from, and over pure inspiration (meow/kakoune)
because existing Vim muscle memory should just work day to day.

## Consequences

- "Is this a bug?" is answered by asking "is it Common Core?" — see CONTEXT.md.
- Case-by-case decisions made so far: undo = Emacs `undo`/`undo-redo` with
  change-group amalgamation; search = thin isearch wrapper (Emacs regex);
  unnamed register = kill-ring, named registers = Emacs registers;
  `:` = thin dispatcher (ADR 0002 records the reuse principle behind these).
