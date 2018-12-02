;;; flycheck-ghcid.el --- Flycheck integration for ghcid

;; Copyright (C) 2018 Alex Peitsinis

;; Author: Alex Peitsinis <alexpeitsinis@gmail.com>
;; Maintainer: Alex Peitsinis <alexpeitsinis@gmail.com>
;; Created: 01 Dec 2018
;; Modified: 02 Dec 2018
;; Version: 0.1
;; Package-Requires: ((flycheck))
;; Keywords: flycheck ghcid haskell
;; URL: https://github.com/alexpeits/flycheck-ghcid

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; TODO
;;
;; Please see README.md from the same repository for documentation.

;;; Code:

(require 'flycheck)
(require 'seq)
(require 'rx)

(defvar flycheck-ghcid-checker-executable "flycheck-ghcid-check.sh")
(defvar flycheck-ghcid-output-file ".ghcid-output")
(defvar-local flycheck-ghcid-default-directory nil)

(defun flycheck-ghcid-get-checker-executable ()
  flycheck-ghcid-executable)

(defun flycheck-ghcid-get-default-directory ()
  (or flycheck-ghcid-default-directory
      (flycheck-haskell--find-default-directory 'haskell-stack-ghc)))

(defun flycheck-ghcid-output-file-exists ()
  (let ((dir (flycheck-ghcid-get-default-directory)))
    (file-exists-p
     (concat (file-name-as-directory dir) flycheck-ghcid-output-file))))

(defun flycheck-ghcid-buffer-relevant-errors (errors)
  "Filter out the irrelevant errors from ERRORS.

Return a list of all errors that are relevant for their
corresponding buffer."
  (seq-filter '(lambda (err) (not (flycheck-relevant-error-other-file-p err))) errors))

(flycheck-define-checker haskell-ghcid
  "Use a running ghcid process to highlight errors
and warnings in haskell buffers."
  :command
  ((eval (flycheck-ghcid-get-checker-executable))
   (eval (my/flycheck-haskell-get-default-directory)))
  :error-patterns
  ((warning line-start (file-name) ":" line ":" column ":"
            (or " " "\n    ") (in "Ww") "arning:"
            (optional " " "[" (id (one-or-more not-newline)) "]")
            (optional "\n")
            (message
             (one-or-more " ") (one-or-more not-newline)
             (zero-or-more "\n"
                           (one-or-more " ")
                           (one-or-more (not (any ?\n ?|))))))
   (error line-start (file-name) ":" line ":" column ": error:"
          (or (message (one-or-more not-newline))
              (and "\n"
                   (message
                    (one-or-more " ") (one-or-more not-newline)
                    (zero-or-more "\n"
                                  (one-or-more " ")
                                  (one-or-more (not (any ?\n ?|)))))))
          line-end))
  :error-filter
  (lambda (errors)
    (flycheck-sanitize-errors
     (flycheck-dedent-error-messages
      (flycheck-ghcid-buffer-relevant-errors
       errors))))
  :modes haskell-mode
  :next-checkers ((warning . haskell-hlint))
  :predicate (lambda () (flycheck-ghcid-output-file-exists)))

(add-to-list 'flycheck-checkers 'haskell-ghcid)

(provide 'flycheck-ghcid)

;;; flycheck-ghcid.el ends here
