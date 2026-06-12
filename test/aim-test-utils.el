;;; aim-test-utils.el --- Declarative test harness for aim-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 toyboot4e

;; Author: toyboot4e <toyboot4e@gmail.com>
;; SPDX-License-Identifier: CC0-1.0

;; This file is part of aim-mode.

;;; Commentary:

;; The declarative buffer harness: a test states initial buffer text with
;; `|' marking point, the keys to feed, and the expected text-plus-point.
;; Tests read like Vim documentation:
;;
;;   (aim-test :initial "hello |world"
;;             :keys "dw"
;;             :expect "hello |")

;;; Code:

(require 'cl-lib)
(require 'ert)

(defmacro aim-test-with-buffer (initial &rest body)
  "Run BODY in a temp buffer initialized from INITIAL.
INITIAL is the buffer text; a `|' character marks point and is
removed.  Without a `|', point starts at the end of the buffer.

The buffer is shown in the selected window for BODY's duration:
the command loop driven by `execute-kbd-macro' acts on the selected
window's buffer, not merely on `current-buffer'."
  (declare (indent 1) (debug t))
  (let ((buffer (gensym "buffer")))
    `(let ((,buffer (generate-new-buffer " *aim-test*")))
       (unwind-protect
           (progn
             (set-window-buffer (selected-window) ,buffer)
             (with-current-buffer ,buffer
               (insert ,initial)
               (goto-char (point-min))
               (if (search-forward "|" nil t)
                   (delete-char -1)
                 (goto-char (point-max)))
               ,@body))
         (kill-buffer ,buffer)))))

(defun aim-test-keys (keys)
  "Execute KEYS, a `kbd' string, in the current buffer."
  (execute-kbd-macro (kbd keys)))

(defun aim-test-buffer-state ()
  "Return the buffer text with `|' inserted at point."
  (concat (buffer-substring-no-properties (point-min) (point))
          "|"
          (buffer-substring-no-properties (point) (point-max))))

(cl-defmacro aim-test (&key initial keys expect)
  "Assert that feeding KEYS to a buffer of INITIAL yields EXPECT.
INITIAL and EXPECT use `|' to mark point; KEYS is a `kbd' string,
or nil to test INITIAL parsing alone."
  `(aim-test-with-buffer ,initial
     (when ,keys (aim-test-keys ,keys))
     (should (equal (aim-test-buffer-state) ,expect))))

(provide 'aim-test-utils)
;;; aim-test-utils.el ends here
