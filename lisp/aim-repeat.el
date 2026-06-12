;;; aim-repeat.el --- Repeat (.) recording  -*- lexical-binding: t; -*-

;;; Commentary:

;; Kernel middle layer (docs/adr/0003): records the last editing
;; command — its input keys, its count, and any insert-session
;; keystrokes that follow — so `.' can replay it.  Commands declare
;; themselves repeatable via the `aim-repeatable' symbol property,
;; which the definition macros set.
;;
;; Recording is input-based: a command's own keys are taken from
;; `this-single-command-keys' (or from a transcript the command builds
;; while reading extra input, like an operator's motion or `f''s
;; character), and an insert session's keystrokes are appended until
;; the session ends.  Replay feeds the record back through
;; `execute-kbd-macro', with the count overridable (`3.').

;;; Code:

(require 'aim-core)

(defvar aim--repeat-record nil
  "Plist (:keys VECTOR :count COUNT) of the last repeatable command.")

(defvar aim--repeating nil
  "Non-nil while `aim-repeat' is replaying; suppresses recording.")

(defvar aim--pending-keys nil
  "Key transcript supplied by the current command, when it read extra input.
Consumed (and cleared) by `aim--repeat-post-command'.")

(defvar aim--transcript nil
  "When a list, input read via `aim--read-char' is appended to it.
Commands that read input beyond their key sequence bind this to
collect a complete transcript for the repeat record.")

(defvar aim--session-keys nil
  "Accumulated key vectors of the insert session being recorded, reversed.")

(defvar aim--session-count nil
  "Count of the command that opened the insert session being recorded.")

(defun aim--read-char (&optional prompt)
  "Read a character like `read-char', adding it to the repeat transcript.
PROMPT is passed to `read-char'."
  (let ((ch (read-char prompt)))
    (when aim--transcript
      (push (vector ch) aim--transcript))
    ch))

(defun aim--repeat-post-command ()
  "Record repeatable commands; runs on `post-command-hook'."
  (cond
   (aim--repeating nil)
   ;; A prefix command (digit-argument...) just ran: skip.  It restores
   ;; `real-this-command' to the previous command's value, so recording
   ;; here would re-record that command with the digit as its keys.
   (prefix-arg nil)
   ((not aim-state)
    (setq aim--session-keys nil))
   ;; Accumulating an insert session.
   (aim--session-keys
    (push (this-single-command-keys) aim--session-keys)
    (unless (eq aim-state 'insert)
      (setq aim--repeat-record
            (list :keys (apply #'vconcat (nreverse aim--session-keys))
                  :count aim--session-count)
            aim--session-keys nil)))
   ;; `real-this-command', not `this-command': commands like
   ;; `kill-region' set the latter for their own purposes.
   ((and (symbolp real-this-command) (get real-this-command 'aim-repeatable))
    (let* ((kind (get real-this-command 'aim-repeatable))
           ;; An operator that aborted leaves no transcript: skip it.
           (keys (cond (aim--pending-keys)
                       ((not (eq kind 'operator))
                        (this-single-command-keys))))
           (count (and current-prefix-arg
                       (prefix-numeric-value current-prefix-arg))))
      (when keys
        (if (eq aim-state 'insert)
            ;; The command opened an insert session; keep recording.
            (setq aim--session-keys (list keys)
                  aim--session-count count)
          (setq aim--repeat-record (list :keys keys :count count)))))))
  (setq aim--pending-keys nil))

(add-hook 'post-command-hook #'aim--repeat-post-command)

(defun aim-repeat (count)
  "Replay the last change; COUNT overrides its recorded count."
  (interactive "P")
  (let ((record aim--repeat-record))
    (unless record
      (user-error "Nothing to repeat"))
    (let* ((keys (plist-get record :keys))
           (n (if count
                  (prefix-numeric-value count)
                (plist-get record :count)))
           (aim--repeating t))
      (execute-kbd-macro
       (if n (vconcat (number-to-string n) keys) keys)))))

(provide 'aim-repeat)
;;; aim-repeat.el ends here
