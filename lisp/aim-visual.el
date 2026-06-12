;;; aim-visual.el --- Visual State commands  -*- lexical-binding: t; -*-

;;; Commentary:

;; Leaf module: entering, adjusting and leaving visual State.  The
;; selection is Emacs's region — the mark anchors it, motions move
;; point — so region-based Emacs commands work on it for free.
;; Operators take the selection as their range (see
;; `aim--operator-range'); `i'/`a' select text objects.

;;; Code:

(require 'aim-macros)

(defun aim-visual-char ()
  "Start a charwise visual selection; toggle it off when active."
  (interactive)
  (cond ((and (eq aim-state 'visual) (eq aim--visual-kind 'char))
         (aim--visual-leave))
        ((eq aim-state 'visual)
         (setq aim--visual-kind 'char))
        (t
         (setq aim--visual-kind 'char)
         (set-mark (point))
         (aim-switch-state 'visual))))

(defun aim-visual-line ()
  "Start a linewise visual selection; toggle it off when active."
  (interactive)
  (cond ((and (eq aim-state 'visual) (eq aim--visual-kind 'line))
         (aim--visual-leave))
        ((eq aim-state 'visual)
         (setq aim--visual-kind 'line))
        (t
         (setq aim--visual-kind 'line)
         (set-mark (point))
         (aim-switch-state 'visual))))

(defun aim-visual-exit ()
  "Leave visual State."
  (interactive)
  (aim--visual-leave))

(defun aim-visual-exchange ()
  "Exchange the two ends of the selection."
  (interactive)
  (exchange-point-and-mark))

(defun aim-visual-restore ()
  "Restore the last visual selection (Vim's `gv')."
  (interactive)
  (pcase aim--last-visual
    (`(,m ,p ,kind)
     (setq aim--visual-kind kind)
     (set-mark m)
     (goto-char p)
     (aim-switch-state 'visual))
    (_ (user-error "No previous selection"))))

(defun aim-visual-paste (_count)
  "Replace the selection with a paste.
The replaced text goes to the kill-ring, like Vim."
  (interactive "p")
  (let* ((text (aim--paste-text))
         (linewise (aim--text-linewise-p text))
         (range (aim--visual-range)))
    (aim--visual-leave)
    (kill-region (car range) (cadr range))
    (aim--kill-finish (if (eq (nth 2 range) 'linewise) 'line 'char))
    (goto-char (car range))
    (if linewise
        (let ((pt (point)))
          (unless (bolp) (insert "\n"))
          (insert text)
          (unless (string-suffix-p "\n" text) (insert "\n"))
          (goto-char pt)
          (back-to-indentation))
      (insert text)
      (backward-char))))

(defun aim-visual-object (count)
  "Select the text object read after this key (i/a in visual State).
COUNT is the object count (e.g. nesting depth for pairs)."
  (interactive "p")
  (let* ((lead (this-single-command-keys))
         (keys (read-key-sequence nil))
         (cmd (lookup-key aim-operator-state-map (vconcat lead keys))))
    (if (and cmd (symbolp cmd) (get cmd 'aim-text-object))
        (let ((range (funcall cmd count)))
          (set-mark (car range))
          (goto-char (max (car range) (1- (cdr range)))))
      (user-error "Not a text object: %s"
                  (key-description (vconcat lead keys))))))

(provide 'aim-visual)
;;; aim-visual.el ends here
