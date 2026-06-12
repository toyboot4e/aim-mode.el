;;; aim-search.el --- Search glue over isearch  -*- lexical-binding: t; -*-

;;; Commentary:

;; Leaf module: `/' and `?' are thin wrappers over isearch
;; (docs/adr/0002) — Emacs regex, Emacs highlighting, isearch
;; extensions all apply.  When an aim-initiated search ends, point
;; moves to the match beginning (Vim's behavior; plain `C-s' is not
;; affected) and the pattern is remembered so `n'/`N' can repeat it
;; outside isearch, wrapping around like Vim.  `*' searches for the
;; symbol at point.

;;; Code:

(require 'aim-macros)

(defvar aim--search-pattern nil
  "Regexp of the last aim search, for `n'/`N'.")

(defvar aim--search-forward-p t
  "Direction of the last aim search.")

(defvar aim--search-via-aim nil
  "Non-nil while an isearch started by aim-mode is active.")

(defun aim-search-forward ()
  "Search forward incrementally (Vim's /)."
  (interactive)
  (setq aim--search-via-aim t)
  (isearch-forward))

(defun aim-search-backward ()
  "Search backward incrementally (Vim's ?)."
  (interactive)
  (setq aim--search-via-aim t)
  (isearch-backward))

(defun aim--isearch-end ()
  "Adopt the finished isearch as the last aim search."
  (when aim--search-via-aim
    (setq aim--search-via-aim nil)
    (unless (string-empty-p isearch-string)
      (setq aim--search-pattern (if isearch-regexp
                                    isearch-string
                                  (regexp-quote isearch-string))
            aim--search-forward-p isearch-forward))
    ;; Vim lands on the match beginning; forward isearch ends after it.
    (when (and isearch-forward isearch-other-end
               (not isearch-mode-end-hook-quit))
      (goto-char isearch-other-end))))

(add-hook 'isearch-mode-end-hook #'aim--isearch-end)

(defun aim--search-again (count forward)
  "Move to the COUNTth next match of the last search, wrapping around.
FORWARD selects the direction."
  (unless aim--search-pattern
    (user-error "No previous search"))
  (aim--push-jump)
  (dotimes (_ count)
    (let ((start (point)))
      (if forward
          (progn
            (goto-char (min (1+ (point)) (point-max)))
            (unless (re-search-forward aim--search-pattern nil t)
              (goto-char (point-min))
              (unless (re-search-forward aim--search-pattern nil t)
                (goto-char start)
                (user-error "Pattern not found: %s" aim--search-pattern)))
            (goto-char (match-beginning 0)))
        (unless (re-search-backward aim--search-pattern nil t)
          (goto-char (point-max))
          (unless (re-search-backward aim--search-pattern nil t)
            (goto-char start)
            (user-error "Pattern not found: %s" aim--search-pattern)))))))

(aim-define-motion aim-search-next (count)
  "Repeat the last search, COUNT times."
  (aim--search-again count aim--search-forward-p))

(aim-define-motion aim-search-previous (count)
  "Repeat the last search in the opposite direction, COUNT times."
  (aim--search-again count (not aim--search-forward-p)))

(aim-define-motion aim-search-symbol-forward (count)
  "Search forward for the COUNTth occurrence of the symbol at point."
  (let* ((beg (save-excursion (aim--skip-word-backward) (point)))
         (end (save-excursion (aim--skip-word-forward) (point))))
    (when (= beg end)
      (user-error "No symbol at point"))
    (setq aim--search-pattern
          (concat "\\_<"
                  (regexp-quote (buffer-substring-no-properties beg end))
                  "\\_>")
          aim--search-forward-p t)
    (aim--search-again count t)))

(provide 'aim-search)
;;; aim-search.el ends here
