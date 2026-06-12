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
(require 'aim-repeat)

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
whole lines (like `dd').

BODY may begin with a docstring, then optionally :motion-subst with
an alist of (MOTION . REPLACEMENT) command symbols: when point is on
a non-blank character, reading MOTION runs REPLACEMENT instead.
This expresses Vim special cases like `cw' acting as `ce'."
  (declare (indent defun) (doc-string 3))
  (let ((doc (if (stringp (car body)) (pop body)
               (format "Operator `%s'." name)))
        (subst nil))
    (while (keywordp (car body))
      (pcase (pop body)
        (:motion-subst (setq subst (pop body)))
        (other (error "Unknown aim-define-operator keyword: %S" other))))
    `(progn
       (put ',name 'aim-operator t)
       (put ',name 'aim-repeatable 'operator)
       (put ',name 'aim--motion-subst ',subst)
       (defun ,name ,arglist
         ,doc
         (interactive (aim--operator-range (this-single-command-keys) ',name))
         ,@body))))

(defmacro aim-define-text-object (name arglist &rest body)
  "Define NAME as a text object with ARGLIST and BODY.

ARGLIST must accept the count as its first argument.  BODY may begin
with a docstring, then optionally :type (`charwise', the default, or
`linewise').  BODY returns the object's range as a cons (BEG . END);
a linewise object must return exact line boundaries (BEG at a line
beginning, END at the line beginning after its last line).  Signal
`user-error' when there is no object at point.

Text objects are read in operator-pending State in place of a
motion; they are not meaningful as standalone normal-State commands."
  (declare (indent defun) (doc-string 3))
  (let ((doc (if (stringp (car body)) (pop body)
               (format "Text object `%s'." name)))
        (type 'charwise))
    (while (keywordp (car body))
      (pcase (pop body)
        (:type (setq type (pop body)))
        (other (error "Unknown aim-define-text-object keyword: %S" other))))
    `(progn
       (put ',name 'aim-text-object ',type)
       (defun ,name ,arglist
         ,doc
         (interactive "p")
         ,@body))))

(defmacro aim-define-command (name arglist &rest body)
  "Define NAME as a repeatable editing command with ARGLIST and BODY.

BODY may begin with a docstring, then optionally :interactive with
an interactive spec string (default: no argument).  The command
records itself for `aim-repeat', including any input it reads
through `aim--read-char'."
  (declare (indent defun) (doc-string 3))
  (let ((doc (if (stringp (car body)) (pop body)
               (format "Command `%s'." name)))
        (ispec nil))
    (while (keywordp (car body))
      (pcase (pop body)
        (:interactive (setq ispec (pop body)))
        (other (error "Unknown aim-define-command keyword: %S" other))))
    `(progn
       (put ',name 'aim-repeatable t)
       (defun ,name ,arglist
         ,doc
         (interactive ,@(and ispec (list ispec)))
         (let ((aim--transcript
                (and (not aim--repeating)
                     (not aim--transcript)
                     (list (this-single-command-keys)))))
           (prog1 (progn ,@body)
             (when aim--transcript
               (setq aim--pending-keys
                     (apply #'vconcat (nreverse aim--transcript))))))))))

;;;; Ranges

(defun aim--expand-range (beg end type)
  "Expand the motion movement BEG..END into a range per TYPE.
Return (BEG END TYPE) with BEG <= END; inclusive ranges cover the
character at END, linewise ranges cover whole lines.

Exclusive ranges get Vim's two adjustment rules (:h exclusive-linewise):
when the range ends at the beginning of a line below its start, the end
backs up before that newline (so `dw' on a line's last word keeps the
newline), and the range becomes linewise when the start also sits at or
before the first non-blank of its line."
  (declare (ftype (function (integer integer symbol) list)))
  (let ((b (min beg end))
        (e (max beg end)))
    (pcase type
      ('inclusive (list b (min (1+ e) (point-max)) 'inclusive))
      ('linewise (list (save-excursion (goto-char b) (line-beginning-position))
                       (save-excursion (goto-char e) (line-beginning-position 2))
                       'linewise))
      (_
       (if (and (> e b)
                (save-excursion (goto-char e) (bolp))
                (> e (save-excursion (goto-char b) (line-end-position))))
           ;; Rule 1: back up before the previous line's newline,
           ;; unless that empties the range (then keep the newline).
           (if (<= (1- e) b)
               (list b e 'exclusive)
             ;; Rule 2: linewise when only blanks precede the start.
             (if (save-excursion
                   (goto-char b)
                   (skip-chars-backward " \t" (line-beginning-position))
                   (bolp))
                 (list (save-excursion (goto-char b) (line-beginning-position))
                       e
                       'linewise)
               (list b (1- e) 'exclusive)))
         (list b e 'exclusive))))))

(defun aim--line-range (count)
  "Return the linewise range (BEG END linewise) of COUNT lines at point."
  (declare (ftype (function (integer) list)))
  (list (line-beginning-position)
        (line-beginning-position (1+ count))
        'linewise))

;;;; Operator-pending State

(defun aim--visual-range ()
  "Range (BEG END TYPE) of the active visual selection."
  (let ((m (or (mark) (user-error "No selection")))
        (p (point)))
    (if (eq aim--visual-kind 'line)
        (aim--expand-range (min m p) (max m p) 'linewise)
      ;; Charwise selections include the character at their far end.
      (list (min m p) (min (1+ (max m p)) (point-max)) 'exclusive))))

(defun aim--operator-range (op-keys &optional operator)
  "Return (BEG END TYPE) for an operator: the selection or a read motion.
In visual State, the selection is the range and visual State ends.
Otherwise a motion is read in operator-pending State: OP-KEYS is the
key sequence that invoked the operator; pressing it again selects
whole lines.  Counts given to the operator and to the motion
multiply, as in Vim (`2d3w' acts on six words).  OPERATOR is the
operator command symbol, used for its motion substitutions."
  (if (eq aim-state 'visual)
      (prog1 (aim--visual-range)
        (aim--visual-leave))
    (aim--operator-read-range op-keys operator)))

(defun aim--operator-read-range (op-keys operator)
  "Read a motion in operator-pending State; see `aim--operator-range'.
OP-KEYS and OPERATOR as there."
  (let ((op-count (prefix-numeric-value current-prefix-arg))
        (had-count current-prefix-arg)
        (motion-count nil)
        (aim--transcript (and (not aim--repeating) (list op-keys))))
    (aim-switch-state 'operator-pending)
    (unwind-protect
        (catch 'aim--range
          (while t
            (let* ((keys (read-key-sequence nil))
                   (cmd (key-binding keys t)))
              (when aim--transcript
                (push keys aim--transcript))
              (cond
               ;; The doubled key first: its global binding is
               ;; irrelevant (it may resolve to `undefined' via the
               ;; self-insert remap).
               ((equal (key-description keys) (key-description op-keys))
                (aim--operator-finish-transcript)
                (throw 'aim--range
                       (aim--line-range (* op-count (or motion-count 1)))))
               ((memq cmd '(keyboard-quit undefined))
                (keyboard-quit))
               ((eq cmd 'digit-argument)
                (setq motion-count
                      (+ (* (or motion-count 0) 10)
                         (- (aref keys (1- (length keys))) ?0))))
               ;; "0" extends a pending count; otherwise it is a motion.
               ((and motion-count (equal (key-description keys) "0"))
                (setq motion-count (* motion-count 10)))
               ((and cmd (get cmd 'aim-text-object))
                (let ((range (funcall cmd (* op-count (or motion-count 1)))))
                  (aim--operator-finish-transcript)
                  (throw 'aim--range
                         (list (car range) (cdr range)
                               (if (eq (get cmd 'aim-text-object) 'linewise)
                                   'linewise
                                 'exclusive)))))
               ((and cmd (get cmd 'aim-motion-type))
                (when (and operator (not (looking-at-p "[ \t\n]")))
                  (setq cmd (or (alist-get cmd (get operator 'aim--motion-subst))
                                cmd)))
                (let* ((beg (point))
                       (explicit (or motion-count had-count))
                       (current-prefix-arg
                        (and explicit (* op-count (or motion-count 1)))))
                  (call-interactively cmd)
                  (aim--operator-finish-transcript)
                  (throw 'aim--range
                         (aim--expand-range beg (point)
                                            (get cmd 'aim-motion-type)))))
               (t
                (user-error "Not a motion: %s" (key-description keys)))))))
      (when (eq aim-state 'operator-pending)
        (aim-switch-state 'normal)))))

(defun aim--operator-finish-transcript ()
  "Publish the operator's key transcript for the repeat record."
  (when aim--transcript
    (setq aim--pending-keys (apply #'vconcat (nreverse aim--transcript)))))

(provide 'aim-macros)
;;; aim-macros.el ends here
