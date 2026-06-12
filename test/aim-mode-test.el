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

(ert-deftest aim-motion-word-syntax-table ()
  "Word motions follow the buffer's syntax table (- in Lisp symbols)."
  (aim-test-with-buffer "|foo-bar baz"
    (lisp-mode)
    (aim-mode 1)
    (aim-test-keys "w")
    (should (equal (aim-test-buffer-state) "foo-bar |baz"))))

(ert-deftest aim-motion-bigword-forward ()
  (aim-test :initial "|foo.bar baz" :keys "W" :expect "foo.bar |baz"))

(ert-deftest aim-motion-bigword-backward ()
  (aim-test :initial "foo.bar |baz" :keys "B" :expect "|foo.bar baz"))

(ert-deftest aim-motion-bigword-end ()
  (aim-test :initial "|foo.bar baz" :keys "E" :expect "foo.ba|r baz"))

(ert-deftest aim-motion-h-stops-at-bol ()
  (aim-test :initial "abc\nd|ef" :keys "5h" :expect "abc\n|def"))

(ert-deftest aim-motion-l-stops-at-eol ()
  (aim-test :initial "a|bc\ndef" :keys "9l" :expect "abc|\ndef"))

(ert-deftest aim-motion-j-keeps-column ()
  (aim-test :initial "ab|c\ndef\n" :keys "j" :expect "abc\nde|f\n"))

(ert-deftest aim-motion-k-keeps-column ()
  (aim-test :initial "abc\nde|f\n" :keys "k" :expect "ab|c\ndef\n"))

(ert-deftest aim-motion-j-sticky-goal-column ()
  "The goal column survives travelling through a short line."
  (aim-test :initial "abc|d\nx\nlmnop\n" :keys "jj" :expect "abcd\nx\nlmn|op\n"))

(ert-deftest aim-motion-goal-column-resets ()
  "An intervening motion resets the goal column."
  (aim-test :initial "abc|d\nx\nlmnop\n" :keys "jhj" :expect "abcd\nx\n|lmnop\n"))

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

(ert-deftest aim-motion-repeat-find ()
  (aim-test :initial "|axbxc" :keys "fx;" :expect "axb|xc"))

(ert-deftest aim-motion-repeat-find-reverse ()
  (aim-test :initial "ax|bxc" :keys "fx," :expect "a|xbxc"))

(ert-deftest aim-op-delete-repeat-find ()
  "d; repeats the find inside an operator, inclusively."
  (aim-test :initial "|axbxc" :keys "fxd;" :expect "a|c"))

;;;; Block, pair and mark motions

(ert-deftest aim-motion-forward-paragraph ()
  (aim-test :initial "|aa\nbb\n\ncc\n" :keys "}" :expect "aa\nbb\n|\ncc\n"))

(ert-deftest aim-motion-backward-paragraph ()
  (aim-test :initial "aa\nbb\n\nc|c\n" :keys "{" :expect "aa\nbb\n|\ncc\n"))

(ert-deftest aim-motion-forward-sentence ()
  (aim-test :initial "|Foo bar.  Baz qux." :keys ")"
            :expect "Foo bar.  |Baz qux."))

(ert-deftest aim-motion-matching-pair-forward ()
  (aim-test :initial "|(ab)" :keys "%" :expect "(ab|)"))

(ert-deftest aim-motion-matching-pair-backward ()
  (aim-test :initial "(ab|)" :keys "%" :expect "|(ab)"))

(ert-deftest aim-op-delete-matching-pair ()
  (aim-test :initial "x|(ab)y" :keys "d%" :expect "x|y"))

(ert-deftest aim-marks-set-and-jump ()
  (aim-test :initial "|aa bb cc" :keys "maww`a" :expect "|aa bb cc"))

(ert-deftest aim-marks-line-jump ()
  (aim-test :initial "aa\n  b|b\n" :keys "magg'a" :expect "aa\n  |bb\n"))

(ert-deftest aim-marks-delete-to-mark ()
  (aim-test :initial "aa |bb cc" :keys "mawd`a" :expect "aa |cc"))

(ert-deftest aim-marks-backtick-backtick-bounces ()
  "`` returns to the position before the last jump."
  (aim-test :initial "aa\nb|b\ncc\n" :keys "G``" :expect "aa\nb|b\ncc\n"))

;;;; Search

(ert-deftest aim-search-lands-on-match-start ()
  (aim-test :initial "|ab cd ef cd" :keys "/cd RET" :expect "ab |cd ef cd"))

(ert-deftest aim-search-next-wraps ()
  (aim-test :initial "|ab cd ef cd" :keys "/cd RET nn" :expect "ab |cd ef cd"))

(ert-deftest aim-search-previous ()
  (aim-test :initial "|ab cd ef cd" :keys "/cd RET nN" :expect "ab |cd ef cd"))

(ert-deftest aim-search-symbol-at-point ()
  (aim-test :initial "ab |cd ef cd" :keys "*" :expect "ab cd ef |cd"))

(ert-deftest aim-search-as-operator-motion ()
  "dn deletes exclusively up to the next match."
  (aim-test :initial "|ab cd ef cd" :keys "/cd RET dn" :expect "ab |cd"))

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

(ert-deftest aim-op-shift-right-line ()
  (aim-test :initial "|a\nb\n" :keys ">>" :expect "    |a\nb\n"))

(ert-deftest aim-op-shift-right-motion ()
  (aim-test :initial "|a\nb\nc\n" :keys ">j" :expect "    |a\n    b\nc\n"))

(ert-deftest aim-op-shift-left ()
  (aim-test :initial "    a\n   |  b\n" :keys "<<" :expect "    a\n |b\n"))

;;;; Text objects

(ert-deftest aim-obj-inner-word ()
  (aim-test :initial "he|llo world" :keys "diw" :expect "| world"))

(ert-deftest aim-obj-inner-word-change ()
  (aim-test :initial "he|llo world" :keys "ciwxx ESC" :expect "x|x world"))

(ert-deftest aim-obj-inner-word-on-blank ()
  (aim-test :initial "ab| cd" :keys "diw" :expect "ab|cd"))

(ert-deftest aim-obj-inner-word-count ()
  "2iw covers the word and the following blank run."
  (aim-test :initial "|aa bb" :keys "d2iw" :expect "|bb"))

(ert-deftest aim-obj-outer-word ()
  (aim-test :initial "aa |bb cc" :keys "daw" :expect "aa |cc"))

(ert-deftest aim-obj-outer-word-no-trailing ()
  "Without trailing blanks, aw takes the leading ones."
  (aim-test :initial "aa b|b" :keys "daw" :expect "aa|"))

(ert-deftest aim-obj-outer-word-repeat ()
  (aim-test :initial "|aa bb cc dd" :keys "daw." :expect "|cc dd"))

(ert-deftest aim-obj-inner-bigword ()
  (aim-test :initial "x fo|o.bar y" :keys "diW" :expect "x | y"))

(ert-deftest aim-obj-inner-paren ()
  (aim-test :initial "(a|bc)" :keys "di(" :expect "(|)"))

(ert-deftest aim-obj-inner-paren-alias-b ()
  (aim-test :initial "(a|bc)" :keys "dib" :expect "(|)"))

(ert-deftest aim-obj-outer-paren ()
  (aim-test :initial "x(a|bc)y" :keys "da(" :expect "x|y"))

(ert-deftest aim-obj-paren-nested-count ()
  (aim-test :initial "(a(b|c)d)" :keys "2di(" :expect "(|)"))

(ert-deftest aim-obj-paren-on-open ()
  (aim-test :initial "|(abc)" :keys "di(" :expect "(|)"))

(ert-deftest aim-obj-inner-bracket ()
  (aim-test :initial "[a|b]" :keys "di]" :expect "[|]"))

(ert-deftest aim-obj-inner-brace ()
  (aim-test :initial "{a|b}" :keys "diB" :expect "{|}"))

(ert-deftest aim-obj-change-inner-quote ()
  (aim-test :initial "x \"a|bc\" y" :keys "ci\"yo ESC" :expect "x \"y|o\" y"))

(ert-deftest aim-obj-quote-before-point ()
  "Quote objects reach forward to the next quoted text on the line."
  (aim-test :initial "x| \"ab\" y" :keys "di\"" :expect "x \"|\" y"))

(ert-deftest aim-obj-outer-quote-trailing-space ()
  (aim-test :initial "x \"a|b\" y" :keys "da\"" :expect "x |y"))

(ert-deftest aim-obj-inner-paragraph ()
  (aim-test :initial "a\nb|\nc\n\nd\n" :keys "dip" :expect "|\nd\n"))

(ert-deftest aim-obj-outer-paragraph ()
  (aim-test :initial "a\nb|\nc\n\nd\n" :keys "dap" :expect "|d\n"))

;;;; Ex Dispatcher

(ert-deftest aim-ex-goto-line ()
  (aim-test :initial "|a\nb\nc\n" :keys ":3 RET" :expect "a\nb\n|c\n"))

(ert-deftest aim-ex-goto-last-line ()
  (aim-test :initial "|a\nb\nc\n" :keys ":$ RET" :expect "a\nb\n|c\n"))

(ert-deftest aim-ex-substitute-current-line ()
  "Without a range, :s touches the first match of the current line."
  (aim-test :initial "aa\na|a\n" :keys ":s/a/X/ RET" :expect "aa\n|Xa\n"))

(ert-deftest aim-ex-substitute-global ()
  (aim-test :initial "a|a\nba\n" :keys ":%s/a/X/g RET" :expect "XX\n|bX\n"))

(ert-deftest aim-ex-substitute-line-range ()
  (aim-test :initial "|aa\naa\naa\n" :keys ":1,2s/a/X/g RET"
            :expect "XX\n|XX\naa\n"))

(ert-deftest aim-ex-substitute-from-visual ()
  ":s from visual State defaults to the selected lines."
  (aim-test :initial "|aa\naa\nba\n" :keys "Vj:s/a/X/g RET"
            :expect "XX\n|XX\nba\n"))

(ert-deftest aim-ex-sexp-eval ()
  "A leading ( evaluates as Emacs Lisp."
  (aim-test-with-buffer "|x"
    (aim-mode 1)
    (defvar aim-test--ex-result nil)
    (setq aim-test--ex-result nil)
    ;; kbd treats spaces as separators; SPC spells them explicitly.
    (aim-test-keys ":(setq SPC aim-test--ex-result SPC 42) RET")
    (should (equal aim-test--ex-result 42))))

(ert-deftest aim-ex-mx-fallthrough ()
  "Unrecognized input naming a command runs it like M-x."
  (aim-test :initial "|x" :keys ":ignore RET" :expect "|x"))

(ert-deftest aim-ex-unknown-command-errors ()
  (aim-test-with-buffer "|x"
    (aim-mode 1)
    (should-error (aim-test-keys ":definitely-not-a-command RET")
                  :type 'user-error)))

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

(ert-deftest aim-cmd-kill-line-rest ()
  (aim-test :initial "ab|cdef" :keys "D" :expect "ab|"))

(ert-deftest aim-cmd-change-line-rest ()
  (aim-test :initial "ab|cdef" :keys "CX ESC" :expect "ab|X"))

(ert-deftest aim-cmd-copy-line ()
  (aim-test :initial "|abc\n" :keys "Yp" :expect "abc\n|abc\n"))

(ert-deftest aim-cmd-replace-char ()
  (aim-test :initial "|abc" :keys "rx" :expect "|xbc"))

(ert-deftest aim-cmd-replace-char-count ()
  (aim-test :initial "|abcd" :keys "3rx" :expect "xx|xd"))

(ert-deftest aim-cmd-replace-char-too-short ()
  "r past the end of the line errors without changing anything."
  (aim-test-with-buffer "ab|cd"
    (aim-mode 1)
    (should-error (aim-test-keys "9rx") :type 'user-error)
    (should (equal (aim-test-buffer-state) "ab|cd"))))

(ert-deftest aim-cmd-invert-case ()
  (aim-test :initial "|aBc" :keys "2~" :expect "Ab|c"))

(ert-deftest aim-cmd-join-lines ()
  (aim-test :initial "ab|c\n  def\n" :keys "J" :expect "abc| def\n"))

(ert-deftest aim-cmd-join-lines-count ()
  (aim-test :initial "|a\nb\nc\nd\n" :keys "3J" :expect "a b| c\nd\n"))

;;;; Visual State

(ert-deftest aim-visual-char-delete ()
  (aim-test :initial "|abcdef" :keys "vlld" :expect "|def"))

(ert-deftest aim-visual-char-yank-paste ()
  (aim-test :initial "|abc" :keys "vlyp" :expect "aa|bbc"))

(ert-deftest aim-visual-line-delete ()
  (aim-test :initial "a\n|bcd\ne\n" :keys "Vd" :expect "a\n|e\n"))

(ert-deftest aim-visual-line-extend-delete ()
  (aim-test :initial "|a\nb\nc\n" :keys "Vjd" :expect "|c\n"))

(ert-deftest aim-visual-char-across-lines ()
  (aim-test :initial "ab|c\ndef\n" :keys "vjd" :expect "ab|\n"))

(ert-deftest aim-visual-exchange-ends ()
  "o swaps the ends, so h extends the selection backward."
  (aim-test :initial "a|bcd" :keys "vlohd" :expect "|d"))

(ert-deftest aim-visual-escape-leaves-selection ()
  (aim-test :initial "a|bc" :keys "vl ESC x" :expect "ab|"))

(ert-deftest aim-visual-restore-gv ()
  (aim-test :initial "a|bcd" :keys "vl ESC gvd" :expect "a|d"))

(ert-deftest aim-visual-inner-word-object ()
  (aim-test :initial "he|llo world" :keys "viwd" :expect "| world"))

(ert-deftest aim-visual-inner-paren-object ()
  (aim-test :initial "(a|bc)" :keys "vibd" :expect "(|)"))

(ert-deftest aim-visual-paragraph-object ()
  (aim-test :initial "a\nb|\nc\n\nd\n" :keys "vipd" :expect "|\nd\n"))

(ert-deftest aim-visual-change ()
  (aim-test :initial "|abc def" :keys "vllcxy ESC" :expect "x|y def"))

(ert-deftest aim-visual-shift ()
  (aim-test :initial "|a\nb\nc\n" :keys "Vj>" :expect "    |a\n    b\nc\n"))

;;;; Repeat

(ert-deftest aim-repeat-delete-char ()
  (aim-test :initial "|abcd" :keys "x." :expect "|cd"))

(ert-deftest aim-repeat-reuses-count ()
  (aim-test :initial "|abcdef" :keys "2x." :expect "|ef"))

(ert-deftest aim-repeat-count-override ()
  (aim-test :initial "|abcdef" :keys "3x2." :expect "|f"))

(ert-deftest aim-repeat-operator-motion ()
  (aim-test :initial "|aa bb cc dd" :keys "dw." :expect "|cc dd"))

(ert-deftest aim-repeat-doubled-operator ()
  (aim-test :initial "|a\nb\nc\nd\n" :keys "dd." :expect "|c\nd\n"))

(ert-deftest aim-repeat-find-char-argument ()
  "The character read by f is part of the repeat record."
  (aim-test :initial "|axbxc" :keys "dfx." :expect "|c"))

(ert-deftest aim-repeat-replace-char-argument ()
  "The character read by r is part of the repeat record."
  (aim-test :initial "|abcd" :keys "rxl." :expect "x|xcd"))

(ert-deftest aim-repeat-insert-session ()
  "Repeat replays an entire insert session's keystrokes."
  (aim-test :initial "|abc" :keys "ihi ESC ." :expect "hh|iiabc"))

(ert-deftest aim-repeat-change ()
  "Repeat replays a change operator with its typed replacement."
  (aim-test :initial "|aa bb cc" :keys "ceXX ESC w ." :expect "XX X|X cc"))

(ert-deftest aim-repeat-motions-do-not-clobber ()
  "Plain motions between change and repeat leave the record alone."
  (aim-test :initial "|abcd efg" :keys "xw." :expect "bcd |fg"))

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
