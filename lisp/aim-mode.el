;;; aim-mode.el --- Yet another Vim mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 toyboot4e

;; Author: toyboot4e <toyboot4e@gmail.com>
;; Maintainer: toyboot4e <toyboot4e@gmail.com>
;; Version: 0.2.0
;; Package-Requires: ((emacs "30.1"))
;; Keywords: emulations
;; URL: https://github.com/toyboot4e/aim-mode.el
;; SPDX-License-Identifier: CC0-1.0

;;; Commentary:

;; Yet another Vim mode: Vim's Common Core guaranteed, Emacs built-in
;; subsystems underneath.  See CONTEXT.md for the project glossary and
;; docs/adr/ for the architecture decisions.
;;
;; This umbrella file wires the Kernel and the Leaves together and owns
;; all default keybindings.
;;
;; Known limitation: ESC is bound as a raw character, so Meta chords
;; typed as ESC-prefixed sequences (terminal Emacs) are shadowed in
;; insert State.  The `input-decode-map' treatment comes in a later
;; Milestone.

;;; Code:

(require 'aim-core)
(require 'aim-repeat)
(require 'aim-macros)
(require 'aim-motions)
(require 'aim-operators)
(require 'aim-commands)

;;;; Default bindings

(define-keymap :keymap aim-motion-map
  "h" #'aim-backward-char
  "l" #'aim-forward-char
  "j" #'aim-next-line
  "k" #'aim-previous-line
  "w" #'aim-forward-word-begin
  "b" #'aim-backward-word-begin
  "e" #'aim-forward-word-end
  "0" #'aim-line-beginning
  "^" #'aim-first-non-blank
  "$" #'aim-line-end
  "g g" #'aim-goto-first-line
  "G" #'aim-goto-line
  "f" #'aim-find-char
  "F" #'aim-find-char-backward
  "t" #'aim-find-char-to
  "T" #'aim-find-char-to-backward
  ";" #'aim-repeat-find
  "," #'aim-repeat-find-reverse)

(dotimes (i 9)
  (keymap-set aim-motion-map (number-to-string (1+ i)) #'digit-argument))

(define-keymap :keymap aim-normal-state-map
  "d" #'aim-delete
  "c" #'aim-change
  "y" #'aim-yank
  ">" #'aim-shift-right
  "<" #'aim-shift-left
  "x" #'aim-delete-char
  "p" #'aim-paste-after
  "P" #'aim-paste-before
  "D" #'aim-kill-line-rest
  "C" #'aim-change-line-rest
  "Y" #'aim-copy-line
  "r" #'aim-replace-char
  "~" #'aim-invert-char-case
  "J" #'aim-join-lines
  "u" #'aim-undo
  "C-r" #'aim-redo
  "." #'aim-repeat
  "i" #'aim-insert
  "a" #'aim-append
  "A" #'aim-append-line
  "I" #'aim-insert-line
  "o" #'aim-open-below
  "O" #'aim-open-above)

(keymap-set aim-insert-state-map "ESC" #'aim-normal-state)
(keymap-set aim-operator-state-map "ESC" #'keyboard-quit)

;;;; Minor mode

;;;###autoload
(define-minor-mode aim-mode
  "Toggle aim-mode in the current buffer."
  :lighter (:eval (format " aim[%s]"
                          (or (alist-get aim-state aim--state-tags) "-")))
  (if aim-mode
      (aim-switch-state 'normal)
    (aim--disable)))

;;;###autoload
(define-globalized-minor-mode aim-global-mode aim-mode aim--turn-on
  :group 'aim)

(defun aim--turn-on ()
  "Enable `aim-mode' except in the minibuffer."
  (unless (or aim-mode (minibufferp))
    (aim-mode 1)))

;;;###autoload
(defun aim-playground ()
  "Open a scratch buffer with `aim-mode' enabled.

This is the entry point used by `nix run'."
  (interactive)
  (let ((buffer (get-buffer-create "*aim-playground*")))
    (with-current-buffer buffer
      (when (zerop (buffer-size))
        (insert "aim-mode playground -- Milestone 0.2 (Kernel tracer bullet)\n"
                "Try: h j k l w b e 0 ^ $ gg G f t / d c y with counts,\n"
                "dd yy p P x u, and i a A I o O with ESC.\n"))
      (text-mode)
      (aim-mode 1))
    (pop-to-buffer buffer)))

(provide 'aim-mode)
;;; aim-mode.el ends here
