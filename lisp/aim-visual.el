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
(require 'rect)

(defvar-local aim--visual-overlays nil
  "Overlays showing the true Vim selection while in visual State.
A list: one overlay for char/line, one per line for block.")

(defvar-local aim--visual-block-to-eol nil
  "Non-nil when `$' has made a block selection ragged to each line's end.")

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
               (if aim--visual-block-to-eol
                   (goto-char (line-end-position))
                 (move-to-column right))
               (when (> (point) s)
                 (aim--visual-make-overlay s (point))))
             (forward-line 1)))))
      (_
       (pcase-let ((`(,beg ,end ,_type) (aim--visual-range)))
         (aim--visual-make-overlay beg end))))))

(add-hook 'post-command-hook #'aim--visual-update)

;;;; Block insert (I / A)
;; The text typed on the first line is replicated at the same column on
;; every other line of the block when insert State ends.  Start and end
;; positions are tracked with this Leaf's own markers (no dependency on
;; other Leaves).

(defvar-local aim--block-insert nil
  "Pending block insert as (START-MARKER COLUMN LINES APPEND EOL), or nil.
EOL non-nil means each line's own end (ragged `$A'), ignoring COLUMN.")

(defvar-local aim--block-insert-end nil
  "Marker tracking the end of the block-insert text while inserting.")

(defun aim--begin-block-insert (col lines append eol)
  "Begin a block insert on the current line, replicating to LINES.
At COL (padding short lines if APPEND), or at each line's end if EOL."
  (if eol (goto-char (line-end-position)) (move-to-column col append))
  (aim--start-undo-session)
  (setq aim--block-insert (list (point-marker) col lines append eol)
        aim--block-insert-end nil)
  (aim-switch-state 'insert))

(defun aim--block-insert (append)
  "Begin a block insert at the left column, or the right edge if APPEND.
With APPEND and a `$'-extended block, append at each line's own end."
  (let* ((m (mark)) (p (point))
         (eol (and append aim--visual-block-to-eol))
         (c1 (save-excursion (goto-char m) (current-column)))
         (c2 (save-excursion (goto-char p) (current-column)))
         (col (if append (1+ (max c1 c2)) (min c1 c2)))
         (l1 (line-number-at-pos (min m p)))
         (l2 (line-number-at-pos (max m p))))
    (aim--visual-leave)
    (goto-char (point-min))
    (forward-line (1- l1))
    (aim--begin-block-insert col (number-sequence (1+ l1) l2) append eol)))

(defun aim--block-insert-track ()
  "Track and finish a block insert (a `post-command-hook' function)."
  (when aim--block-insert
    (if (eq aim-state 'insert)
        (setq aim--block-insert-end (point-marker))
      (pcase-let ((`(,start ,col ,lines ,append ,eol) aim--block-insert))
        (setq aim--block-insert nil)
        (let ((text (and (markerp aim--block-insert-end)
                         (>= (marker-position aim--block-insert-end)
                             (marker-position start))
                         (buffer-substring start aim--block-insert-end))))
          (when (and text (> (length text) 0) (not (string-search "\n" text)))
            (save-excursion
              (dolist (ln lines)
                (goto-char (point-min))
                (forward-line (1- ln))
                (if eol
                    (progn (goto-char (line-end-position)) (insert text))
                  (move-to-column col append)
                  (when (or append (>= (current-column) col))
                    (insert text)))))))
        (set-marker start nil)))))

(add-hook 'post-command-hook #'aim--block-insert-track)

(defun aim-visual-insert ()
  "Insert at the left of a block selection on every line (Vim's block I)."
  (interactive)
  (if (eq aim--visual-kind 'block)
      (aim--block-insert nil)
    (let ((beg (min (mark) (point))))
      (aim--visual-leave)
      (goto-char beg)
      (aim-switch-state 'insert))))

(defun aim-visual-append ()
  "Append at the right of a block selection on every line (Vim's block A)."
  (interactive)
  (if (eq aim--visual-kind 'block)
      (aim--block-insert t)
    (let ((end (max (mark) (point))))
      (aim--visual-leave)
      (goto-char end)
      (aim-switch-state 'insert))))

(defun aim-visual-char ()
  "Start a charwise visual selection; toggle it off when active."
  (interactive)
  (cond ((and (eq aim-state 'visual) (eq aim--visual-kind 'char))
         (aim--visual-leave))
        ((eq aim-state 'visual)
         (setq aim--visual-kind 'char))
        (t
         (setq aim--visual-kind 'char)
         (setq aim--visual-block-to-eol nil)
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
         (setq aim--visual-block-to-eol nil)
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
         (setq aim--visual-block-to-eol nil)
         (set-mark (point))
         (aim-switch-state 'visual))))

(defun aim-visual-end-of-line ()
  "Move to end of line; in a block, make the right edge ragged (Vim's $)."
  (interactive)
  (when (eq aim--visual-kind 'block)
    (setq aim--visual-block-to-eol t))
  (goto-char (line-end-position)))

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

(defun aim--visual-kill-rectangle (beg end)
  "Delete the BEG..END rectangle into the `kill-ring', block-tagged."
  (kill-new (propertize (mapconcat #'identity
                                   (delete-extract-rectangle beg end) "\n")
                        'aim-type 'block)))

(defun aim-visual-paste (_count)
  "Replace the selection with a paste.
The replaced text goes to the `kill-ring', like Vim."
  (interactive "p")
  (let* ((range (aim--visual-range))
         (text (aim--paste-text)))
    (cond
     ((eq (nth 2 range) 'block)
      (aim--visual-leave)
      (aim--visual-kill-rectangle (nth 0 range) (nth 1 range))
      (goto-char (nth 0 range))
      (if (eq (get-text-property 0 'aim-type text) 'block)
          (insert-rectangle (split-string text "\n"))
        (insert text)))
     ((aim--text-linewise-p text)
      (aim--visual-leave)
      (kill-region (nth 0 range) (nth 1 range))
      (aim--kill-finish (if (eq (nth 2 range) 'linewise) 'line 'char))
      (goto-char (nth 0 range))
      (let ((pt (point)))
        (unless (bolp) (insert "\n"))
        (insert text)
        (unless (string-suffix-p "\n" text) (insert "\n"))
        (goto-char pt)
        (back-to-indentation)))
     (t
      (aim--visual-leave)
      (kill-region (nth 0 range) (nth 1 range))
      (aim--kill-finish (if (eq (nth 2 range) 'linewise) 'line 'char))
      (goto-char (nth 0 range))
      (insert text)
      (backward-char)))))

(defun aim-visual-change ()
  "Change the visual selection (Vim's visual c/s).
A block selection deletes the rectangle and replicates the typed
text down the block; char/line behave like the change operator."
  (interactive)
  (let ((range (aim--visual-range)))
    (if (eq (nth 2 range) 'block)
        (let* ((m (mark)) (p (point))
               (c1 (save-excursion (goto-char m) (current-column)))
               (c2 (save-excursion (goto-char p) (current-column)))
               (left (min c1 c2))
               (l1 (line-number-at-pos (min m p)))
               (l2 (line-number-at-pos (max m p))))
          (aim--visual-leave)
          (aim--start-undo-session)
          (aim--visual-kill-rectangle (nth 0 range) (nth 1 range))
          (goto-char (point-min))
          (forward-line (1- l1))
          (aim--begin-block-insert left (number-sequence (1+ l1) l2) nil nil))
      (let* ((linewise (eq (nth 2 range) 'linewise))
             (indent (and linewise
                          (save-excursion
                            (goto-char (nth 0 range))
                            (buffer-substring (point)
                                              (progn (back-to-indentation)
                                                     (point)))))))
        (aim--visual-leave)
        (aim--start-undo-session)
        (kill-region (nth 0 range) (nth 1 range))
        (aim--kill-finish (if linewise 'line 'char))
        (goto-char (nth 0 range))
        (when linewise (insert indent "\n") (backward-char))
        (aim-switch-state 'insert)))))

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
