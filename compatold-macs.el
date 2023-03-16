;;; compatold-macs.el --- Compatibility Macros           -*- lexical-binding: t; no-byte-compile: t; -*-

;; Copyright (C) 2021-2023 Free Software Foundation, Inc.

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

;; These macros are used to define compatibility functions, macros and
;; advice.

;;; Code:

(defvar compatold--current-version nil
  "Default version to use when no explicit version was given.")

(defmacro compatold-declare-version (version)
  "Set the Emacs version that is currently being handled to VERSION."
  ;; FIXME: Avoid setting the version for any definition that might
  ;; follow, but try to restrict it to the current file/buffer.
  (setq compatold--current-version version)
  nil)

(defvar compatold--generate-function #'compatold--generate-default
  "Function used to generate compatibility code.
The function must take six arguments: NAME, DEF-FN, INSTALL-FN,
CHECK-FN, ATTR and TYPE.  The resulting body is constructed by
invoking the functions DEF-FN (passed the \"realname\" and the
version number, returning the compatibility definition), the
INSTALL-FN (passed the \"realname\" and returning the
installation code), CHECK-FN (passed the \"realname\" and
returning a check to see if the compatibility definition should
be installed).  ATTR is a plist used to modify the generated
code.  The following attributes are handled, all others are
ignored:

- :min-version :: Prevent the compatibility definition from begin
  installed in versions older than indicated (string).

- :max-version :: Prevent the compatibility definition from begin
  installed in versions newer than indicated (string).

- :feature :: The library the code is supposed to be loaded
  with (via `eval-after-load').

- :cond :: Only install the compatibility code, iff the value
  evaluates to non-nil.

  For prefixed functions, this can be interpreted as a test to
  `defalias' an existing definition or not.

- :no-highlight :: Do not highlight this definition as
  compatibility function.

- :version :: Manual specification of the version the compatee
  code was defined in (string).

- :realname :: Manual specification of a \"realname\" to use for
  the compatibility definition (symbol).

- :notes :: Additional notes that a developer using this
  compatibility function should keep in mind.

- :prefix :: Add a `compatold-' prefix to the name, and define the
  compatibility code unconditionally.

TYPE is used to set the symbol property `compatold-type' for NAME.")

(defun compatold--generate-default (name def-fn install-fn check-fn attr type)
  "Generate a leaner compatibility definition.
See `compatold-generate-function' for details on the arguments NAME,
DEF-FN, INSTALL-FN, CHECK-FN, ATTR and TYPE."
  (let* ((min-version (plist-get attr :min-version))
         (max-version (plist-get attr :max-version))
         (feature (plist-get attr :feature))
         (cond (plist-get attr :cond))
         (version (or (plist-get attr :version)
                      compatold--current-version))
         (realname (or (plist-get attr :realname)
                       (intern (format "compatold--%S" name))))
         (check (cond
                 ((or (and min-version
                           (version< emacs-version min-version))
                      (and max-version
                           (version< max-version emacs-version)))
                  nil)
                 ((plist-get attr :prefix)
                  '(progn))
                 ((and version (version<= version emacs-version) (not cond))
                  nil)
                 (`(when (and ,(if cond cond t)
                              ,(funcall check-fn)))))))
    (when (eq name realname)
      (error "%S: Name is equal to realname" name))
    (cond
     ((and (plist-get attr :prefix) (memq type '(func macro))
           (string-match "\\`compatold-\\(.+\\)\\'" (symbol-name name))
           (let* ((actual-name (intern (match-string 1 (symbol-name name))))
                  (body (funcall install-fn actual-name version)))
             (when (and (version<= version emacs-version)
                        (fboundp actual-name)
                        check)
               `(,@check
                 ,(if feature
                      ;; See https://nullprogram.com/blog/2018/02/22/:
                      `(eval-after-load ,feature `(funcall ',(lambda () ,body)))
                    body))))))
     ((plist-get attr :realname)
      `(progn
         ,(funcall def-fn realname version)
         ,(and check
               `(,@check
                 ,(let ((body (funcall install-fn realname version)))
                    (if feature
                        ;; See https://nullprogram.com/blog/2018/02/22/:
                        `(eval-after-load ,feature `(funcall ',(lambda () ,body)))
                      body))))))
     (check
      (let* ((body (if (eq type 'advice)
                       `(,@check
                         ,(funcall def-fn realname version)
                         ,(funcall install-fn realname version))
                     `(,@check ,(funcall def-fn name version)))))
        (if feature
            ;; See https://nullprogram.com/blog/2018/02/22/:
            `(eval-after-load ,feature `(funcall ',(lambda () ,body)))
          body))))))

(defun compatold--define-function (type name arglist docstring rest)
  "Generate compatibility code for a function NAME.
TYPE is one of `func', for functions and `macro' for macros, and
`advice' ARGLIST is passed on directly to the definition, and
DOCSTRING is prepended with a compatibility note.  REST contains
the remaining definition, that may begin with a property list of
attributes (see `compatold-generate-common')."
  (let ((oldname name) (body rest))
    (while (keywordp (car body))
      (setq body (cddr body)))
    ;; It might be possible to set these properties otherwise.  That
    ;; should be looked into and implemented if it is the case.
    (when (and (listp (car-safe body)) (eq (caar body) 'declare))
      (when (version<= emacs-version "25")
        (delq (assq 'side-effect-free (car body)) (car body))
        (delq (assq 'pure (car body)) (car body))))
    ;; Check if we want an explicitly prefixed function
    (when (plist-get rest :prefix)
      (setq name (intern (format "compatold-%s" name))))
    (funcall compatold--generate-function
     name
     (lambda (realname version)
       `(,(cond
           ((memq type '(func advice)) 'defun)
           ((eq type 'macro) 'defmacro)
           ((error "Unknown type")))
         ,realname ,arglist
         ;; Prepend compatibility notice to the actual
         ;; documentation string.
         ,(let ((type (cond
                       ((eq type 'func) "function")
                       ((eq type 'macro) "macro")
                       ((eq type 'advice) "advice")
                       ((error "Unknown type")))))
            (with-temp-buffer
              (insert docstring)
              (newline 2)
              (insert
               "[Compatibility "
               (if version
                   (format
                    "%s for `%S', defined in Emacs %s.  \
If this is not documented on your system, you can check \
`(compatold) Emacs %s' for more details."
                     type oldname version version)
                 (format
                  "code %s for `%S'"
                  type oldname))
               "]")
              (let ((fill-column 80))
                (fill-region (point-min) (point-max)))
              (buffer-string)))
         ;; Advice may use the implicit variable `oldfun', but
         ;; to avoid triggering the byte compiler, we make
         ;; sure the argument is used at least once.
         ,@(if (eq type 'advice)
               (cons '(ignore oldfun) body)
             body)))
     (lambda (realname _version)
       (cond
        ((memq type '(func macro))
         ;; Functions and macros are installed by
         ;; aliasing the name of the compatible
         ;; function to the name of the compatibility
         ;; function.
         `(defalias ',name #',realname))
        ((eq type 'advice)
         `(advice-add ',name :around #',realname))))
     (lambda ()
       (cond
        ((memq type '(func macro))
         `(not (fboundp ',name)))
        ((eq type 'advice) t)))
     rest type)))

(defmacro compatold-defun (name arglist docstring &rest rest)
  "Define NAME with arguments ARGLIST as a compatibility function.
The function must be documented in DOCSTRING.  REST may begin
with a plist, that is interpreted by the macro but not passed on
to the actual function.  See `compatold-generate-common' for a
listing of attributes.

The definition will only be installed, if the version this
function was defined in, as indicated by the `:version'
attribute, is greater than the current Emacs version."
  (declare (debug (&define name (&rest symbolp)
                           stringp
                           [&rest keywordp sexp]
                           def-body))
           (doc-string 3) (indent 2))
  (compatold--define-function 'func name arglist docstring rest))

(defmacro compatold-defmacro (name arglist docstring &rest rest)
  "Define NAME with arguments ARGLIST as a compatibility macro.
The macro must be documented in DOCSTRING.  REST may begin
with a plist, that is interpreted by this macro but not passed on
to the actual macro.  See `compatold-generate-common' for a
listing of attributes.

The definition will only be installed, if the version this
function was defined in, as indicated by the `:version'
attribute, is greater than the current Emacs version."
  (declare (debug compatold-defun) (doc-string 3) (indent 2))
  (compatold--define-function 'macro name arglist docstring rest))

(defmacro compatold-advise (name arglist docstring &rest rest)
  "Define NAME with arguments ARGLIST as a compatibility advice.
The advice function must be documented in DOCSTRING.  REST may
begin with a plist, that is interpreted by this macro but not
passed on to the actual advice function.  See
`compatold-generate-common' for a listing of attributes.  The advice
wraps the old definition, that is accessible via using the symbol
`oldfun'.

The advice will only be installed, if the version this function
was defined in, as indicated by the `:version' attribute, is
greater than the current Emacs version."
  (declare (debug compatold-defun) (doc-string 3) (indent 2))
  (compatold--define-function 'advice name (cons 'oldfun arglist) docstring rest))

(defmacro compatold-defvar (name initval docstring &rest attr)
  "Declare compatibility variable NAME with initial value INITVAL.
The obligatory documentation string DOCSTRING must be given.

The remaining arguments ATTR form a plist, modifying the
behaviour of this macro.  See `compatold-generate-common' for a
listing of attributes.  Furthermore, `compatold-defvar' also handles
the attribute `:local' that either makes the variable permanent
local with a value of `permanent' or just buffer local with any
non-nil value."
  (declare (debug (name form stringp [&rest keywordp sexp]))
           (doc-string 3) (indent 2))
  ;; Check if we want an explicitly prefixed function
  (let ((oldname name))
    (when (plist-get attr :prefix)
      (setq name (intern (format "compatold-%s" name))))
    (funcall compatold--generate-function
     name
     (lambda (realname version)
       (let ((localp (plist-get attr :local)))
         `(progn
            (,(if (plist-get attr :constant) 'defconst 'defvar)
             ,realname ,initval
             ;; Prepend compatibility notice to the actual
             ;; documentation string.
             ,(if version
                  (format
                   "[Compatibility variable for `%S', defined in Emacs %s]\n\n%s"
                   oldname version docstring)
                (format
                 "[Compatibility variable for `%S']\n\n%s"
                 oldname docstring)))
            ;; Make variable as local if necessary
            ,(cond
              ((eq localp 'permanent)
               `(put ',realname 'permanent-local t))
              (localp
               `(make-variable-buffer-local ',realname))))))
     (lambda (realname _version)
       `(defvaralias ',name ',realname))
     (lambda ()
       `(not (boundp ',name)))
     attr 'variable)))

(provide 'compatold-macs)
;;; compatold-macs.el ends here
