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
(require 'rect)

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

(defun aim--insert-block (text)
  "Insert block-tagged TEXT as a rectangle at point."
  (let ((pt (point)))
    (insert-rectangle (split-string text "\n"))
    (goto-char pt)))

(aim-define-command aim-paste-after (count)
  "Paste COUNT times after point, from the pending register or the kill-ring.
Linewise text goes below the current line; a block pastes as a
rectangle after the cursor column."
  :interactive "p"
  (let ((text (aim--paste-text)))
    (cond
     ((eq (get-text-property 0 'aim-type text) 'block)
      (unless (eolp) (forward-char))
      (aim--insert-block text))
     ((aim--text-linewise-p text)
      (forward-line 1)
      (unless (bolp) (insert "\n"))
      (aim--insert-linewise text count))
     (t
      (unless (eolp) (forward-char))
      (dotimes (_ count) (insert text))
      (backward-char)))))

(aim-define-command aim-paste-before (count)
  "Paste COUNT times before point, from the pending register or the kill-ring.
Linewise text goes above the current line; a block pastes as a
rectangle at the cursor column."
  :interactive "p"
  (let ((text (aim--paste-text)))
    (cond
     ((eq (get-text-property 0 'aim-type text) 'block)
      (aim--insert-block text))
     ((aim--text-linewise-p text)
      (forward-line 0)
      (aim--insert-linewise text count))
     (t
      (dotimes (_ count) (insert text))
      (backward-char)))))

(aim-define-command aim-paste-after-advance (count)
  "Like `aim-paste-after' but leave point just after the paste (Vim's gp)."
  :interactive "p"
  (let ((text (aim--paste-text)))
    (cond
     ((eq (get-text-property 0 'aim-type text) 'block)
      (unless (eolp) (forward-char))
      (aim--insert-block text))
     ((aim--text-linewise-p text)
      (forward-line 1)
      (unless (bolp) (insert "\n"))
      (dotimes (_ count)
        (insert text)
        (unless (string-suffix-p "\n" text) (insert "\n"))))
     (t
      (unless (eolp) (forward-char))
      (dotimes (_ count) (insert text))))))

(aim-define-command aim-paste-before-advance (count)
  "Like `aim-paste-before' but leave point just after the paste (Vim's gP)."
  :interactive "p"
  (let ((text (aim--paste-text)))
    (cond
     ((eq (get-text-property 0 'aim-type text) 'block)
      (aim--insert-block text))
     ((aim--text-linewise-p text)
      (forward-line 0)
      (dotimes (_ count)
        (insert text)
        (unless (string-suffix-p "\n" text) (insert "\n"))))
     (t
      (dotimes (_ count) (insert text))))))

(defun aim-use-register ()
  "Select the register for the next kill or paste (Vim's \" prefix)."
  (interactive)
  (let ((reg (aim--read-char "\"-")))
    (setq aim--pending-register reg
          ;; Carry "<reg> into the next repeat record so `"adw' repeats
          ;; with its register (the property keeps the post-command hook
          ;; from clearing this).
          aim--repeat-prefix (vconcat [?\"] (vector reg)))))

(put 'aim-use-register 'aim-repeat-prefix t)

;;;; Substitute and join

(aim-define-command aim-substitute-char (count)
  "Delete COUNT characters and enter insert State (Vim's s)."
  :interactive "p"
  (aim--start-undo-session)
  (let ((end (min (line-end-position) (+ (point) count))))
    (when (< (point) end)
      (kill-region (point) end)
      (aim--kill-finish 'char)))
  (aim-switch-state 'insert))

(aim-define-command aim-substitute-line (count)
  "Change COUNT whole lines, keeping indentation (Vim's S, like cc)."
  :interactive "p"
  (let ((indent (buffer-substring (line-beginning-position)
                                  (save-excursion (back-to-indentation) (point)))))
    (aim--start-undo-session)
    (kill-region (line-beginning-position) (line-beginning-position (1+ count)))
    (aim--kill-finish 'line)
    (insert indent "\n")
    (backward-char)
    (aim-switch-state 'insert)))

(aim-define-command aim-join-lines-no-space (count)
  "Join COUNT lines without inserting a space (Vim's gJ)."
  :interactive "p"
  (dotimes (_ (max 1 (1- (max count 2))))
    (goto-char (line-end-position))
    (unless (eobp) (delete-char 1))))

;;;; Increment / decrement

(defun aim--add-to-number (delta)
  "Add DELTA to the decimal number at or after point on this line.
Leave point on the last digit of the result, like Vim."
  (let ((eol (line-end-position)))
    (unless (looking-at-p "[0-9]")
      (skip-chars-forward "^0-9" eol))
    (unless (looking-at-p "[0-9]")
      (user-error "No number on the line"))
    (skip-chars-backward "0-9")
    (when (eq (char-before) ?-)
      (backward-char))
    (looking-at "-?[0-9]+")
    (let ((new (number-to-string (+ (string-to-number (match-string 0)) delta))))
      (replace-match new)
      (goto-char (1- (point))))))

(aim-define-command aim-increment (count)
  "Increment the number at or after point by COUNT (Vim's C-a)."
  :interactive "p"
  (aim--add-to-number count))

(aim-define-command aim-decrement (count)
  "Decrement the number at or after point by COUNT (Vim's C-x)."
  :interactive "p"
  (aim--add-to-number (- count)))

;;;; Insert at last edit (gi)

(defvar-local aim--last-insert-pos nil
  "Marker at the point of the last insert-State command, for `gi'.")

(defun aim--track-insert-pos ()
  "Remember point while in insert State; runs on `post-command-hook'."
  (when (eq aim-state 'insert)
    (setq aim--last-insert-pos (point-marker))))

(add-hook 'post-command-hook #'aim--track-insert-pos)

(aim-define-command aim-insert-at-last-edit ()
  "Re-enter insert State where insert was last left (Vim's gi)."
  (when (and (markerp aim--last-insert-pos)
             (marker-position aim--last-insert-pos))
    (goto-char aim--last-insert-pos))
  (aim-switch-state 'insert))

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
