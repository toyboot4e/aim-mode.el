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

(defconst aim--state-tags
  '((normal . "N") (insert . "I") (operator-pending . "O")
    (visual . "V") (replace . "R") (motion . "M"))
  "Mode-line tag per State.")

(defvar-local aim-state nil
  "The current State of this buffer, or nil when aim-mode is disabled.
Also serves as the activation variable in `aim--emulation-alist'.")

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

(defvar aim--state-maps
  `((normal . ,aim-normal-state-map)
    (operator-pending . ,aim-operator-state-map)
    (insert . ,aim-insert-state-map))
  "Alist mapping State symbols to their keymaps.")

(defvar-local aim--emulation-alist nil
  "Per-buffer entry consulted by `emulation-mode-map-alists'.
Holds ((aim-state . MAP)) for the current State's map; since
`aim-state' is nil when aim-mode is off, the map deactivates with it.")

(add-to-list 'emulation-mode-map-alists 'aim--emulation-alist)

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

;;;; State switching

(defun aim-switch-state (state)
  "Switch the current buffer to STATE."
  (let ((old aim-state))
    (when (and (eq old 'insert) (not (eq state 'insert)))
      (aim--end-undo-session))
    (setq aim-state state
          aim--emulation-alist
          (let ((map (alist-get state aim--state-maps)))
            (and map (list (cons 'aim-state map)))))
    (when (and (eq state 'insert) (not (eq old 'insert)))
      (aim--start-undo-session)))
  (aim--update-cursor))

(defun aim-normal-state ()
  "Enter normal State.
Leaving insert State moves point one character left unless at the
beginning of a line, mirroring Vim."
  (interactive)
  (let ((was-insert (eq aim-state 'insert)))
    (aim-switch-state 'normal)
    (when (and was-insert (not (bolp)))
      (backward-char))))

(defun aim-insert-state ()
  "Enter insert State at point."
  (interactive)
  (aim-switch-state 'insert))

(defun aim--disable ()
  "Deactivate aim in the current buffer."
  (aim--end-undo-session)
  (setq aim-state nil
        aim--emulation-alist nil)
  (aim--update-cursor))

(provide 'aim-core)
;;; aim-core.el ends here
