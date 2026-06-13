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

(aim-define-motion aim-last-non-blank (count)
  "Move onto the last non-blank char, COUNT - 1 lines below (Vim's g_)."
  :type inclusive
  (when (> count 1)
    (forward-line (1- count)))
  (goto-char (line-end-position))
  (skip-chars-backward " \t")
  (unless (bolp) (backward-char)))

(aim-define-motion aim-goto-column (count)
  "Move to column COUNT on this line (1-based; Vim's |)."
  (forward-line 0)
  (move-to-column (1- count)))

(aim-define-motion aim-next-line-non-blank (count)
  "Move to the first non-blank of the COUNTth next line (Vim's +)."
  :type linewise
  (forward-line count)
  (back-to-indentation))

(aim-define-motion aim-previous-line-non-blank (count)
  "Move to the first non-blank of the COUNTth previous line (Vim's -)."
  :type linewise
  (forward-line (- count))
  (back-to-indentation))

(aim-define-motion aim-current-line-non-blank (count)
  "Move to the first non-blank, COUNT - 1 lines down (Vim's _)."
  :type linewise
  (forward-line (1- count))
  (back-to-indentation))

(aim-define-motion aim-next-visual-line (count)
  "Move COUNT display lines down, keeping the column (Vim's gj)."
  (line-move-visual count t))

(aim-define-motion aim-previous-visual-line (count)
  "Move COUNT display lines up, keeping the column (Vim's gk)."
  (line-move-visual (- count) t))

;;;; Section motions
;; Mapped onto Emacs's defun motions (Vim's sections are file-type
;; specific; defun boundaries are the closest portable analogue).

(aim-define-motion aim-backward-section (count)
  "Move back to the start of a section/defun (Vim's [[)."
  :type exclusive
  (beginning-of-defun count))

(aim-define-motion aim-forward-section (count)
  "Move forward to the start of a section/defun (Vim's ]])."
  :type exclusive
  (beginning-of-defun (- count)))

(aim-define-motion aim-backward-section-end (count)
  "Move back to the end of a section/defun (Vim's [])."
  :type exclusive
  (end-of-defun (- count)))

(aim-define-motion aim-forward-section-end (count)
  "Move forward to the end of a section/defun (Vim's ][)."
  :type exclusive
  (end-of-defun count))

;;;; Word motions

(aim-define-motion aim-forward-word-begin (count)
  "Move to the beginning of the COUNTth next word.
Vim's `dw'-keeps-the-newline special case is not handled here: it
falls out of the exclusive-motion adjustment rules in
`aim--expand-range'."
  (dotimes (_ count)
    (cond ((aim--word-char-p (char-after)) (aim--skip-word-forward))
          ((aim--punct-char-p (char-after)) (aim--skip-punct-forward)))
    (skip-chars-forward " \t\n")))

(aim-define-motion aim-backward-word-begin (count)
  "Move to the beginning of the COUNTth previous word."
  (dotimes (_ count)
    (skip-chars-backward " \t\n")
    (cond ((aim--word-char-p (char-before)) (aim--skip-word-backward))
          ((aim--punct-char-p (char-before)) (aim--skip-punct-backward)))))

(aim-define-motion aim-forward-word-end (count)
  "Move onto the last character of the COUNTth next word."
  :type inclusive
  (dotimes (_ count)
    (unless (eobp) (forward-char))
    (skip-chars-forward " \t\n")
    (cond ((aim--word-char-p (char-after)) (aim--skip-word-forward))
          ((aim--punct-char-p (char-after)) (aim--skip-punct-forward)))
    (unless (bobp) (backward-char))))

(aim-define-motion aim-forward-bigword-begin (count)
  "Move to the beginning of the COUNTth next WORD (non-blank run)."
  (dotimes (_ count)
    (skip-chars-forward "^ \t\n")
    (skip-chars-forward " \t\n")))

(aim-define-motion aim-backward-bigword-begin (count)
  "Move to the beginning of the COUNTth previous WORD (non-blank run)."
  (dotimes (_ count)
    (skip-chars-backward " \t\n")
    (skip-chars-backward "^ \t\n")))

(aim-define-motion aim-forward-bigword-end (count)
  "Move onto the last character of the COUNTth next WORD."
  :type inclusive
  (dotimes (_ count)
    (unless (eobp) (forward-char))
    (skip-chars-forward " \t\n")
    (skip-chars-forward "^ \t\n")
    (unless (bobp) (backward-char))))

;;;; Block motions

(aim-define-motion aim-forward-paragraph (count)
  "Move to the COUNTth next blank line after a paragraph."
  (dotimes (_ count)
    (forward-line 0)
    (while (and (not (eobp)) (looking-at-p "^[ \t]*$"))
      (forward-line 1))
    (while (and (not (eobp)) (not (looking-at-p "^[ \t]*$")))
      (forward-line 1))))

(aim-define-motion aim-backward-paragraph (count)
  "Move to the COUNTth previous blank line before a paragraph."
  (dotimes (_ count)
    (forward-line 0)
    (while (and (not (bobp)) (looking-at-p "^[ \t]*$"))
      (forward-line -1))
    (while (and (not (bobp)) (not (looking-at-p "^[ \t]*$")))
      (forward-line -1))))

(aim-define-motion aim-forward-sentence (count)
  "Move to the beginning of the COUNTth next sentence."
  (forward-sentence count)
  (skip-chars-forward " \t\n"))

(aim-define-motion aim-backward-sentence (count)
  "Move to the beginning of the COUNTth previous sentence."
  (backward-sentence count))

(aim-define-motion aim-matching-pair (_count)
  "Jump between matching pair characters (Vim's %).
Uses the first of ()[]{} at or after point on the current line."
  :type inclusive
  (let ((pairs '((?\( . ?\)) (?\[ . ?\]) (?{ . ?})))
        (pos nil))
    (save-excursion
      (while (and (not pos) (not (eolp)))
        (if (memq (char-after) '(?\( ?\) ?\[ ?\] ?{ ?}))
            (setq pos (point))
          (forward-char))))
    (unless pos
      (user-error "No pair character on this line"))
    (goto-char pos)
    (let* ((c (char-after))
           (open (rassq c pairs))
           (target (if open
                       ;; on a close char: its open
                       (aim--scan-open-backward (car open) c 1)
                     (aim--match-close pos c (cdr (assq c pairs))))))
      (unless target
        (user-error "Unmatched %c" c))
      (goto-char target))))

;;;; Window and scroll motions

(aim-define-motion aim-window-top (count)
  "Move to window line COUNT from the top, at its first non-blank."
  :type linewise
  (move-to-window-line (1- count))
  (back-to-indentation))

(aim-define-motion aim-window-middle (_count)
  "Move to the middle window line, at its first non-blank."
  :type linewise
  (move-to-window-line nil)
  (back-to-indentation))

(aim-define-motion aim-window-bottom (count)
  "Move to window line COUNT from the bottom, at its first non-blank."
  :type linewise
  (move-to-window-line (- count))
  (back-to-indentation))

(aim-define-motion aim-scroll-down (count)
  "Move COUNT half-windows down, scrolling."
  :type linewise
  (forward-line (* count (max 1 (/ (window-body-height) 2))))
  (ignore-errors (recenter)))

(aim-define-motion aim-scroll-up (count)
  "Move COUNT half-windows up, scrolling."
  :type linewise
  (forward-line (- (* count (max 1 (/ (window-body-height) 2)))))
  (ignore-errors (recenter)))

;;;; Buffer motions

(aim-define-motion aim-goto-first-line (count)
  "Move to line COUNT (default the first), at its first non-blank."
  :type linewise
  (aim--push-jump)
  (goto-char (point-min))
  (forward-line (1- count))
  (back-to-indentation))

(aim-define-motion aim-goto-line (count)
  "Move to line COUNT, or the last line without a count."
  :type linewise
  :interactive "P"
  (aim--push-jump)
  (if count
      (progn (goto-char (point-min))
             (forward-line (1- (prefix-numeric-value count))))
    (goto-char (point-max))
    (when (and (bolp) (not (bobp)))
      (forward-line -1)))
  (back-to-indentation))

;;;; Find-char motions

(defvar aim--last-find nil
  "Last find-char request, as a list (CHAR FORWARD TO), for `;' and `,'.")

(defun aim--find-char-1 (count ch forward to)
  "Move to the COUNTth occurrence of character CH on this line.
Search FORWARD or backward; land on the character, or next to it
when TO is non-nil.  Signal `user-error' without moving when the
character is absent."
  (let ((str (char-to-string ch))
        (start (point))
        (case-fold-search nil))
    (condition-case nil
        (if forward
            (progn (forward-char)
                   (search-forward str (line-end-position) nil count)
                   (backward-char (if to 2 1)))
          (search-backward str (line-beginning-position) nil count)
          (when to (forward-char)))
      (error
       (goto-char start)
       (user-error "Can't find %s" str)))))

(defun aim--find-char (count forward to)
  "Read a character and find its COUNTth occurrence on this line.
FORWARD and TO as in `aim--find-char-1'.  Remembers the request
for `;' and `,'."
  (let ((ch (aim--read-char (if forward "f-" "F-"))))
    (setq aim--last-find (list ch forward to))
    (aim--find-char-1 count ch forward to)))

(aim-define-motion aim-find-char (count)
  "Move onto the COUNTth occurrence of the next typed character."
  :type inclusive
  (aim--find-char count t nil))

(aim-define-motion aim-find-char-to (count)
  "Move just before the COUNTth occurrence of the next typed character."
  :type inclusive
  (aim--find-char count t t))

(aim-define-motion aim-find-char-backward (count)
  "Move back onto the COUNTth previous occurrence of the typed character."
  (aim--find-char count nil nil))

(aim-define-motion aim-find-char-to-backward (count)
  "Move just after the COUNTth previous occurrence of the typed character."
  (aim--find-char count nil t))

(aim-define-motion aim-repeat-find (count)
  "Repeat the last f/F/t/T, COUNT times."
  :type inclusive
  (pcase aim--last-find
    (`(,ch ,forward ,to)
     ;; The repeated find's type depends on its direction; the
     ;; operator loop reads the type property after the motion runs.
     (put 'aim-repeat-find 'aim-motion-type
          (if forward 'inclusive 'exclusive))
     (aim--find-char-1 count ch forward to))
    (_ (user-error "No find to repeat"))))

(aim-define-motion aim-repeat-find-reverse (count)
  "Repeat the last f/F/t/T in the opposite direction, COUNT times."
  :type exclusive
  (pcase aim--last-find
    (`(,ch ,forward ,to)
     (put 'aim-repeat-find-reverse 'aim-motion-type
          (if forward 'exclusive 'inclusive))
     (aim--find-char-1 count ch (not forward) to))
    (_ (user-error "No find to repeat"))))

;;;; Marks

(defun aim--goto-marker (line)
  "Jump to the marker read from the next key.
Backtick or apostrophe means the position before the last jump.
LINE lands on the first non-blank of the target line."
  (let ((ch (aim--read-char "mark:")))
    (cond ((memq ch '(?` ?'))
           (let ((m (or aim--last-jump
                        (user-error "No previous jump"))))
             (let ((pos (marker-position m)))
               (aim--push-jump)
               (goto-char pos))))
          (t
           (let ((r (get-register ch)))
             (unless (markerp r)
               (user-error "No marker in register %c" ch))
             (unless (eq (marker-buffer r) (current-buffer))
               (pop-to-buffer-same-window (marker-buffer r)))
             (aim--push-jump)
             (goto-char r))))
    (when line
      (back-to-indentation))))

(aim-define-motion aim-goto-marker (_count)
  "Jump to the marker read from the next key, exactly (Vim's backtick)."
  (aim--goto-marker nil))

(aim-define-motion aim-goto-marker-line (_count)
  "Jump to the marker's line, at its first non-blank (Vim's ')."
  :type linewise
  (aim--goto-marker t))

(provide 'aim-motions)
;;; aim-motions.el ends here
