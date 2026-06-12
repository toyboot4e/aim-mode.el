;;; aim-text-objects.el --- Common Core text objects  -*- lexical-binding: t; -*-

;;; Commentary:

;; Leaf module: the i/a text objects, read in operator-pending State
;; (`diw', `ci(', `da"' ...).  Words follow the syntax-table vocabulary
;; in aim-core; pair objects scan characters directly (no escape or
;; string-context awareness); quote objects pair up quotes from the
;; start of the line, like Vim.

;;; Code:

(require 'aim-macros)

;;;; Words

(defun aim--group-start ()
  "Move to the start of the character group at point."
  (cond ((aim--blank-char-p (char-after)) (skip-chars-backward " \t"))
        ((aim--word-char-p (char-after)) (aim--skip-word-backward))
        ((aim--punct-char-p (char-after)) (aim--skip-punct-backward))))

(defun aim--skip-group-forward ()
  "Skip past the character group at point (word, punctuation or blanks)."
  (cond ((aim--blank-char-p (char-after)) (skip-chars-forward " \t"))
        ((aim--word-char-p (char-after)) (aim--skip-word-forward))
        ((aim--punct-char-p (char-after)) (aim--skip-punct-forward))))

(aim-define-text-object aim-inner-word (count)
  "The word (or blank run) at point, plus COUNT - 1 following groups."
  (let (beg end)
    (save-excursion
      (aim--group-start)
      (setq beg (point))
      (dotimes (_ count) (aim--skip-group-forward))
      (setq end (point)))
    (when (= beg end)
      (user-error "No word at point"))
    (cons beg end)))

(aim-define-text-object aim-outer-word (count)
  "COUNT words at point with their trailing blanks.
Without trailing blanks the leading blanks are included instead;
starting on blanks includes them with the following word."
  (let (beg end)
    (save-excursion
      (if (aim--blank-char-p (char-after))
          (progn
            (skip-chars-backward " \t")
            (setq beg (point))
            (dotimes (_ count)
              (skip-chars-forward " \t")
              (aim--skip-group-forward))
            (setq end (point)))
        (aim--group-start)
        (setq beg (point))
        (dotimes (_ count)
          (aim--skip-group-forward)
          (skip-chars-forward " \t"))
        (setq end (point))
        ;; No blanks after the last word: take the leading ones.
        (unless (aim--blank-char-p (char-before end))
          (setq beg (save-excursion (goto-char beg)
                                    (skip-chars-backward " \t")
                                    (point))))))
    (when (= beg end)
      (user-error "No word at point"))
    (cons beg end)))

(aim-define-text-object aim-inner-bigword (count)
  "The WORD (non-blank run) at point, plus COUNT - 1 following groups."
  (let (beg end)
    (save-excursion
      (if (aim--blank-char-p (char-after))
          (skip-chars-backward " \t")
        (skip-chars-backward "^ \t\n"))
      (setq beg (point))
      (dotimes (_ count)
        (if (aim--blank-char-p (char-after))
            (skip-chars-forward " \t")
          (skip-chars-forward "^ \t\n")))
      (setq end (point)))
    (when (= beg end)
      (user-error "No WORD at point"))
    (cons beg end)))

(aim-define-text-object aim-outer-bigword (count)
  "COUNT WORDs at point with their trailing blanks."
  (let (beg end)
    (save-excursion
      (if (aim--blank-char-p (char-after))
          (skip-chars-backward " \t")
        (skip-chars-backward "^ \t\n"))
      (setq beg (point))
      (dotimes (_ count)
        (skip-chars-forward "^ \t\n")
        (skip-chars-forward " \t"))
      (setq end (point))
      (unless (aim--blank-char-p (char-before end))
        (setq beg (save-excursion (goto-char beg)
                                  (skip-chars-backward " \t")
                                  (point)))))
    (when (= beg end)
      (user-error "No WORD at point"))
    (cons beg end)))

;;;; Pairs
;; Scanning helpers live in aim-core (shared with the % motion).

(defun aim--pair-range (open close count around)
  "Range of the COUNTth OPEN..CLOSE pair enclosing point.
Inner range excludes the pair characters; AROUND includes them."
  (let* ((openp (aim--scan-open-backward open close count))
         (closep (and openp (aim--match-close openp open close))))
    (unless closep
      (user-error "No surrounding %c%c" open close))
    (if around
        (cons openp (1+ closep))
      (cons (1+ openp) closep))))

(defmacro aim--define-pair-objects (open close suffix)
  "Define inner and outer text objects for the OPEN..CLOSE pair.
SUFFIX names them aim-inner-SUFFIX / aim-outer-SUFFIX."
  `(progn
     (aim-define-text-object ,(intern (format "aim-inner-%s" suffix)) (count)
       ,(format "Inside the COUNTth enclosing %c%c pair." open close)
       (aim--pair-range ,open ,close count nil))
     (aim-define-text-object ,(intern (format "aim-outer-%s" suffix)) (count)
       ,(format "The COUNTth enclosing %c%c pair, included." open close)
       (aim--pair-range ,open ,close count t))))

(aim--define-pair-objects ?\( ?\) "paren")
(aim--define-pair-objects ?\[ ?\] "bracket")
(aim--define-pair-objects ?{ ?} "brace")
(aim--define-pair-objects ?< ?> "angle")

;;;; Quotes

(defun aim--quote-range (quote around)
  "Range of QUOTE-delimited text on the current line.
Quotes pair up from the start of the line; the first pair ending at
or after point is used.  Inner range excludes the quotes; AROUND
includes them plus trailing blanks (or leading ones without any)."
  (let ((str (char-to-string quote))
        (positions nil)
        (pair nil))
    (save-excursion
      (goto-char (line-beginning-position))
      (while (search-forward str (line-end-position) t)
        (push (1- (point)) positions)))
    (setq positions (nreverse positions))
    (while (and (cdr positions) (not pair))
      (let ((o (pop positions))
            (c (pop positions)))
        (when (<= (point) c)
          (setq pair (cons o c)))))
    (unless pair
      (user-error "No %s-quoted text on this line" str))
    (if around
        (let* ((b (car pair))
               (e (1+ (cdr pair)))
               (e2 (save-excursion (goto-char e)
                                   (skip-chars-forward " \t")
                                   (point))))
          (if (> e2 e)
              (cons b e2)
            (cons (save-excursion (goto-char b)
                                  (skip-chars-backward " \t")
                                  (point))
                  e)))
      (cons (1+ (car pair)) (cdr pair)))))

(defmacro aim--define-quote-objects (char suffix)
  "Define inner and outer text objects for CHAR-quoted text.
SUFFIX names them aim-inner-SUFFIX / aim-outer-SUFFIX."
  `(progn
     (aim-define-text-object ,(intern (format "aim-inner-%s" suffix)) (_count)
       ,(format "Inside %c-quoted text on the current line." char)
       (aim--quote-range ,char nil))
     (aim-define-text-object ,(intern (format "aim-outer-%s" suffix)) (_count)
       ,(format "%c-quoted text on the current line, quotes included." char)
       (aim--quote-range ,char t))))

(aim--define-quote-objects ?\" "double-quote")
(aim--define-quote-objects ?\' "single-quote")
(aim--define-quote-objects ?\` "back-quote")

;;;; Paragraphs

(defun aim--paragraph-range (around)
  "Range of the paragraph at point: the block of similar-blank lines.
AROUND extends over following blank lines (or preceding ones when
there are none following).  Returns exact line boundaries."
  (let ((blank-re "^[ \t]*$"))
    (save-excursion
      (forward-line 0)
      (let* ((on-blank (and (looking-at-p blank-re) t))
             (beg (save-excursion
                    (while (and (not (bobp))
                                (save-excursion
                                  (forward-line -1)
                                  (eq (and (looking-at-p blank-re) t) on-blank)))
                      (forward-line -1))
                    (point)))
             (end (save-excursion
                    (while (and (not (eobp))
                                (eq (and (looking-at-p blank-re) t) on-blank))
                      (forward-line 1))
                    (point))))
        (when around
          (let ((end2 (save-excursion
                        (goto-char end)
                        (while (and (not (eobp)) (looking-at-p blank-re))
                          (forward-line 1))
                        (point))))
            (if (> end2 end)
                (setq end end2)
              (setq beg (save-excursion
                          (goto-char beg)
                          (while (and (not (bobp))
                                      (save-excursion (forward-line -1)
                                                      (looking-at-p blank-re)))
                            (forward-line -1))
                          (point))))))
        (cons beg end)))))

(aim-define-text-object aim-inner-paragraph (_count)
  "The block of lines around point with the same blankness."
  :type linewise
  (aim--paragraph-range nil))

(aim-define-text-object aim-outer-paragraph (_count)
  "The paragraph at point plus its surrounding blank lines."
  :type linewise
  (aim--paragraph-range t))

(provide 'aim-text-objects)
;;; aim-text-objects.el ends here
