;;; aim-ex.el --- The Ex Dispatcher  -*- lexical-binding: t; -*-

;;; Commentary:

;; Leaf module: the `:' prompt (see CONTEXT.md, "Ex Dispatcher").  Not
;; an ex language — a hand-parsed whitelist of everyday commands:
;;
;;   :w [file]  :q  :q!  :wq  :x  :e file  :<line>  :$
;;   :[range]s/pat/rep/[g]    with ranges %, N, ., $, N,M
;;
;; plus two fallthroughs: input starting with `(' is evaluated as an
;; Emacs Lisp expression (the result is echoed), and anything else
;; naming an interactive command runs it like `M-x'.  Patterns are
;; Emacs regexps by design (docs/adr/0002).  From visual State, `:s'
;; defaults to the selected lines.

;;; Code:

(require 'aim-macros)

(defvar aim-ex-history nil
  "Minibuffer history for the Ex Dispatcher.")

(defun aim-ex ()
  "Read and dispatch an ex-style command (see CONTEXT.md)."
  (interactive)
  (let ((selection (and (eq aim-state 'visual)
                        (prog1 (let ((range (aim--visual-range)))
                                 (cons (car range) (cadr range)))
                          (aim--visual-leave)))))
    (aim-ex--dispatch (string-trim (read-string ":" nil 'aim-ex-history))
                      selection)))

(defun aim-ex--dispatch (input selection)
  "Dispatch the ex INPUT; SELECTION is the visual range, if any."
  (cond
   ((string-empty-p input))
   ;; Fallthrough 1: Emacs Lisp expression.
   ((string-prefix-p "(" input)
    (message "%S" (eval (car (read-from-string input)) t)))
   ;; Line addresses.
   ((string-match-p "\\`[0-9]+\\'" input)
    (aim--push-jump)
    (goto-char (point-min))
    (forward-line (1- (string-to-number input)))
    (back-to-indentation))
   ((equal input "$")
    (aim--push-jump)
    (goto-char (point-max))
    (when (and (bolp) (not (bobp))) (forward-line -1))
    (back-to-indentation))
   ;; Substitution.
   ((string-match (concat "\\`\\(%\\|\\(?:[0-9]+\\|[.$]\\)"
                          "\\(?:,\\(?:[0-9]+\\|[.$]\\)\\)?\\)?"
                          "s/\\(\\(?:[^/\\]\\|\\\\.\\)*\\)"
                          "/\\(\\(?:[^/\\]\\|\\\\.\\)*\\)"
                          "\\(?:/\\([gi]*\\)\\)?\\'")
                  input)
    ;; Extract all groups before anything clobbers the match data.
    (let ((range (match-string 1 input))
          (pattern (match-string 2 input))
          (replacement (match-string 3 input))
          (flags (or (match-string 4 input) "")))
      (aim-ex--substitute (aim-ex--resolve-range range selection)
                          (replace-regexp-in-string "\\\\/" "/" pattern)
                          (replace-regexp-in-string "\\\\/" "/" replacement)
                          flags)))
   ;; File commands.
   ((equal input "w") (save-buffer))
   ((string-match "\\`w \\(.+\\)\\'" input)
    (write-file (expand-file-name (match-string 1 input))))
   ((equal input "q") (aim-ex--quit nil))
   ((equal input "q!") (aim-ex--quit t))
   ((member input '("wq" "x"))
    (save-buffer)
    (aim-ex--quit nil))
   ((string-match "\\`e \\(.+\\)\\'" input)
    (find-file (expand-file-name (match-string 1 input))))
   ;; Fallthrough 2: M-x.
   (t
    (let ((sym (intern-soft input)))
      (if (commandp sym)
          (call-interactively sym)
        (user-error "Unknown ex command: %s" input))))))

(defun aim-ex--resolve-range (range selection)
  "Resolve the ex RANGE string to buffer positions (BEG . END).
RANGE is %, N, ., $, or N,M; nil means SELECTION when given, else
the current line."
  (cond
   ((and (null range) selection)
    (cons (save-excursion (goto-char (car selection))
                          (line-beginning-position))
          (save-excursion (goto-char (max (car selection)
                                          (1- (cdr selection))))
                          (line-beginning-position 2))))
   ((null range)
    (cons (line-beginning-position) (line-beginning-position 2)))
   ((equal range "%")
    (cons (point-min) (point-max)))
   (t
    (let* ((parts (split-string range ","))
           (from (aim-ex--address-line (car parts)))
           (to (aim-ex--address-line (or (cadr parts) (car parts)))))
      (save-excursion
        (cons (progn (goto-char (point-min))
                     (forward-line (1- from))
                     (point))
              (progn (goto-char (point-min))
                     (forward-line to)
                     (point))))))))

(defun aim-ex--address-line (addr)
  "Resolve the address ADDR (a number, . or $) to a line number."
  (pcase addr
    ("." (line-number-at-pos))
    ("$" (line-number-at-pos (point-max)))
    (_ (string-to-number addr))))

(defun aim-ex--substitute (range pattern replacement flags)
  "Substitute PATTERN with REPLACEMENT over RANGE per FLAGS.
The g flag replaces every occurrence instead of the first per line.
PATTERN is an Emacs regexp; REPLACEMENT supports \\\\N backreferences."
  (let ((global (string-match-p "g" flags))
        (end (copy-marker (cdr range)))
        (count 0)
        (last nil))
    (save-excursion
      (goto-char (car range))
      (if global
          (while (re-search-forward pattern end t)
            (replace-match replacement)
            (setq count (1+ count)
                  last (point))
            ;; Guard against zero-width matches looping forever.
            (when (= (match-beginning 0) (match-end 0))
              (forward-char)))
        (while (< (point) end)
          (when (re-search-forward pattern
                                   (min (line-end-position) (marker-position end))
                                   t)
            (replace-match replacement)
            (setq count (1+ count)
                  last (point)))
          (forward-line 1))))
    (set-marker end nil)
    (if (zerop count)
        (user-error "Pattern not found: %s" pattern)
      (goto-char last)
      (forward-line 0)
      (message "%d substitution%s" count (if (= count 1) "" "s")))))

(defun aim-ex--quit (force)
  "Close the window, or its buffer when it is the only window.
FORCE discards unsaved changes."
  (when force
    (set-buffer-modified-p nil))
  (if (cdr (window-list))
      (delete-window)
    (kill-current-buffer)))

(provide 'aim-ex)
;;; aim-ex.el ends here
