# aim-mode.el

Yet another Vim mode for Emacs: Vim's everyday grammar (the *Common Core*)
guaranteed, Emacs's own subsystems (isearch, kill-ring, registers, kmacro,
undo) underneath. A small layered Kernel with orthogonal Leaves; zero
external dependencies; Emacs 30.1+.

## Philosophy

- **Common Core, not full emulation.** The everyday Vim vocabulary —
  motions, operators, counts, text objects and their compositions — is
  guaranteed to match Vim. Outside it there is no compatibility promise.
- **Reuse Emacs, don't reimplement it.** Undo, search, registers,
  macros and marks are thin glue over the Emacs subsystems, so they
  interoperate with the rest of your config. Consequently `:s///` and
  `/` use Emacs regular expressions, not Vim's.
- **Built on a public API.** Every command is defined through
  `aim-define-operator` / `aim-define-motion` / `aim-define-command` /
  `aim-define-text-object` and bound with `aim-define-key` — the same
  tools you'd use to extend it.

## Status

Approaching 1.0 (exhaustive Common Core coverage). See
[docs/ROADMAP.md](./docs/ROADMAP.md).

## Documentation

- [docs/VIM-COMPARISON.md](./docs/VIM-COMPARISON.md) — what's covered and
  how it differs from Vim.
- [docs/KEYBINDINGS.md](./docs/KEYBINDINGS.md) — every binding per State
  (generated from the keymaps).
- [CONTEXT.md](./CONTEXT.md) — project glossary.
- [docs/adr/](./docs/adr/) — architecture decisions.
- [docs/CAVEATS.md](./docs/CAVEATS.md) — known/by-design divergences.

## Install

Emacs 30.1+. With a checkout on `load-path`:

```elisp
(require 'aim-mode)
(aim-global-mode 1)          ; enable everywhere, or M-x aim-mode per buffer
```

## State indicator

The current State shows in the mode line with a per-State face
(`NORMAL`, `INSERT`, `VISUAL`/`V-LINE`/`V-BLOCK`, `O-PEND`, `REPLACE`,
`MOTION`), and the cursor shape changes per State (`aim-state-cursors`).
The faces (`aim-normal-state-face` …) inherit from semantic faces, so
themes restyle them. For a custom mode line, embed the segment yourself:

```elisp
(aim-mode-line-string)   ; → a propertized " NORMAL " etc.
```

## Try it

```sh
nix run github:toyboot4e/aim-mode.el   # or `nix run .` from a checkout
```

## Develop

```sh
nix develop        # devShell: Emacs (with package-lint) + just
just ci            # compile (staged, layering-enforced) + lint + test
just run           # playground Emacs from the working tree
```

Kernel layering (`core → repeat → macros → Leaves`) is enforced at
byte-compile time: `just compile` builds each file against only the layers
below it, so an upward `require` fails the build.

## License

CC0-1.0 (public-domain dedication). Because aim-mode is not GPL, no code is
ever copied from GPL projects (evil, Emacs itself) — architecture and ideas
only; see docs/adr/0004.
