;;; aim-core.el --- States and keymap machinery for aim-mode  -*- lexical-binding: t; -*-

;;; Commentary:

;; The bottom layer of the aim-mode Kernel (docs/adr/0003): State
;; definitions, keymap activation through `emulation-mode-map-alists',
;; per-State cursor shapes, and undo grouping so that one insert session
;; is a single undo step (docs/adr/0002).

;;; Code:

(defgroup aim nil
  "Yet another Vim mode."
  :group 'emulations
  :prefix "aim-")

(defconst aim-states
  '(normal insert operator-pending visual replace motion)
  "All States aim-mode ships in 1.0.")

(defvar-local aim-state nil
  "The current State of this buffer, or nil when aim-mode is disabled.
Also serves as the activation variable in `aim--emulation-alist'.")

;;;; Mode-line indicator
;; Faces inherit from semantic faces so themes restyle them for free.

(defface aim-normal-state-face '((t :inherit success :weight bold))
  "Mode-line face for normal State." :group 'aim)
(defface aim-insert-state-face '((t :inherit error :weight bold))
  "Mode-line face for insert State." :group 'aim)
(defface aim-visual-state-face '((t :inherit warning :weight bold))
  "Mode-line face for visual State." :group 'aim)
(defface aim-operator-state-face '((t :inherit font-lock-builtin-face :weight bold))
  "Mode-line face for operator-pending State." :group 'aim)
(defface aim-replace-state-face '((t :inherit font-lock-constant-face :weight bold))
  "Mode-line face for replace State." :group 'aim)
(defface aim-motion-state-face '((t :inherit shadow :weight bold))
  "Mode-line face for motion State." :group 'aim)

(defconst aim--state-faces
  '((normal . aim-normal-state-face)
    (insert . aim-insert-state-face)
    (operator-pending . aim-operator-state-face)
    (visual . aim-visual-state-face)
    (replace . aim-replace-state-face)
    (motion . aim-motion-state-face))
  "Mode-line face per State.")

(defvar aim--visual-kind)              ; defined with the visual bookkeeping

(defun aim--state-label ()
  "Short upper-case label for the current State (visual shows its kind)."
  (pcase aim-state
    ('normal "NORMAL")
    ('insert "INSERT")
    ('operator-pending "O-PEND")
    ('replace "REPLACE")
    ('motion "MOTION")
    ('visual (pcase aim--visual-kind
               ('line "V-LINE") ('block "V-BLOCK") (_ "V-CHAR")))))

(defun aim-mode-line-string ()
  "Propertized State indicator for the mode line; empty when disabled.
Use as the `aim-mode' lighter, or embed in a custom mode line."
  (if aim-state
      (propertize (concat " " (aim--state-label) " ")
                  'face (alist-get aim-state aim--state-faces))
    ""))

;;;; Keymaps

(defvar-keymap aim-motion-map
  :doc "Bindings shared by normal and operator-pending States: motions, counts.")

(defvar-keymap aim-normal-state-map
  :doc "Bindings active in normal State."
  :parent aim-motion-map)

(defvar-keymap aim-operator-state-map
  :doc "Bindings active in operator-pending State."
  :parent aim-motion-map)

(defvar-keymap aim-insert-state-map
  :doc "Bindings active in insert State; unbound keys self-insert.")

(defvar-keymap aim-visual-state-map
  :doc "Bindings active in visual State."
  :parent aim-motion-map)

(defvar-keymap aim-replace-state-map
  :doc "Bindings active in replace State; unbound keys overwrite.")

(defvar-keymap aim-motion-state-map
  :doc "Bindings active in motion State: motions only."
  :parent aim-motion-map)

(defvar aim--state-maps
  `((normal . ,aim-normal-state-map)
    (operator-pending . ,aim-operator-state-map)
    (insert . ,aim-insert-state-map)
    (visual . ,aim-visual-state-map)
    (replace . ,aim-replace-state-map)
    (motion . ,aim-motion-state-map))
  "Alist mapping State symbols to their keymaps.")

;; Unbound printable keys must not self-insert outside the editing
;; States; otherwise a typo in normal State edits the buffer.
(dolist (map (list aim-normal-state-map aim-operator-state-map
                   aim-visual-state-map aim-motion-state-map))
  (define-key map [remap self-insert-command] #'undefined))

;;;; Per-major-mode auxiliary bindings

(defvar aim--aux-maps (make-hash-table :test #'equal)
  "Keymaps for (STATE . MAJOR-MODE) pairs, written by `aim-define-key'.")

(defun aim--aux-map (state mode &optional create)
  "The auxiliary keymap for STATE in MODE, or nil.
CREATE it when missing."
  (let ((key (cons state mode)))
    (or (gethash key aim--aux-maps)
        (and create
             (puthash key (make-sparse-keymap) aim--aux-maps)))))

(defun aim--current-aux-map (state)
  "Auxiliary keymap(s) for STATE in the current buffer's major mode.
Composes the maps of the mode and its parents, nearest mode first."
  (let (maps)
    (dolist (mode (derived-mode-all-parents major-mode))
      (let ((map (aim--aux-map state mode)))
        (when map (push map maps))))
    (cond ((null maps) nil)
          ((null (cdr maps)) (car maps))
          (t (make-composed-keymap (nreverse maps))))))

(defun aim-define-key (state key def &optional mode)
  "Bind KEY to DEF in STATE's keymap.
With MODE, the binding applies only in buffers whose major mode
derives from MODE, and takes precedence over the State keymap.
KEY is a `keymap-set' key string."
  (if mode
      (keymap-set (aim--aux-map state mode t) key def)
    (keymap-set (or (alist-get state aim--state-maps)
                    (error "No such State: %s" state))
                key def)))

(defvar-local aim--emulation-alist nil
  "Per-buffer entry consulted by `emulation-mode-map-alists'.
Holds ((aim-state . MAP)) for the current State's map; since
`aim-state' is nil when aim-mode is off, the map deactivates with it.")

(add-to-list 'emulation-mode-map-alists 'aim--emulation-alist)

;;;; Word vocabulary
;; Shared by motions and text objects (Leaves that may not depend on
;; each other).  A word follows the buffer's syntax table — word and
;; symbol constituents — approximating Vim's `iskeyword'; runs of other
;; non-blank characters form punctuation groups.

(defun aim--word-char-p (c)
  "Non-nil when character C is a word constituent (word or symbol syntax)."
  (and c (not (eq c ?\n)) (memq (char-syntax c) '(?w ?_))))

(defun aim--blank-char-p (c)
  "Non-nil when character C is a blank (space or tab)."
  (memq c '(?\s ?\t)))

(defun aim--punct-char-p (c)
  "Non-nil when character C is non-blank and not a word constituent."
  (and c (not (eq c ?\n)) (not (aim--blank-char-p c)) (not (aim--word-char-p c))))

(defun aim--skip-word-forward ()
  "Skip forward over word constituents."
  (skip-syntax-forward "w_"))

(defun aim--skip-word-backward ()
  "Skip backward over word constituents."
  (skip-syntax-backward "w_"))

(defun aim--skip-punct-forward ()
  "Skip forward over a punctuation group."
  (while (aim--punct-char-p (char-after))
    (forward-char)))

(defun aim--skip-punct-backward ()
  "Skip backward over a punctuation group."
  (while (aim--punct-char-p (char-before))
    (backward-char)))

;;;; Pair scanning
;; Shared by text objects and the % motion.  Character-based — no
;; escape or string-context awareness (see docs/CAVEATS.md).

(defun aim--scan-open-backward (open close count)
  "Position of the COUNTth OPEN enclosing point, scanning backward.
CLOSE characters re-balance; point sitting on OPEN counts as inside.
Return nil when there is no such OPEN."
  (save-excursion
    (when (eq (char-after) open)
      (forward-char))
    (let ((depth 0) (n count) (found nil))
      (while (and (not found) (not (bobp)))
        (let ((c (char-before)))
          (cond ((eq c close) (setq depth (1+ depth)))
                ((eq c open)
                 (if (> depth 0)
                     (setq depth (1- depth))
                   (setq n (1- n))
                   (when (zerop n)
                     (setq found (1- (point))))))))
        (unless found (backward-char)))
      found)))

(defun aim--match-close (openp open close)
  "Position of the CLOSE matching the OPEN at position OPENP, or nil."
  (save-excursion
    (goto-char (1+ openp))
    (let ((depth 0) (found nil))
      (while (and (not found) (not (eobp)))
        (let ((c (char-after)))
          (cond ((eq c open) (setq depth (1+ depth)))
                ((eq c close)
                 (if (> depth 0)
                     (setq depth (1- depth))
                   (setq found (point))))))
        (unless found (forward-char)))
      found)))

;;;; Kills and registers
;; The unnamed register is the kill-ring head (docs/adr/0002).  Killed
;; text is tagged with its type (char or line) via a text property, so
;; paste does not have to guess; named registers are Emacs registers,
;; written through the pending-register prefix (`\"a').

(defvar aim--pending-register nil
  "Register character set by the \" prefix for the next kill or paste.")

(defun aim--register-consume ()
  "Return and clear the pending register character, if any."
  (prog1 aim--pending-register
    (setq aim--pending-register nil)))

(defun aim--kill-finish (type)
  "Tag the latest kill as TYPE (char or line); fill the pending register."
  (when kill-ring
    (put-text-property 0 (length (car kill-ring))
                       'aim-type type (car kill-ring)))
  (let ((register (aim--register-consume)))
    (when register
      (set-register register (current-kill 0)))))

(defun aim--paste-text ()
  "Text to paste: the pending register's contents, or the latest kill."
  (let ((register (aim--register-consume)))
    (if register
        (let ((value (get-register register)))
          (unless (stringp value)
            (user-error "Register %c does not hold text" register))
          value)
      (current-kill 0))))

(defun aim--text-linewise-p (text)
  "Non-nil when TEXT should paste linewise.
Uses the kill's type tag, falling back to a trailing newline for
text killed outside aim-mode."
  (eq (or (get-text-property 0 'aim-type text)
          (if (string-suffix-p "\n" text) 'line 'char))
      'line))

;;;; Jumps

(defvar-local aim--last-jump nil
  "Marker at the position before the last jump, for the backtick mark.")

(defun aim--push-jump ()
  "Remember point as the position before a jump."
  (setq aim--last-jump (point-marker)))

;;;; Terminal ESC
;; On a tty, ESC is also the lead byte of Meta chords and function-key
;; sequences.  An `input-decode-map' filter waits `aim-esc-delay' for a
;; following byte: alone it becomes the <escape> event (so leaving
;; insert State is instant), otherwise normal decoding proceeds and
;; Meta chords work.  GUI frames and batch mode are untouched.

(defcustom aim-esc-delay 0.01
  "Seconds to wait for a byte following ESC on a tty."
  :type 'number)

(defun aim--esc-filter (map)
  "Translate a lone ESC to <escape>; pass MAP through otherwise."
  (if (and (equal (this-single-command-keys) [?\e])
           (sit-for aim-esc-delay))
      [escape]
    map))

(defun aim--setup-terminal-esc (&optional frame)
  "Install the ESC filter on FRAME's terminal when it is a tty."
  (with-selected-frame (or frame (selected-frame))
    (let ((term (frame-terminal)))
      (when (and (eq (terminal-live-p term) t)
                 (not (terminal-parameter term 'aim--esc)))
        (set-terminal-parameter term 'aim--esc t)
        ;; KEY is built at runtime, not written as the literal [?\e], so
        ;; no static reserved-key check (some byte-compilers flag ESC)
        ;; can inspect it; and the binding is guarded because a handful
        ;; of builds reject rebinding ESC here.  Instant-tty-ESC is only
        ;; an optimisation — the GUI <escape> event and the "ESC" State
        ;; bindings leave insert State regardless.
        (let* ((esc (vector ?\e))
               (prev (lookup-key input-decode-map esc)))
          (ignore-errors
            (define-key input-decode-map esc
                        `(menu-item "" ,prev :filter ,#'aim--esc-filter))))))))

(unless noninteractive
  (aim--setup-terminal-esc)
  (add-hook 'after-make-frame-functions #'aim--setup-terminal-esc))

;;;; Cursor

(defcustom aim-state-cursors
  '((normal . box)
    (insert . bar)
    (operator-pending . hollow)
    (visual . box)
    (replace . hbar)
    (motion . box))
  "Cursor shape per State, as accepted by `cursor-type'."
  :type '(alist :key-type symbol :value-type sexp))

(defun aim--update-cursor ()
  "Set `cursor-type' from `aim-state-cursors' for the current State."
  (setq cursor-type (if aim-state
                        (alist-get aim-state aim-state-cursors 'box)
                      (default-value 'cursor-type))))

;;;; Undo sessions
;; One insert session (or change-operator + its insertion) is one undo
;; step: a change group opens when insert State begins and is
;; amalgamated when it ends.

(defvar-local aim--undo-handle nil
  "Open change-group handle for the current undo session, or nil.")

(defun aim--start-undo-session ()
  "Open an undo session unless one is already open."
  (unless aim--undo-handle
    (setq aim--undo-handle (prepare-change-group))
    (activate-change-group aim--undo-handle)))

(defun aim--end-undo-session ()
  "Amalgamate and close the current undo session, if any."
  (when aim--undo-handle
    (undo-amalgamate-change-group aim--undo-handle)
    (accept-change-group aim--undo-handle)
    (setq aim--undo-handle nil)))

;;;; Visual selection bookkeeping

(defvar-local aim--visual-kind 'char
  "Kind of the visual selection: `char' or `line'.")

(defvar-local aim--last-visual nil
  "Last visual selection, as (MARK POINT KIND), for `gv'.")

(defun aim--visual-leave ()
  "Leave visual State for normal State, remembering the selection.
Switch State before deactivating the mark: `deactivate-mark' runs
`deactivate-mark-hook', and `aim--visual-deactivate' there keys off
`aim-state', so leaving first keeps that hook from re-entering."
  (when (eq aim-state 'visual)
    (setq aim--last-visual (list (mark) (point) aim--visual-kind)))
  (aim-switch-state 'normal)
  (deactivate-mark))

;;;; Replace-State bookkeeping
;; Typed characters overwrite via `overwrite-mode'; the characters they
;; replaced are remembered so backspace can restore them.

(defvar-local aim--replace-saved nil
  "Alist of (POSITION . CHAR) overwritten this replace session.
CHAR is nil when the typed character was appended at end of line.")

(defun aim--replace-pre-command ()
  "Remember the character about to be overwritten in replace State."
  (when (and (eq aim-state 'replace)
             (eq this-command 'self-insert-command))
    (push (cons (point) (and (not (eolp)) (char-after)))
          aim--replace-saved)))

(add-hook 'pre-command-hook #'aim--replace-pre-command)

;;;; State switching

(defun aim-switch-state (state)
  "Switch the current buffer to STATE."
  (let ((old aim-state)
        (editing '(insert replace)))
    (when (and (memq old editing) (not (memq state editing)))
      (aim--end-undo-session))
    (when (and (eq old 'replace) (not (eq state 'replace)))
      (overwrite-mode -1)
      (setq aim--replace-saved nil))
    (setq aim-state state
          aim--emulation-alist
          (let ((map (alist-get state aim--state-maps))
                (aux (aim--current-aux-map state)))
            (append (and aux (list (cons 'aim-state aux)))
                    (and map (list (cons 'aim-state map))))))
    (when (and (memq state editing) (not (memq old editing)))
      (aim--start-undo-session))
    (when (and (eq state 'replace) (not (eq old 'replace)))
      (overwrite-mode 1)))
  (aim--update-cursor))

(defun aim-normal-state ()
  "Enter normal State.
Leaving insert or replace State moves point one character left
unless at the beginning of a line, mirroring Vim."
  (interactive)
  (let ((was-editing (memq aim-state '(insert replace))))
    (aim-switch-state 'normal)
    (when (and was-editing (not (bolp)))
      (backward-char))))

(defun aim-insert-state ()
  "Enter insert State at point."
  (interactive)
  (aim-switch-state 'insert))

(defun aim--refresh-state ()
  "Recompute the State keymaps after a major-mode change."
  (when aim-state
    (aim-switch-state aim-state)))

(add-hook 'after-change-major-mode-hook #'aim--refresh-state)

(defun aim--disable ()
  "Deactivate aim in the current buffer."
  (aim--end-undo-session)
  (setq aim-state nil
        aim--emulation-alist nil)
  (aim--update-cursor))

(provide 'aim-core)
;;; aim-core.el ends here
