;;; aim-mode-test.el --- Milestone 0.1 smoke tests  -*- lexical-binding: t; -*-

;;; Commentary:

;; Smoke tests proving the pipeline: the harness drives a buffer through
;; the real command loop, and the aim-mode stub toggles its State.

;;; Code:

(require 'aim-test-utils)
(require 'aim-mode)

(ert-deftest aim-test-harness-self-insert ()
  "Keys fed by the harness reach the command loop."
  (aim-test :initial "hello |world"
            :keys "foo"
            :expect "hello foo|world"))

(ert-deftest aim-test-harness-motion ()
  "Non-inserting commands move point as expected."
  (aim-test :initial "|hello"
            :keys "C-e"
            :expect "hello|"))

(ert-deftest aim-test-harness-default-point ()
  "Without a `|' marker, point starts at the end of the buffer."
  (aim-test :initial "abc"
            :keys nil
            :expect "abc|"))

(ert-deftest aim-mode-test-toggle ()
  "Enabling aim-mode enters normal State; disabling clears it."
  (with-temp-buffer
    (aim-mode 1)
    (should aim-mode)
    (should (eq aim-state 'normal))
    (aim-mode -1)
    (should-not aim-state)))

(provide 'aim-mode-test)
;;; aim-mode-test.el ends here
