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
(require 'kmacro)

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
      (kill-region (point) end)
      (aim--kill-finish 'char))))

(defun aim--insert-linewise (text count)
  "Insert TEXT as lines COUNT times at point (must be at a line start)."
  (let ((pt (point)))
    (dotimes (_ count)
      (insert text)
      (unless (string-suffix-p "\n" text)
        (insert "\n")))
    (goto-char pt)
    (back-to-indentation)))

(aim-define-command aim-paste-after (count)
  "Paste COUNT times after point, from the pending register or the kill-ring.
Linewise text goes below the current line."
  :interactive "p"
  (let ((text (aim--paste-text)))
    (if (aim--text-linewise-p text)
        (progn
          (forward-line 1)
          (unless (bolp) (insert "\n"))
          (aim--insert-linewise text count))
      (unless (eolp) (forward-char))
      (dotimes (_ count) (insert text))
      (backward-char))))

(aim-define-command aim-paste-before (count)
  "Paste COUNT times before point, from the pending register or the kill-ring.
Linewise text goes above the current line."
  :interactive "p"
  (let ((text (aim--paste-text)))
    (if (aim--text-linewise-p text)
        (progn
          (forward-line 0)
          (aim--insert-linewise text count))
      (dotimes (_ count) (insert text))
      (backward-char))))

(defun aim-use-register ()
  "Select the register for the next kill or paste (Vim's \" prefix)."
  (interactive)
  (setq aim--pending-register (aim--read-char "\"-")))

(aim-define-command aim-kill-line-rest (count)
  "Kill to the end of the line, COUNT - 1 lines below (Vim's D)."
  :interactive "p"
  (kill-region (point) (line-end-position count))
  (aim--kill-finish 'char))

(aim-define-command aim-change-line-rest (count)
  "Change to the end of the line, COUNT - 1 lines below (Vim's C).
The kill and the following insertion form a single undo step."
  :interactive "p"
  (aim--start-undo-session)
  (kill-region (point) (line-end-position count))
  (aim--kill-finish 'char)
  (aim-switch-state 'insert))

(aim-define-command aim-copy-line (count)
  "Copy COUNT whole lines into the kill-ring (Vim's Y, which is yy)."
  :interactive "p"
  (copy-region-as-kill (line-beginning-position)
                       (line-beginning-position (1+ count)))
  (aim--kill-finish 'line))

(aim-define-command aim-replace-char (count)
  "Replace COUNT characters after point with the next typed character.
Fails without changing anything when the line is too short, like Vim."
  :interactive "p"
  (let ((ch (aim--read-char "r-")))
    (when (> (+ (point) count) (line-end-position))
      (user-error "Not enough characters on the line"))
    (delete-region (point) (+ (point) count))
    (insert (make-string count ch))
    (backward-char)))

(aim-define-command aim-invert-char-case (count)
  "Toggle the case of COUNT characters, moving right past them."
  :interactive "p"
  (let* ((end (min (line-end-position) (+ (point) count)))
         (text (buffer-substring (point) end)))
    (delete-region (point) end)
    (insert (mapconcat (lambda (c)
                         (char-to-string
                          (cond ((eq c (upcase c)) (downcase c))
                                (t (upcase c)))))
                       text))))

(aim-define-command aim-join-lines (count)
  "Join COUNT lines (at least two) with a single space, like Vim's J.
Point ends on the joining space."
  :interactive "p"
  (dotimes (_ (max 1 (1- (max count 2))))
    (goto-char (line-end-position))
    (unless (eobp)
      (let ((here (point)))
        (forward-char)
        (skip-chars-forward " \t")
        (delete-region here (point))
        (insert " ")
        (backward-char)))))

;;;; Replace and motion States

(aim-define-command aim-replace-state ()
  "Enter replace State: typed characters overwrite (Vim's R)."
  (aim-switch-state 'replace))

(defun aim-replace-backspace ()
  "Undo the last replacement, restoring the original character.
Before the session's first replacement, just move left."
  (interactive)
  (let ((entry (assq (1- (point)) aim--replace-saved)))
    (if (not entry)
        (backward-char)
      (delete-char -1)
      (when (cdr entry)
        (insert (cdr entry))
        (backward-char))
      (setq aim--replace-saved (delq entry aim--replace-saved)))))

(defun aim-motion-state ()
  "Enter motion State: motions only, for read-only contexts."
  (interactive)
  (aim-switch-state 'motion))

;;;; Marks

(defun aim-set-marker ()
  "Store point in the register read from the next key (Vim's m).
Shared with Emacs's own register system (`C-x r')."
  (interactive)
  (point-to-register (aim--read-char "m-")))

;;;; Keyboard macros (q/@ over kmacro and registers, docs/adr/0002)

(defvar aim--macro-register nil
  "Register being recorded into by `aim-record-macro'.")

(defvar aim--macro-last-register nil
  "Register of the last executed macro, for `@@'.")

(defun aim-record-macro ()
  "Start recording a keyboard macro into a register; press q again to stop."
  (interactive)
  (if defining-kbd-macro
      (progn
        (kmacro-end-macro nil)
        (when aim--macro-register
          (set-register aim--macro-register last-kbd-macro)
          (setq aim--macro-register nil)))
    (setq aim--macro-register (aim--read-char "q-"))
    (kmacro-start-macro nil)))

(defun aim-execute-macro (count)
  "Execute the macro in the register read next, COUNT times.
`@@' repeats the last executed macro."
  (interactive "p")
  (let ((register (aim--read-char "@-")))
    (when (eq register ?@)
      (setq register (or aim--macro-last-register
                         (user-error "No previous macro"))))
    (let ((macro (get-register register)))
      (unless macro
        (user-error "Nothing in register %c" register))
      (setq aim--macro-last-register register)
      (execute-kbd-macro macro count))))

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
