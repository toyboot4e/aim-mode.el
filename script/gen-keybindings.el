;;; gen-keybindings.el --- Generate docs/KEYBINDINGS.md  -*- lexical-binding: t; -*-

;;; Commentary:

;; Walk aim-mode's State keymaps and emit docs/KEYBINDINGS.md so the
;; reference is derived from the bindings and cannot drift.  Run via
;; `just docs'.

;;; Code:

(add-to-list 'load-path (expand-file-name "lisp"))
(require 'aim-mode)
(require 'cl-lib)

(defun aim-gen--walk (map prefix)
  "Collect (KEY-DESCRIPTION . COMMAND) from MAP under PREFIX, recursively."
  (let (items)
    (map-keymap
     (lambda (event def)
       (let ((keys (vconcat prefix (vector event))))
         (cond
          ((keymapp def)
           (setq items (nconc items (aim-gen--walk def keys))))
          ((and (symbolp def) def
                (not (memq def '(undefined digit-argument))))
           (push (cons (key-description keys) def) items)))))
     map)
    items))

(defun aim-gen--table (title map)
  "Return a markdown section titled TITLE for keymap MAP."
  (let* ((raw (aim-gen--walk map []))
         (seen (make-hash-table :test #'equal))
         rows)
    (dolist (it (sort raw (lambda (a b) (string< (car a) (car b)))))
      (unless (gethash (car it) seen)
        (puthash (car it) t seen)
        (push (format "| `%s` | %s |"
                      (car it)
                      (string-replace "aim-" "" (symbol-name (cdr it))))
              rows)))
    (concat "## " title "\n\n"
            "| Key | Command |\n|-----|---------|\n"
            (string-join (nreverse rows) "\n")
            "\n")))

(with-temp-file "docs/KEYBINDINGS.md"
  (insert "# Keybindings\n\n"
          "Generated from the State keymaps by `just docs` — do not edit "
          "by hand.\nCommand names are shown without the `aim-` prefix.\n\n")
  (insert (aim-gen--table "Normal State" aim-normal-state-map) "\n")
  (insert (aim-gen--table "Visual State" aim-visual-state-map) "\n")
  (insert (aim-gen--table "Operator-pending State (motions + text objects)"
                          aim-operator-state-map) "\n")
  (insert (aim-gen--table "Insert State" aim-insert-state-map) "\n")
  (insert (aim-gen--table "Replace State" aim-replace-state-map)))

(message "wrote docs/KEYBINDINGS.md")
;;; gen-keybindings.el ends here
