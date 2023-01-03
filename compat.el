;;; compat.el --- Emacs Lisp Compatibility Library -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2023 Free Software Foundation, Inc.

;; Author: Philip Kaludercic <philipk@posteo.net>, Daniel Mendler <mail@daniel-mendler.de>
;; Maintainer: Daniel Mendler <mail@daniel-mendler.de>, Compat Development <~pkal/compat-devel@lists.sr.ht>
;; Version: 29.1.0.0-git
;; URL: https://github.com/emacs-compat/compat
;; Package-Requires: ((emacs "24.4") (nadvice "0.3"))
;; Keywords: lisp

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; To allow for the usage of Emacs functions and macros that are
;; defined in newer versions of Emacs, compat.el provides definitions
;; that are installed ONLY if necessary.  These reimplementations of
;; functions and macros are at least subsets of the actual
;; implementations.  Be sure to read the documentation string to make
;; sure.
;;
;; Not every function provided in newer versions of Emacs is provided
;; here.  Some depend on new features from the core, others cannot be
;; implemented to a meaningful degree.  Please consult the Compat
;; manual for details.  The main audience for this library are not
;; regular users, but package maintainers.  Therefore commands and
;; user options are usually not implemented here.

;;; Code:

(require 'compat-29)

(defmacro compat-function (fun)
  "Return compatibility function symbol for FUN.

If the Emacs version provides a sufficiently recent version of
FUN, the symbol FUN is returned itself."
  (let ((compat (intern (format "compat--%s" fun))))
    `#',(if (fboundp compat) compat fun)))

(defmacro compat-call (fun &rest args)
  "Call compatibility function FUN with ARGS.

See `compat-function' for the compatibility function resolution."
  (let ((compat (intern (format "compat--%s" fun))))
    `(,(if (fboundp compat) compat fun) ,@args)))

(provide 'compat)
;;; compat.el ends here
