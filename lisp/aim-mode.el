;;; aim-mode.el --- Yet another Vim mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 toyboot4e

;; Author: toyboot4e <toyboot4e@gmail.com>
;; Maintainer: toyboot4e <toyboot4e@gmail.com>
;; Version: 1.0.0
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
(require 'aim-text-objects)
(require 'aim-operators)
(require 'aim-commands)
(require 'aim-visual)
(require 'aim-search)
(require 'aim-ex)

;;;; Default bindings

(define-keymap :keymap aim-motion-map
  "h" #'aim-backward-char
  "l" #'aim-forward-char
  "j" #'aim-next-line
  "k" #'aim-previous-line
  "w" #'aim-forward-word-begin
  "b" #'aim-backward-word-begin
  "e" #'aim-forward-word-end
  "W" #'aim-forward-bigword-begin
  "B" #'aim-backward-bigword-begin
  "E" #'aim-forward-bigword-end
  "0" #'aim-line-beginning
  "^" #'aim-first-non-blank
  "$" #'aim-line-end
  "g g" #'aim-goto-first-line
  "g j" #'aim-next-visual-line
  "g k" #'aim-previous-visual-line
  "g _" #'aim-last-non-blank
  "|" #'aim-goto-column
  "+" #'aim-next-line-non-blank
  "-" #'aim-previous-line-non-blank
  "_" #'aim-current-line-non-blank
  "[ [" #'aim-backward-section
  "] ]" #'aim-forward-section
  "[ ]" #'aim-backward-section-end
  "] [" #'aim-forward-section-end
  "G" #'aim-goto-line
  "f" #'aim-find-char
  "F" #'aim-find-char-backward
  "t" #'aim-find-char-to
  "T" #'aim-find-char-to-backward
  ";" #'aim-repeat-find
  "," #'aim-repeat-find-reverse
  "{" #'aim-backward-paragraph
  "}" #'aim-forward-paragraph
  "(" #'aim-backward-sentence
  ")" #'aim-forward-sentence
  "%" #'aim-matching-pair
  "H" #'aim-window-top
  "M" #'aim-window-middle
  "L" #'aim-window-bottom
  "C-d" #'aim-scroll-down
  "C-u" #'aim-scroll-up
  "`" #'aim-goto-marker
  "'" #'aim-goto-marker-line
  "n" #'aim-search-next
  "N" #'aim-search-previous
  "*" #'aim-search-symbol-forward)

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
  "O" #'aim-open-above
  "v" #'aim-visual-char
  "V" #'aim-visual-line
  "C-v" #'aim-visual-block
  "g v" #'aim-visual-restore
  "g u" #'aim-downcase
  "g U" #'aim-upcase
  "g ~" #'aim-swap-case
  "g q" #'aim-reformat
  "g w" #'aim-reformat-keep
  "g p" #'aim-paste-after-advance
  "g P" #'aim-paste-before-advance
  "g J" #'aim-join-lines-no-space
  "g i" #'aim-insert-at-last-edit
  "s" #'aim-substitute-char
  "S" #'aim-substitute-line
  "=" #'aim-reindent
  "!" #'aim-filter
  "C-a" #'aim-increment
  "g C-x" #'aim-decrement
  "&" #'aim-ex-repeat-substitute
  "g &" #'aim-ex-repeat-substitute-buffer
  "Z Z" #'aim-write-quit
  "Z Q" #'aim-quit-no-write
  "R" #'aim-replace-state
  "m" #'aim-set-marker
  "/" #'aim-search-forward
  "?" #'aim-search-backward
  ":" #'aim-ex
  "\"" #'aim-use-register
  "q" #'aim-record-macro
  "@" #'aim-execute-macro)

(define-keymap :keymap aim-visual-state-map
  "ESC" #'aim-visual-exit
  "v" #'aim-visual-char
  "V" #'aim-visual-line
  "C-v" #'aim-visual-block
  "o" #'aim-visual-exchange
  "i" #'aim-visual-object
  "a" #'aim-visual-object
  "I" #'aim-visual-insert
  "A" #'aim-visual-append
  "$" #'aim-visual-end-of-line
  "d" #'aim-delete
  "x" #'aim-delete
  "c" #'aim-visual-change
  "s" #'aim-visual-change
  "y" #'aim-yank
  ">" #'aim-shift-right
  "<" #'aim-shift-left
  "u" #'aim-downcase
  "U" #'aim-upcase
  "~" #'aim-swap-case
  "=" #'aim-reindent
  "g q" #'aim-reformat
  "g w" #'aim-reformat-keep
  "!" #'aim-filter
  ":" #'aim-ex
  "p" #'aim-visual-paste
  "\"" #'aim-use-register)

;; Both the raw ESC character and the <escape> event (GUI frames, and
;; ttys via the input-decode filter) must be bound.
(dolist (key '("ESC" "<escape>"))
  (keymap-set aim-insert-state-map key #'aim-normal-state)
  (keymap-set aim-operator-state-map key #'keyboard-quit)
  (keymap-set aim-replace-state-map key #'aim-normal-state)
  (keymap-set aim-visual-state-map key #'aim-visual-exit))
(keymap-set aim-replace-state-map "DEL" #'aim-replace-backspace)

;; Vim's insert-State C-w deletes the word before point (Emacs's C-w is
;; kill-region).  Other insert chords stay plain Emacs (see CAVEATS).
(keymap-set aim-insert-state-map "C-w" #'backward-kill-word)
(keymap-set aim-replace-state-map "C-w" #'backward-kill-word)

;; Text objects, read in operator-pending State.
(dolist (entry '(("w" . "word")
                 ("W" . "bigword")
                 ("(" . "paren") (")" . "paren") ("b" . "paren")
                 ("[" . "bracket") ("]" . "bracket")
                 ("{" . "brace") ("}" . "brace") ("B" . "brace")
                 ("<" . "angle") (">" . "angle")
                 ("\"" . "double-quote")
                 ("'" . "single-quote")
                 ("`" . "back-quote")
                 ("p" . "paragraph")
                 ("s" . "sentence")
                 ("t" . "tag")))
  (keymap-set aim-operator-state-map (concat "i " (car entry))
              (intern (format "aim-inner-%s" (cdr entry))))
  (keymap-set aim-operator-state-map (concat "a " (car entry))
              (intern (format "aim-outer-%s" (cdr entry)))))

;;;; Minor mode

;;;###autoload
(define-minor-mode aim-mode
  "Toggle aim-mode in the current buffer."
  :lighter (:eval (aim-mode-line-string))
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
        (insert "aim-mode playground -- 1.0\n"
                "States: v V C-v visual, R replace, i insert; ESC leaves.\n"
                "Motions: h j k l w b e W B E 0 ^ $ g_ | + - _ gj gk gg G\n"
                "  f F t T ; , { } ( ) % H M L C-d C-u [[ ]]; / ? n N *; m `a 'a.\n"
                "Operators: d c y > < = gu gU g~ gq gw ! (doubled: dd guu == !!).\n"
                "Commands: x s S r ~ J gJ D C Y p P gp gP gi C-a g-C-x . u C-r.\n"
                "Text objects: iw aw i( a\" it at is as ip ...\n"
                "Visual: v V C-v; block I A c p; o gv; Ex: :%s/// :(sexp) & ZZ.\n"))
      (text-mode)
      (aim-mode 1))
    (pop-to-buffer buffer)))

(provide 'aim-mode)
;;; aim-mode.el ends here
