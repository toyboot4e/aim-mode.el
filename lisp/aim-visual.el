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

(defvar-local aim--visual-overlays nil
  "Overlays showing the true Vim selection while in visual State.
A list: one overlay for char/line, one per line for block.")

(defun aim--visual-make-overlay (beg end)
  "Add a `region'-faced overlay over BEG..END to the visual overlays."
  (let ((ov (make-overlay beg end)))
    (overlay-put ov 'face 'region)
    (overlay-put ov 'priority 99)
    (push ov aim--visual-overlays)))

(defun aim--visual-update ()
  "Refresh the visual-selection overlays; clear them outside visual State.
Runs on `post-command-hook' (a no-op in non-visual buffers)."
  (mapc #'delete-overlay aim--visual-overlays)
  (setq aim--visual-overlays nil)
  (when (and (eq aim-state 'visual) (mark t))
    (pcase aim--visual-kind
      ('block
       (let* ((m (mark)) (p (point))
              (c1 (save-excursion (goto-char m) (current-column)))
              (c2 (save-excursion (goto-char p) (current-column)))
              (left (min c1 c2))
              (right (1+ (max c1 c2)))
              (l1 (line-number-at-pos (min m p)))
              (l2 (line-number-at-pos (max m p))))
         (save-excursion
           (goto-char (point-min))
           (forward-line (1- l1))
           (dotimes (_ (1+ (- l2 l1)))
             (move-to-column left)
             (let ((s (point)))
               (move-to-column right)
               (when (> (point) s)
                 (aim--visual-make-overlay s (point))))
             (forward-line 1)))))
      (_
       (pcase-let ((`(,beg ,end ,_type) (aim--visual-range)))
         (aim--visual-make-overlay beg end))))))

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
