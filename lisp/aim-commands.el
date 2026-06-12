;;; aim-commands.el --- Simple normal-State commands  -*- lexical-binding: t; -*-

;;; Commentary:

;; Leaf module: normal-State commands that are not operator + motion
;; compositions — insert-State entries, x, paste, and undo glue
;; (docs/adr/0002).  All editing commands are defined through
;; `aim-define-command' so `.' can repeat them; undo/redo stay plain
;; commands because Vim's `.' does not repeat undo.
;;
;; Paste decides between charwise and linewise from the killed text: a
;; trailing newline means linewise.  This approximates Vim's register
;; types until registers carry their own type.

;;; Code:

(require 'aim-macros)

;;;; Insert-State entries

(aim-define-command aim-insert ()
  "Enter insert State at point."
  (aim-switch-state 'insert))

(aim-define-command aim-append ()
  "Enter insert State after the character at point."
  (unless (eolp) (forward-char))
  (aim-switch-state 'insert))

(aim-define-command aim-append-line ()
  "Enter insert State at the end of the line."
  (goto-char (line-end-position))
  (aim-switch-state 'insert))

(aim-define-command aim-insert-line ()
  "Enter insert State at the first non-blank character of the line."
  (back-to-indentation)
  (aim-switch-state 'insert))

(aim-define-command aim-open-below ()
  "Open a line below and enter insert State."
  (goto-char (line-end-position))
  (aim-switch-state 'insert)
  (insert "\n"))

(aim-define-command aim-open-above ()
  "Open a line above and enter insert State."
  (forward-line 0)
  (aim-switch-state 'insert)
  (insert "\n")
  (forward-line -1))

;;;; Editing

(aim-define-command aim-delete-char (count)
  "Kill COUNT characters after point, staying on the current line."
  :interactive "p"
  (let ((end (min (line-end-position) (+ (point) count))))
    (when (< (point) end)
      (kill-region (point) end))))

(aim-define-command aim-paste-after (count)
  "Paste the latest kill COUNT times after point.
Linewise text (ending in a newline) goes below the current line."
  :interactive "p"
  (let ((text (current-kill 0)))
    (if (string-suffix-p "\n" text)
        (progn
          (forward-line 1)
          (unless (bolp) (insert "\n"))
          (let ((pt (point)))
            (dotimes (_ count) (insert text))
            (goto-char pt)
            (back-to-indentation)))
      (unless (eolp) (forward-char))
      (dotimes (_ count) (insert text))
      (backward-char))))

(aim-define-command aim-paste-before (count)
  "Paste the latest kill COUNT times before point.
Linewise text (ending in a newline) goes above the current line."
  :interactive "p"
  (let ((text (current-kill 0)))
    (if (string-suffix-p "\n" text)
        (progn
          (forward-line 0)
          (let ((pt (point)))
            (dotimes (_ count) (insert text))
            (goto-char pt)
            (back-to-indentation)))
      (dotimes (_ count) (insert text))
      (backward-char))))

;;;; Undo

(defun aim-undo (count)
  "Undo COUNT changes."
  (interactive "p")
  (undo count))

(defun aim-redo (count)
  "Redo COUNT undone changes."
  (interactive "p")
  (undo-redo count))

(provide 'aim-commands)
;;; aim-commands.el ends here
