# aim-mode.el development tasks.  `just ci` runs everything.

emacs := "emacs"
stage := ".stage"

# Kernel layer order, bottom-up.  Each file compiles against ONLY the
# layers before it, so an upward `require` is a hard compile failure
# (docs/adr/0003).  Append new layers/Leaves here in dependency order.
layers := "aim-core aim-repeat aim-macros aim-motions aim-text-objects aim-operators aim-commands aim-visual aim-mode"

default: ci

ci: compile lint test

# Staged byte-compilation with warnings as errors.
[private]
alias c := compile
compile:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf "{{ stage }}" && mkdir -p "{{ stage }}"
    for layer in {{ layers }}; do
        cp "lisp/$layer.el" "{{ stage }}/"
        "{{ emacs }}" -Q --batch -L "{{ stage }}" \
            --eval '(setq byte-compile-error-on-warn t)' \
            -f batch-byte-compile "{{ stage }}/$layer.el"
        echo "compiled: $layer"
    done

# Run the ERT suite in batch.
[private]
alias t := test
test:
    "{{ emacs }}" -Q --batch -L lisp -L test \
        -l aim-test-utils -l aim-mode-test \
        -f ert-run-tests-batch-and-exit

# package-lint (fails CI) + checkdoc (informational for now).
[private]
alias l := lint
lint:
    "{{ emacs }}" -Q --batch -l package-lint \
        --eval '(setq package-lint-main-file "lisp/aim-mode.el")' \
        -f package-lint-batch-and-exit lisp/*.el
    "{{ emacs }}" -Q --batch \
        --eval '(dolist (f (directory-files "lisp" t "\\.el$")) (checkdoc-file f))'

# Launch the playground Emacs (what `nix run` does, from the working tree).
[private]
alias r := run
run:
    "{{ emacs }}" -Q -L lisp -l aim-mode --eval '(aim-playground)'

clean:
    rm -rf "{{ stage }}" lisp/*.elc test/*.elc
