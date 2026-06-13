# aim-mode.el development tasks.  `just ci` runs everything.

emacs := "emacs"
stage := ".stage"

# Kernel layer order, bottom-up.  Each file compiles against ONLY the
# layers before it, so an upward `require` is a hard compile failure
# (docs/adr/0003).  Append new layers/Leaves here in dependency order.
layers := "aim-core aim-repeat aim-macros aim-motions aim-text-objects aim-operators aim-commands aim-visual aim-search aim-ex aim-mode"

default: ci

ci: compile lint test docs-check

ci-nix:
    nix develop -c just ci

[private]
alias c := compile

# Staged byte-compilation with warnings as errors.
[script('bash', '-euo', 'pipefail')]
compile:
    rm -rf "{{ stage }}" && mkdir -p "{{ stage }}"
    for layer in {{ layers }}; do
        cp "lisp/$layer.el" "{{ stage }}/"
        "{{ emacs }}" -Q --batch -L "{{ stage }}" \
            --eval '(setq byte-compile-error-on-warn t)' \
            -f batch-byte-compile "{{ stage }}/$layer.el"
        echo "compiled: $layer"
    done

[private]
alias t := test

# Run the ERT suite in batch.
test:
    "{{ emacs }}" -Q --batch -L lisp -L test \
        -l aim-test-utils -l aim-mode-test \
        -f ert-run-tests-batch-and-exit

[private]
alias l := lint

# package-lint (fails CI) + checkdoc (informational for now).
lint:
    "{{ emacs }}" -Q --batch -l package-lint \
        --eval '(setq package-lint-main-file "lisp/aim-mode.el")' \
        -f package-lint-batch-and-exit lisp/*.el
    "{{ emacs }}" -Q --batch \
        --eval '(dolist (f (directory-files "lisp" t "\\.el$")) (checkdoc-file f))'

[private]
alias f := fmt

# Format the tree (nixfmt under treefmt) via the flake formatter.
fmt:
    nix fmt

[private]
alias a := audit

# zizmor security audit of the GitHub Actions workflows (offline, no token).
audit:
    zizmor --offline .github/workflows

# Verify Actions are pinned to SHAs matching their tags (needs network; `pinact run --update` bumps and re-pins).
pin-check:
    pinact run --check

[private]
alias d := docs

# Regenerate docs/KEYBINDINGS.md from the State keymaps.
docs:
    "{{ emacs }}" -Q --batch -L lisp -l script/gen-keybindings.el

# Fail if docs/KEYBINDINGS.md has drifted from the keymaps (part of `ci`).
[script('bash', '-euo', 'pipefail')]
docs-check:
    out="$(mktemp)"
    trap 'rm -f "$out"' EXIT
    AIM_KEYBINDINGS_OUT="$out" "{{ emacs }}" -Q --batch -L lisp \
        -l script/gen-keybindings.el
    if ! diff -u docs/KEYBINDINGS.md "$out"; then
        echo "docs/KEYBINDINGS.md is stale; run 'just docs' and commit." >&2
        exit 1
    fi

[private]
alias r := run

# Launch the playground Emacs (what `nix run` does, from the working tree).
run:
    "{{ emacs }}" -Q -L lisp -l aim-mode --eval '(aim-playground)'

clean:
    rm -rf "{{ stage }}" lisp/*.elc test/*.elc
