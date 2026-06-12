# aim-mode.el

Yet another Vim mode for Emacs: Vim's everyday grammar (the *Common Core*)
guaranteed, Emacs's own subsystems (isearch, kill-ring, registers, kmacro,
undo) underneath.

Design documents: [CONTEXT.md](./CONTEXT.md) (glossary) and
[docs/adr/](./docs/adr/) (architecture decisions).

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
