;;; aim-mode-test.el --- Kernel tracer-bullet tests  -*- lexical-binding: t; -*-

;;; Commentary:

;; Milestone 0.2 tests: harness self-tests, States, motions, operators
;; with counts and types, paste, and undo grouping.

;;; Code:

(require 'aim-test-utils)
(require 'aim-mode)

;;;; Harness self-tests (aim-mode off)

(ert-deftest aim-test-harness-self-insert ()
  "Keys fed by the harness reach the command loop."
  (aim-test :aim nil :initial "hello |world" :keys "foo"
            :expect "hello foo|world"))

(ert-deftest aim-test-harness-motion ()
  "Non-inserting commands move point as expected."
  (aim-test :aim nil :initial "|hello" :keys "C-e" :expect "hello|"))

(ert-deftest aim-test-harness-default-point ()
  "Without a `|' marker, point starts at the end of the buffer."
  (aim-test :aim nil :initial "abc" :keys nil :expect "abc|"))

;;;; States

(ert-deftest aim-state-toggle ()
  "Enabling aim-mode enters normal State; disabling clears it."
  (with-temp-buffer
    (aim-mode 1)
    (should aim-mode)
    (should (eq aim-state 'normal))
    (aim-mode -1)
    (should-not aim-state)))

(ert-deftest aim-state-insert-roundtrip ()
  "i enters insert State; ESC returns to normal, point one left."
  (aim-test :initial "ab|c" :keys "ix ESC" :expect "ab|xc"))

;;;; Motions

(ert-deftest aim-motion-word-forward ()
  (aim-test :initial "|hello world" :keys "w" :expect "hello |world"))

(ert-deftest aim-motion-word-punctuation ()
  (aim-test :initial "|foo.bar" :keys "w" :expect "foo|.bar"))

(ert-deftest aim-motion-word-count ()
  (aim-test :initial "|a b c d" :keys "3w" :expect "a b c |d"))

(ert-deftest aim-motion-word-backward ()
  (aim-test :initial "a b |c" :keys "b" :expect "a |b c"))

(ert-deftest aim-motion-word-end ()
  (aim-test :initial "|hello world" :keys "e" :expect "hell|o world"))

(ert-deftest aim-motion-h-stops-at-bol ()
  (aim-test :initial "abc\nd|ef" :keys "5h" :expect "abc\n|def"))

(ert-deftest aim-motion-l-stops-at-eol ()
  (aim-test :initial "a|bc\ndef" :keys "9l" :expect "abc|\ndef"))

(ert-deftest aim-motion-j-keeps-column ()
  (aim-test :initial "ab|c\ndef\n" :keys "j" :expect "abc\nde|f\n"))

(ert-deftest aim-motion-k-keeps-column ()
  (aim-test :initial "abc\nde|f\n" :keys "k" :expect "ab|c\ndef\n"))

(ert-deftest aim-motion-line-beginning ()
  (aim-test :initial "abc |def" :keys "0" :expect "|abc def"))

(ert-deftest aim-motion-first-non-blank ()
  (aim-test :initial "  ab|c" :keys "^" :expect "  |abc"))

(ert-deftest aim-motion-line-end ()
  (aim-test :initial "|abc" :keys "$" :expect "abc|"))

(ert-deftest aim-motion-goto-first-line ()
  (aim-test :initial "abc\n|def\n" :keys "gg" :expect "|abc\ndef\n"))

(ert-deftest aim-motion-goto-last-line ()
  (aim-test :initial "|abc\ndef\nghi\n" :keys "G" :expect "abc\ndef\n|ghi\n"))

(ert-deftest aim-motion-goto-line-count ()
  (aim-test :initial "|abc\ndef\nghi\n" :keys "2G" :expect "abc\n|def\nghi\n"))

(ert-deftest aim-motion-find-char ()
  (aim-test :initial "|hello" :keys "fl" :expect "he|llo"))

(ert-deftest aim-motion-find-char-count ()
  (aim-test :initial "|hello world" :keys "2fl" :expect "hel|lo world"))

(ert-deftest aim-motion-find-char-to ()
  (aim-test :initial "|hello" :keys "tl" :expect "h|ello"))

(ert-deftest aim-motion-find-char-backward ()
  (aim-test :initial "hell|o" :keys "Fh" :expect "|hello"))

(ert-deftest aim-motion-find-char-to-backward ()
  (aim-test :initial "hell|o" :keys "Th" :expect "h|ello"))

;;;; Operators

(ert-deftest aim-op-delete-word ()
  (aim-test :initial "hello |world foo" :keys "dw" :expect "hello |foo"))

(ert-deftest aim-op-delete-word-keeps-newline ()
  "Exclusive rule 1: dw on the last word stops before the newline."
  (aim-test :initial "abc |def\nghi" :keys "dw" :expect "abc |\nghi"))

(ert-deftest aim-op-delete-word-becomes-linewise ()
  "Exclusive rule 2: dw from indentation over a whole line is linewise."
  (aim-test :initial "  |def\nghi" :keys "dw" :expect "|ghi"))

(ert-deftest aim-op-delete-word-at-eol-joins ()
  "Degenerate rule 1: dw on the newline itself deletes it."
  (aim-test :initial "abc|\ndef" :keys "dw" :expect "abc|def"))

(ert-deftest aim-op-delete-word-end ()
  (aim-test :initial "|hello world" :keys "de" :expect "| world"))

(ert-deftest aim-op-delete-to-eol ()
  (aim-test :initial "ab|cdef" :keys "d$" :expect "ab|"))

(ert-deftest aim-op-delete-to-bol ()
  (aim-test :initial "abc|def" :keys "d0" :expect "|def"))

(ert-deftest aim-op-delete-line ()
  (aim-test :initial "a\n|b\nc\n" :keys "dd" :expect "a\n|c\n"))

(ert-deftest aim-op-delete-line-count ()
  (aim-test :initial "|a\nb\nc\n" :keys "2dd" :expect "|c\n"))

(ert-deftest aim-op-count-on-motion ()
  (aim-test :initial "|a b c d" :keys "d2w" :expect "|c d"))

(ert-deftest aim-op-counts-multiply ()
  (aim-test :initial "|a b c d e f g" :keys "2d3w" :expect "|g"))

(ert-deftest aim-op-delete-linewise-motion ()
  (aim-test :initial "|a\nb\nc\n" :keys "dj" :expect "|c\n"))

(ert-deftest aim-op-delete-find-char ()
  (aim-test :initial "|abxcd" :keys "dfx" :expect "|cd"))

(ert-deftest aim-op-delete-to-last-line ()
  (aim-test :initial "a\n|b\nc\n" :keys "dG" :expect "a\n|"))

(ert-deftest aim-op-delete-to-first-line ()
  (aim-test :initial "a\nb|c\nd\n" :keys "dgg" :expect "|d\n"))

(ert-deftest aim-op-change-word-end ()
  (aim-test :initial "|hello world" :keys "cebye ESC" :expect "by|e world"))

(ert-deftest aim-op-change-line ()
  (aim-test :initial "a\n|bcd\ne\n" :keys "ccx ESC" :expect "a\n|x\ne\n"))

(ert-deftest aim-op-change-word-acts-as-ce ()
  "Vim treats cw on a non-blank as ce: trailing whitespace survives."
  (aim-test :initial "|hello world" :keys "cwbye ESC" :expect "by|e world"))

(ert-deftest aim-op-change-on-blank-stays-cw ()
  "On whitespace, cw is not substituted and behaves like dw."
  (aim-test :initial "a| b" :keys "cwx ESC" :expect "a|xb"))

(ert-deftest aim-op-change-line-keeps-indent ()
  "cc preserves the line's indentation, like Vim with autoindent."
  (aim-test :initial "  ab|c\nz" :keys "ccx ESC" :expect "  |x\nz"))

(ert-deftest aim-op-yank-line-paste ()
  (aim-test :initial "|abc\ndef\n" :keys "yyp" :expect "abc\n|abc\ndef\n"))

(ert-deftest aim-op-yank-word-paste-before ()
  (aim-test :initial "|hello world" :keys "ywP" :expect "hello| hello world"))

;;;; Simple commands

(ert-deftest aim-cmd-delete-char ()
  (aim-test :initial "a|bc" :keys "x" :expect "a|c"))

(ert-deftest aim-cmd-delete-char-count ()
  (aim-test :initial "ab|cdef" :keys "3x" :expect "ab|f"))

(ert-deftest aim-cmd-transpose-xp ()
  (aim-test :initial "|abc" :keys "xp" :expect "b|ac"))

(ert-deftest aim-cmd-append ()
  (aim-test :initial "|abc" :keys "ax ESC" :expect "a|xbc"))

(ert-deftest aim-cmd-append-line ()
  (aim-test :initial "|abc" :keys "Ax ESC" :expect "abc|x"))

(ert-deftest aim-cmd-insert-line ()
  (aim-test :initial "  ab|c" :keys "Ix ESC" :expect "  |xabc"))

(ert-deftest aim-cmd-open-below ()
  (aim-test :initial "|abc\ndef\n" :keys "ox ESC" :expect "abc\n|x\ndef\n"))

(ert-deftest aim-cmd-open-above ()
  (aim-test :initial "abc\n|def\n" :keys "Ox ESC" :expect "abc\n|x\ndef\n"))

;;;; Undo

(ert-deftest aim-undo-delete-line ()
  (aim-test :initial "|a\nb\n" :keys "ddu" :expect "|a\nb\n"))

(ert-deftest aim-undo-insert-session-is-one-step ()
  "An entire insert session undoes as a single step."
  (aim-test :initial "|abc" :keys "ihi ESC u" :expect "|abc"))

(ert-deftest aim-undo-change-is-one-step ()
  "A change operator plus its insertion undoes as a single step."
  (aim-test :initial "|hello world" :keys "cebye ESC u" :expect "|hello world"))

(provide 'aim-mode-test)
;;; aim-mode-test.el ends here
