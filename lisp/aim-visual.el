;;; aim-visual.el --- Visual State commands  -*- lexical-binding: t; -*-

;;; Commentary:

;; Leaf module: entering, adjusting and leaving visual State.  The
;; selection is Emacs's region — the mark anchors it, motions move
;; point — so region-based Emacs commands work on it for free.
;; Operators take the selection as their range (see
;; `aim--operator-range'); `i'/`a' select text objects.
;;
;; Emacs's region is exclusive at its larger end and char-granular,
;; while Vim's visual selection is inclusive (charwise) or whole-line
;; (linewise).  So the live highlight is drawn by a dedicated overlay
;; over the true `aim--visual-range', recomputed after each command;
;; the mark stays active underneath for region-command integration
;; (the overlay is always a superset, so the two same-face highlights
;; simply union).  Block selections keep the plain-region highlight for
;; now (see docs/CAVEATS.md).

;;; Code:

(require 'aim-macros)

(defvar-local aim--visual-overlay nil
  "Overlay showing the true Vim selection while in visual State.")

(defun aim--visual-update ()
  "Refresh the visual-selection overlay; remove it outside visual State.
Runs on `post-command-hook' (a no-op in non-visual buffers)."
  (if (and (eq aim-state 'visual)
           (memq aim--visual-kind '(char line))
           (mark t))
      (pcase-let ((`(,beg ,end ,_type) (aim--visual-range)))
        (if aim--visual-overlay
            (move-overlay aim--visual-overlay beg end)
          (setq aim--visual-overlay (make-overlay beg end))
          (overlay-put aim--visual-overlay 'face 'region)
          (overlay-put aim--visual-overlay 'priority 99)))
    (when aim--visual-overlay
      (delete-overlay aim--visual-overlay)
      (setq aim--visual-overlay nil))))

(add-hook 'post-command-hook #'aim--visual-update)

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

(defun aim-visual-block ()
  "Start a blockwise visual selection; toggle it off when active."
  (interactive)
  (cond ((and (eq aim-state 'visual) (eq aim--visual-kind 'block))
         (aim--visual-leave))
        ((eq aim-state 'visual)
         (setq aim--visual-kind 'block))
        (t
         (setq aim--visual-kind 'block)
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
  (when (eq aim--visual-kind 'block)
    (user-error "Paste over a block selection is not supported yet"))
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
