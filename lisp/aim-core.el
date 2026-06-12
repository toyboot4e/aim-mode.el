;;; aim-core.el --- States and keymap machinery for aim-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 toyboot4e

;; Author: toyboot4e <toyboot4e@gmail.com>
;; SPDX-License-Identifier: CC0-1.0

;; This file is part of aim-mode.

;;; Commentary:

;; The bottom layer of the aim-mode Kernel: State definitions and keymap
;; machinery (see docs/adr/0003).  Milestone 0.1 ships only a skeleton so
;; the staged-compilation pipeline has a real layer below `aim-mode'.

;;; Code:

(defgroup aim nil
  "Yet another Vim mode."
  :group 'emulations
  :prefix "aim-")

(defconst aim-states
  '(normal insert operator-pending visual replace motion)
  "All States aim-mode ships in 1.0.")

(defvar-local aim-state nil
  "The current State of this buffer, or nil when aim-mode is disabled.")

(provide 'aim-core)
;;; aim-core.el ends here
