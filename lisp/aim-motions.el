;;; aim-motions.el --- Common Core motions  -*- lexical-binding: t; -*-

;;; Commentary:

;; Leaf module: the Common Core motions.  Each motion declares its type
;; (exclusive / inclusive / linewise), which the Kernel uses to expand
;; movements into operator ranges.
;;
;; Point follows Emacs's between-characters model rather than Vim's
;; on-a-character model: `$' lands after the last character, and `l' may
;; reach the end of line.  Operator ranges match Vim regardless.

;;; Code:

(require 'aim-macros)

(defconst aim--word-chars "[:alnum:]_"
  "Characters that form a word, as a `skip-chars-forward' set.")

;;;; Character and line motions

(aim-define-motion aim-backward-char (count)
  "Move COUNT characters left, stopping at the beginning of the line."
  (goto-char (max (line-beginning-position) (- (point) count))))

(aim-define-motion aim-forward-char (count)
  "Move COUNT characters right, stopping at the end of the line."
  (goto-char (min (line-end-position) (+ (point) count))))

(defvar aim--goal-column nil
  "Column a `j'/`k' run started from, kept across short lines.")

(defun aim--line-move (count)
  "Move COUNT lines (negative for up), keeping the goal column.
Consecutive `j'/`k' presses remember the column the run started
from, so travelling through a short line does not lose it."
  (let ((col (if (memq last-command '(aim-next-line aim-previous-line))
                 (or aim--goal-column (current-column))
               (current-column))))
    (setq aim--goal-column col)
    (forward-line count)
    (move-to-column col)))

(aim-define-motion aim-next-line (count)
  "Move COUNT lines down, keeping the goal column."
  :type linewise
  (aim--line-move count))

(aim-define-motion aim-previous-line (count)
  "Move COUNT lines up, keeping the goal column."
  :type linewise
  (aim--line-move (- count)))

(aim-define-motion aim-line-beginning (_count)
  "Move to the beginning of the line."
  (goto-char (line-beginning-position)))

(aim-define-motion aim-first-non-blank (_count)
  "Move to the first non-blank character of the line."
  (back-to-indentation))

(aim-define-motion aim-line-end (count)
  "Move to the end of the line, COUNT - 1 lines below."
  (when (> count 1)
    (forward-line (1- count)))
  (goto-char (line-end-position)))

;;;; Word motions

(aim-define-motion aim-forward-word-begin (count)
  "Move to the beginning of the COUNTth next word.
Vim's `dw'-keeps-the-newline special case is not handled here: it
falls out of the exclusive-motion adjustment rules in
`aim--expand-range'."
  (dotimes (_ count)
    (cond ((looking-at-p (concat "[" aim--word-chars "]"))
           (skip-chars-forward aim--word-chars))
          ((not (looking-at-p "[ \t\n]"))
           (skip-chars-forward (concat "^" aim--word-chars " \t\n"))))
    (skip-chars-forward " \t\n")))

(aim-define-motion aim-backward-word-begin (count)
  "Move to the beginning of the COUNTth previous word."
  (dotimes (_ count)
    (skip-chars-backward " \t\n")
    (let ((c (char-before)))
      (cond ((null c))
            ((string-match-p (concat "[" aim--word-chars "]")
                             (char-to-string c))
             (skip-chars-backward aim--word-chars))
            (t
             (skip-chars-backward (concat "^" aim--word-chars " \t\n")))))))

(aim-define-motion aim-forward-word-end (count)
  "Move onto the last character of the COUNTth next word."
  :type inclusive
  (dotimes (_ count)
    (unless (eobp) (forward-char))
    (skip-chars-forward " \t\n")
    (cond ((looking-at-p (concat "[" aim--word-chars "]"))
           (skip-chars-forward aim--word-chars))
          ((not (eobp))
           (skip-chars-forward (concat "^" aim--word-chars " \t\n"))))
    (unless (bobp) (backward-char))))

;;;; Buffer motions

(aim-define-motion aim-goto-first-line (count)
  "Move to line COUNT (default the first), at its first non-blank."
  :type linewise
  (goto-char (point-min))
  (forward-line (1- count))
  (back-to-indentation))

(aim-define-motion aim-goto-line (count)
  "Move to line COUNT, or the last line without a count."
  :type linewise
  :interactive "P"
  (if count
      (progn (goto-char (point-min))
             (forward-line (1- (prefix-numeric-value count))))
    (goto-char (point-max))
    (when (and (bolp) (not (bobp)))
      (forward-line -1)))
  (back-to-indentation))

;;;; Find-char motions

(defun aim--find-char (count forward)
  "Search for the next typed character COUNT times on this line.
Move FORWARD or backward onto the found character; signal
`user-error' without moving when the character is absent."
  (let ((ch (char-to-string (aim--read-char (if forward "f-" "F-"))))
        (start (point))
        (case-fold-search nil))
    (condition-case nil
        (if forward
            (progn (forward-char)
                   (search-forward ch (line-end-position) nil count)
                   (backward-char))
          (search-backward ch (line-beginning-position) nil count))
      (error
       (goto-char start)
       (user-error "Can't find %s" ch)))))

(aim-define-motion aim-find-char (count)
  "Move onto the COUNTth occurrence of the next typed character."
  :type inclusive
  (aim--find-char count t))

(aim-define-motion aim-find-char-to (count)
  "Move just before the COUNTth occurrence of the next typed character."
  :type inclusive
  (aim--find-char count t)
  (backward-char))

(aim-define-motion aim-find-char-backward (count)
  "Move back onto the COUNTth previous occurrence of the typed character."
  (aim--find-char count nil))

(aim-define-motion aim-find-char-to-backward (count)
  "Move just after the COUNTth previous occurrence of the typed character."
  (aim--find-char count nil)
  (forward-char))

(provide 'aim-motions)
;;; aim-motions.el ends here
