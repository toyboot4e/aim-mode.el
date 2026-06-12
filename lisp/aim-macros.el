;;; aim-macros.el --- Definition macros and the motion type system  -*- lexical-binding: t; -*-

;;; Commentary:

;; The top layer of the aim-mode Kernel: `aim-define-motion' and
;; `aim-define-operator', plus the motion type system (exclusive,
;; inclusive, linewise) that mediates between motions and operators
;; (docs/adr/0003).  An operator reads one motion (or its own doubled
;; key) in operator-pending State, expands the motion's movement into a
;; buffer range according to the motion's type, and acts on that range.

;;; Code:

(require 'aim-core)

;;;; Definition macros

(defmacro aim-define-motion (name arglist &rest body)
  "Define NAME as an aim motion command with ARGLIST and BODY.

ARGLIST must accept the count as its first argument.  BODY may begin
with a docstring, followed by optional keywords: :type (`exclusive',
`inclusive' or `linewise'; default `exclusive') and :interactive (an
interactive spec string; default \"p\")."
  (declare (indent defun) (doc-string 3))
  (let ((doc (if (stringp (car body)) (pop body)
               (format "Motion `%s'." name)))
        (type 'exclusive)
        (ispec "p"))
    (while (keywordp (car body))
      (pcase (pop body)
        (:type (setq type (pop body)))
        (:interactive (setq ispec (pop body)))
        (other (error "Unknown aim-define-motion keyword: %S" other))))
    `(progn
       (put ',name 'aim-motion-type ',type)
       (defun ,name ,arglist
         ,doc
         (interactive ,ispec)
         ,@body))))

(defmacro aim-define-operator (name arglist &rest body)
  "Define NAME as an aim operator command with ARGLIST and BODY.

ARGLIST must be (BEG END TYPE).  When invoked interactively the
operator reads a motion in operator-pending State; BODY then runs
with the expanded range.  Pressing the operator's own key acts on
whole lines (like `dd')."
  (declare (indent defun) (doc-string 3))
  (let ((doc (if (stringp (car body)) (pop body)
               (format "Operator `%s'." name))))
    `(progn
       (put ',name 'aim-operator t)
       (defun ,name ,arglist
         ,doc
         (interactive (aim--operator-range (this-single-command-keys)))
         ,@body))))

;;;; Ranges

(defun aim--expand-range (beg end type)
  "Expand the motion movement BEG..END into a range per TYPE.
Return (BEG END TYPE) with BEG <= END; inclusive ranges cover the
character at END, linewise ranges cover whole lines."
  (declare (ftype (function (integer integer symbol) list)))
  (let ((b (min beg end))
        (e (max beg end)))
    (pcase type
      ('inclusive (list b (min (1+ e) (point-max)) 'inclusive))
      ('linewise (list (save-excursion (goto-char b) (line-beginning-position))
                       (save-excursion (goto-char e) (line-beginning-position 2))
                       'linewise))
      (_ (list b e 'exclusive)))))

(defun aim--line-range (count)
  "Return the linewise range (BEG END linewise) of COUNT lines at point."
  (declare (ftype (function (integer) list)))
  (list (line-beginning-position)
        (line-beginning-position (1+ count))
        'linewise))

;;;; Operator-pending State

(defun aim--operator-range (op-keys)
  "Read a motion in operator-pending State and return (BEG END TYPE).
OP-KEYS is the key sequence that invoked the operator; pressing it
again selects whole lines.  Counts given to the operator and to the
motion multiply, as in Vim (`2d3w' acts on six words)."
  (let ((op-count (prefix-numeric-value current-prefix-arg))
        (had-count current-prefix-arg)
        (motion-count nil))
    (aim-switch-state 'operator-pending)
    (unwind-protect
        (catch 'aim--range
          (while t
            (let* ((keys (read-key-sequence nil))
                   (cmd (key-binding keys t)))
              (cond
               ((memq cmd '(keyboard-quit undefined))
                (keyboard-quit))
               ((eq cmd 'digit-argument)
                (setq motion-count
                      (+ (* (or motion-count 0) 10)
                         (- (aref keys (1- (length keys))) ?0))))
               ;; "0" extends a pending count; otherwise it is a motion.
               ((and motion-count (equal (key-description keys) "0"))
                (setq motion-count (* motion-count 10)))
               ((equal (key-description keys) (key-description op-keys))
                (throw 'aim--range
                       (aim--line-range (* op-count (or motion-count 1)))))
               ((and cmd (get cmd 'aim-motion-type))
                (let* ((beg (point))
                       (explicit (or motion-count had-count))
                       (current-prefix-arg
                        (and explicit (* op-count (or motion-count 1)))))
                  (call-interactively cmd)
                  (throw 'aim--range
                         (aim--expand-range beg (point)
                                            (get cmd 'aim-motion-type)))))
               (t
                (user-error "Not a motion: %s" (key-description keys)))))))
      (when (eq aim-state 'operator-pending)
        (aim-switch-state 'normal)))))

(provide 'aim-macros)
;;; aim-macros.el ends here
