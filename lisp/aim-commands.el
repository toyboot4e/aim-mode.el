;;; aim-commands.el --- Simple normal-State commands  -*- lexical-binding: t; -*-

;;; Commentary:

;; Leaf module: normal-State commands that are not operator + motion
;; compositions — insert-State entries, x, paste, and undo glue
;; (docs/adr/0002).  These are plain commands for now; they migrate to
;; the definition macros when the repeat layer lands.
;;
;; Paste decides between charwise and linewise from the killed text: a
;; trailing newline means linewise.  This approximates Vim's register
;; types until registers carry their own type.

;;; Code:

(require 'aim-core)

;;;; Insert-State entries

(defun aim-insert ()
  "Enter insert State at point."
  (interactive)
  (aim-switch-state 'insert))

(defun aim-append ()
  "Enter insert State after the character at point."
  (interactive)
  (unless (eolp) (forward-char))
  (aim-switch-state 'insert))

(defun aim-append-line ()
  "Enter insert State at the end of the line."
  (interactive)
  (goto-char (line-end-position))
  (aim-switch-state 'insert))

(defun aim-insert-line ()
  "Enter insert State at the first non-blank character of the line."
  (interactive)
  (back-to-indentation)
  (aim-switch-state 'insert))

(defun aim-open-below ()
  "Open a line below and enter insert State."
  (interactive)
  (goto-char (line-end-position))
  (aim-switch-state 'insert)
  (insert "\n"))

(defun aim-open-above ()
  "Open a line above and enter insert State."
  (interactive)
  (forward-line 0)
  (aim-switch-state 'insert)
  (insert "\n")
  (forward-line -1))

;;;; Editing

(defun aim-delete-char (count)
  "Kill COUNT characters after point, staying on the current line."
  (interactive "p")
  (let ((end (min (line-end-position) (+ (point) count))))
    (when (< (point) end)
      (kill-region (point) end))))

(defun aim-paste-after (count)
  "Paste the latest kill COUNT times after point.
Linewise text (ending in a newline) goes below the current line."
  (interactive "p")
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

(defun aim-paste-before (count)
  "Paste the latest kill COUNT times before point.
Linewise text (ending in a newline) goes above the current line."
  (interactive "p")
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
