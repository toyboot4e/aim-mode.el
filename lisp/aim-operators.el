;;; aim-operators.el --- Common Core operators  -*- lexical-binding: t; -*-

;;; Commentary:

;; Leaf module: the d / c / y operators.  Killed and yanked text goes
;; to the kill-ring (the unnamed register; docs/adr/0002).
;;
;; Known divergence, to fix in a later Milestone: `cw' eats the
;; trailing whitespace (Vim treats `cw' as `ce').

;;; Code:

(require 'aim-macros)

(aim-define-operator aim-delete (beg end type)
  "Kill from BEG to END; linewise TYPE kills whole lines."
  (kill-region beg end)
  (goto-char beg)
  (when (eq type 'linewise)
    (back-to-indentation)))

(aim-define-operator aim-change (beg end type)
  "Kill from BEG to END and enter insert State.
A linewise TYPE keeps an empty line to insert into.  The kill and
the following insertion form a single undo step."
  (aim--start-undo-session)
  (kill-region beg end)
  (goto-char beg)
  (when (eq type 'linewise)
    (insert "\n")
    (backward-char))
  (aim-switch-state 'insert))

(aim-define-operator aim-yank (beg end type)
  "Copy from BEG to END into the kill-ring.
Point moves to BEG, except for a linewise yank that already contains
point, which stays put (like `yy')."
  (copy-region-as-kill beg end)
  (unless (and (eq type 'linewise)
               (<= beg (point))
               (< (point) end))
    (goto-char beg)))

(provide 'aim-operators)
;;; aim-operators.el ends here
