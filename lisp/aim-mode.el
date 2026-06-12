;;; aim-mode.el --- Yet another Vim mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 toyboot4e

;; Author: toyboot4e <toyboot4e@gmail.com>
;; Maintainer: toyboot4e <toyboot4e@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "30.1"))
;; Keywords: emulations
;; URL: https://github.com/toyboot4e/aim-mode.el
;; SPDX-License-Identifier: CC0-1.0

;;; Commentary:

;; Yet another Vim mode: Vim's Common Core guaranteed, Emacs built-in
;; subsystems underneath.  See CONTEXT.md for the project glossary and
;; docs/adr/ for the architecture decisions.
;;
;; Milestone 0.1 is the tooling milestone: this file is a stub that
;; proves the compile/test/lint/run pipeline end to end.

;;; Code:

(require 'aim-core)

;;;###autoload
(define-minor-mode aim-mode
  "Toggle aim-mode in the current buffer.

Milestone 0.1 stub: enabling the mode only tracks `aim-state';
no keybindings are installed yet."
  :lighter (:eval (format " aim[%s]" (or aim-state "-")))
  (setq aim-state (and aim-mode 'normal)))

;;;###autoload
(defun aim-playground ()
  "Open a scratch buffer with `aim-mode' enabled.

This is the entry point used by `nix run'."
  (interactive)
  (let ((buffer (get-buffer-create "*aim-playground*")))
    (with-current-buffer buffer
      (when (zerop (buffer-size))
        (insert "aim-mode playground -- Milestone 0.1 (tooling)\n"
                "aim-mode is enabled here, but installs no keybindings yet.\n\n"))
      (text-mode)
      (aim-mode 1))
    (pop-to-buffer buffer)))

(provide 'aim-mode)
;;; aim-mode.el ends here
