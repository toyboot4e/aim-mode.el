;;; aim-operators.el --- Common Core operators  -*- lexical-binding: t; -*-

;;; Commentary:

;; Leaf module: the d / c / y operators.  Killed and yanked text goes
;; to the kill-ring (the unnamed register; docs/adr/0002).

;;; Code:

(require 'aim-macros)
(require 'rect)

(defun aim--kill-rectangle (beg end)
  "Delete the BEG..END rectangle into the `kill-ring', block-tagged."
  (kill-new (propertize (mapconcat #'identity
                                   (delete-extract-rectangle beg end)
                                   "\n")
                        'aim-type 'block)))

(aim-define-operator aim-delete (beg end type)
  "Kill from BEG to END; linewise TYPE kills whole lines.
A block TYPE kills the rectangle between the corners."
  (if (eq type 'block)
      (aim--kill-rectangle beg end)
    (kill-region beg end)
    (aim--kill-finish (if (eq type 'linewise) 'line 'char)))
  (goto-char beg)
  (when (eq type 'linewise)
    (back-to-indentation)))

(aim-define-operator aim-change (beg end type)
  "Kill from BEG to END and enter insert State.
A linewise TYPE keeps the first line's indentation to insert after,
like Vim's `cc' with autoindent.  The kill and the following
insertion form a single undo step."
  :motion-subst ((aim-forward-word-begin . aim-forward-word-end))
  (let ((indent (and (eq type 'linewise)
                     (save-excursion
                       (goto-char beg)
                       (buffer-substring beg (progn (back-to-indentation)
                                                    (point)))))))
    (aim--start-undo-session)
    (if (eq type 'block)
        ;; Insertion is not replicated per line yet (docs/CAVEATS.md).
        (aim--kill-rectangle beg end)
      (kill-region beg end)
      (aim--kill-finish (if (eq type 'linewise) 'line 'char)))
    (goto-char beg)
    (when (eq type 'linewise)
      (insert indent "\n")
      (backward-char))
    (aim-switch-state 'insert)))

(aim-define-operator aim-yank (beg end type)
  "Copy from BEG to END into the `kill-ring'.
Point moves to BEG, except for a linewise yank that already contains
point, which stays put (like `yy').  A block TYPE copies the
rectangle."
  (if (eq type 'block)
      (kill-new (propertize (mapconcat #'identity
                                       (extract-rectangle beg end)
                                       "\n")
                            'aim-type 'block))
    (copy-region-as-kill beg end)
    (aim--kill-finish (if (eq type 'linewise) 'line 'char)))
  (unless (and (eq type 'linewise)
               (<= beg (point))
               (< (point) end))
    (goto-char beg)))

;; Vim's `.' repeats the last change, not a yank.
(put 'aim-yank 'aim-repeatable nil)

;;;; Case

(defun aim--swap-case-string (text)
  "Return TEXT with the case of each character toggled."
  (mapconcat (lambda (c)
               (string (if (eq c (upcase c)) (downcase c) (upcase c))))
             text))

(aim-define-operator aim-downcase (beg end _type)
  "Lowercase BEG..END (Vim's gu)."
  (downcase-region beg end)
  (goto-char beg))

(aim-define-operator aim-upcase (beg end _type)
  "Uppercase BEG..END (Vim's gU)."
  (upcase-region beg end)
  (goto-char beg))

(aim-define-operator aim-swap-case (beg end _type)
  "Toggle the case of BEG..END (Vim's g~)."
  (let ((text (buffer-substring beg end)))
    (delete-region beg end)
    (goto-char beg)
    (insert (aim--swap-case-string text))
    (goto-char beg)))

;;;; Reindent

(aim-define-operator aim-reindent (beg end _type)
  "Reindent the lines spanned by BEG..END (Vim's =)."
  (indent-region beg end)
  (goto-char beg)
  (back-to-indentation))

;;;; Reformat

(aim-define-operator aim-reformat (beg end _type)
  "Reflow BEG..END to `fill-column' (Vim's gq); point ends past it."
  (let ((m (copy-marker end)))
    (fill-region beg end)
    (goto-char m)
    (set-marker m nil)
    (forward-line 0)
    (back-to-indentation)))

(aim-define-operator aim-reformat-keep (beg end _type)
  "Reflow BEG..END to `fill-column' (Vim's gw); point stays put."
  (save-excursion (fill-region beg end)))

;;;; Filter

(aim-define-operator aim-filter (beg end _type)
  "Filter the lines spanned by BEG..END through a shell command (Vim's !)."
  (let* ((cmd (read-shell-command "!"))
         (b (copy-marker (save-excursion (goto-char beg)
                                         (line-beginning-position))))
         ;; A linewise range already ends at a line start; only a
         ;; charwise end needs rounding up to the next line.
         (e (save-excursion (goto-char end)
                            (if (bolp) end (line-beginning-position 2)))))
    (shell-command-on-region b e cmd nil t)
    (goto-char b)
    (set-marker b nil)
    (back-to-indentation)))

(defcustom aim-shift-width 4
  "Columns shifted by the > and < operators."
  :type 'natnum
  :group 'aim)

(aim-define-operator aim-shift-right (beg end _type)
  "Shift the lines in BEG..END right by `aim-shift-width' columns."
  (indent-rigidly beg end aim-shift-width)
  (goto-char beg)
  (back-to-indentation))

(aim-define-operator aim-shift-left (beg end _type)
  "Shift the lines in BEG..END left by `aim-shift-width' columns."
  (indent-rigidly beg end (- aim-shift-width))
  (goto-char beg)
  (back-to-indentation))

(provide 'aim-operators)
;;; aim-operators.el ends here
