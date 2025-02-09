;;; compatold-24.el --- Compatibility Layer for Emacs 24.4  -*- lexical-binding: t; -*-

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

;; Find here the functionality added in Emacs 24.4, needed by older
;; versions.
;;
;; Only load this library if you need to use one of the following
;; functions:
;;
;; - `compatold-='
;; - `compatold-<'
;; - `compatold->'
;; - `compatold-<='
;; - `compatold->='
;; - `split-string'.

;;; Code:

(eval-when-compile (load "compatold-macs.el" nil t t))

(compatold-declare-version "24.4")

;;;; Defined in data.c

(compatold-defun = (number-or-marker &rest numbers-or-markers)
  "Handle multiple arguments."
  :prefix t
  (catch 'fail
    (while numbers-or-markers
      (unless (= number-or-marker (car numbers-or-markers))
        (throw 'fail nil))
      (setq number-or-marker (pop numbers-or-markers)))
    t))

(compatold-defun < (number-or-marker &rest numbers-or-markers)
  "Handle multiple arguments."
  :prefix t
  (catch 'fail
    (while numbers-or-markers
      (unless (< number-or-marker (car numbers-or-markers))
        (throw 'fail nil))
      (setq number-or-marker (pop numbers-or-markers)))
    t))

(compatold-defun > (number-or-marker &rest numbers-or-markers)
  "Handle multiple arguments."
  :prefix t
  (catch 'fail
    (while numbers-or-markers
      (unless (> number-or-marker (car numbers-or-markers))
        (throw 'fail nil))
      (setq number-or-marker (pop numbers-or-markers)))
    t))

(compatold-defun <= (number-or-marker &rest numbers-or-markers)
  "Handle multiple arguments."
  :prefix t
  (catch 'fail
    (while numbers-or-markers
      (unless (<= number-or-marker (car numbers-or-markers))
        (throw 'fail nil))
      (setq number-or-marker (pop numbers-or-markers)))
    t))

(compatold-defun >= (number-or-marker &rest numbers-or-markers)
  "Handle multiple arguments."
  :prefix t
  (catch 'fail
    (while numbers-or-markers
      (unless (>= number-or-marker (pop numbers-or-markers))
        (throw 'fail nil)))
    t))

(compatold-defun bool-vector-exclusive-or (a b &optional c)
  "Return A ^ B, bitwise exclusive or.
If optional third argument C is given, store result into C.
A, B, and C must be bool vectors of the same length.
Return the destination vector if it changed or nil otherwise."
  (unless (bool-vector-p a)
    (signal 'wrong-type-argument (list 'bool-vector-p a)))
  (unless (bool-vector-p b)
    (signal 'wrong-type-argument (list 'bool-vector-p b)))
  (unless (or (null c) (bool-vector-p c))
    (signal 'wrong-type-argument (list 'bool-vector-p c)))
  (when (/= (length a) (length b))
    (signal 'wrong-length-argument (list (length a) (length b))))
  (let ((dest (or c (make-bool-vector (length a) nil))) changed)
    (when (/= (length a) (length dest))
      (signal 'wrong-length-argument (list (length a) (length dest))))
    (dotimes (i (length dest))
      (let ((val (not (eq (aref a i) (aref b i)))))
        (unless (eq val (aref dest i))
          (setq changed t))
        (aset dest i val)))
    (if c (and changed c) dest)))

(compatold-defun bool-vector-union (a b &optional c)
  "Return A | B, bitwise or.
If optional third argument C is given, store result into C.
A, B, and C must be bool vectors of the same length.
Return the destination vector if it changed or nil otherwise."
  (unless (bool-vector-p a)
    (signal 'wrong-type-argument (list 'bool-vector-p a)))
  (unless (bool-vector-p b)
    (signal 'wrong-type-argument (list 'bool-vector-p b)))
  (unless (or (null c) (bool-vector-p c))
    (signal 'wrong-type-argument (list 'bool-vector-p c)))
  (when (/= (length a) (length b))
    (signal 'wrong-length-argument (list (length a) (length b))))
  (let ((dest (or c (make-bool-vector (length a) nil))) changed)
    (when (/= (length a) (length dest))
      (signal 'wrong-length-argument (list (length a) (length dest))))
    (dotimes (i (length dest))
      (let ((val (or (aref a i) (aref b i))))
        (unless (eq val (aref dest i))
          (setq changed t))
        (aset dest i val)))
    (if c (and changed c) dest)))

(compatold-defun bool-vector-intersection (a b &optional c)
  "Return A & B, bitwise and.
If optional third argument C is given, store result into C.
A, B, and C must be bool vectors of the same length.
Return the destination vector if it changed or nil otherwise."
  (unless (bool-vector-p a)
    (signal 'wrong-type-argument (list 'bool-vector-p a)))
  (unless (bool-vector-p b)
    (signal 'wrong-type-argument (list 'bool-vector-p b)))
  (unless (or (null c) (bool-vector-p c))
    (signal 'wrong-type-argument (list 'bool-vector-p c)))
  (when (/= (length a) (length b))
    (signal 'wrong-length-argument (list (length a) (length b))))
  (let ((dest (or c (make-bool-vector (length a) nil))) changed)
    (when (/= (length a) (length dest))
      (signal 'wrong-length-argument (list (length a) (length dest))))
    (dotimes (i (length dest))
      (let ((val (and (aref a i) (aref b i))))
        (unless (eq val (aref dest i))
          (setq changed t))
        (aset dest i val)))
    (if c (and changed c) dest)))

(compatold-defun bool-vector-set-difference (a b &optional c)
  "Return A &~ B, set difference.
If optional third argument C is given, store result into C.
A, B, and C must be bool vectors of the same length.
Return the destination vector if it changed or nil otherwise."
  (unless (bool-vector-p a)
    (signal 'wrong-type-argument (list 'bool-vector-p a)))
  (unless (bool-vector-p b)
    (signal 'wrong-type-argument (list 'bool-vector-p b)))
  (unless (or (null c) (bool-vector-p c))
    (signal 'wrong-type-argument (list 'bool-vector-p c)))
  (when (/= (length a) (length b))
    (signal 'wrong-length-argument (list (length a) (length b))))
  (let ((dest (or c (make-bool-vector (length a) nil))) changed)
    (when (/= (length a) (length dest))
      (signal 'wrong-length-argument (list (length a) (length dest))))
    (dotimes (i (length dest))
      (let ((val (and (aref a i) (not (aref b i)))))
        (unless (eq val (aref dest i))
          (setq changed t))
        (aset dest i val)))
    (if c (and changed c) dest)))

(compatold-defun bool-vector-not (a &optional b)
  "Compute ~A, set complement.
If optional second argument B is given, store result into B.
A and B must be bool vectors of the same length.
Return the destination vector."
  (unless (bool-vector-p a)
    (signal 'wrong-type-argument (list 'bool-vector-p a)))
  (unless (or (null b) (bool-vector-p b))
    (signal 'wrong-type-argument (list 'bool-vector-p b)))
  (let ((dest (or b (make-bool-vector (length a) nil))))
    (when (/= (length a) (length dest))
      (signal 'wrong-length-argument (list (length a) (length dest))))
    (dotimes (i (length dest))
      (aset dest i (not (aref a i))))
    dest))

(compatold-defun bool-vector-subsetp (a b)
  "Return t if every t value in A is also t in B, nil otherwise.
A and B must be bool vectors of the same length."
  (unless (bool-vector-p a)
    (signal 'wrong-type-argument (list 'bool-vector-p a)))
  (unless (bool-vector-p b)
    (signal 'wrong-type-argument (list 'bool-vector-p b)))
  (when (/= (length a) (length b))
    (signal 'wrong-length-argument (list (length a) (length b))))
  (catch 'not-subset
    (dotimes (i (length a))
      (when (if (aref a i) (not (aref b i)) nil)
        (throw 'not-subset nil)))
    t))

(compatold-defun bool-vector-count-consecutive (a b i)
  "Count how many consecutive elements in A equal B starting at I.
A is a bool vector, B is t or nil, and I is an index into A."
  (unless (bool-vector-p a)
    (signal 'wrong-type-argument (list 'bool-vector-p a)))
  (setq b (and b t))                    ;normalise to nil or t
  (unless (< i (length a))
    (signal 'args-out-of-range (list a i)))
  (let ((len (length a)) (n i))
    (while (and (< i len) (eq (aref a i) b))
      (setq i (1+ i)))
    (- i n)))

(compatold-defun bool-vector-count-population (a)
  "Count how many elements in A are t.
A is a bool vector.  To count A's nil elements, subtract the
return value from A's length."
  (unless (bool-vector-p a)
    (signal 'wrong-type-argument (list 'bool-vector-p a)))
  (let ((n 0))
    (dotimes (i (length a))
      (when (aref a i)
        (setq n (1+ n))))
    n))

;;;; Defined in subr.el

;;* UNTESTED
(compatold-defmacro with-eval-after-load (file &rest body)
  "Execute BODY after FILE is loaded.
FILE is normally a feature name, but it can also be a file name,
in case that file does not provide any feature.  See `eval-after-load'
for more details about the different forms of FILE and their semantics."
  (declare (indent 1) (debug (form def-body)))
  ;; See https://nullprogram.com/blog/2018/02/22/ on how
  ;; `eval-after-load' is used to preserve compatibility with 24.3.
  `(eval-after-load ,file `(funcall ',,`(lambda () ,@body))))

(compatold-defun special-form-p (object)
  "Non-nil if and only if OBJECT is a special form."
  (if (and (symbolp object) (fboundp object))
      (setq object (condition-case nil
                       (indirect-function object)
                     (void-function nil))))
  (and (subrp object) (eq (cdr (subr-arity object)) 'unevalled)))

(compatold-defun macrop (object)
  "Non-nil if and only if OBJECT is a macro."
  (let ((def (condition-case nil
                 (indirect-function object)
               (void-function nil))))
    (when (consp def)
      (or (eq 'macro (car def))
          (and (autoloadp def) (memq (nth 4 def) '(macro t)))))))

(compatold-defun string-suffix-p (suffix string  &optional ignore-case)
  "Return non-nil if SUFFIX is a suffix of STRING.
If IGNORE-CASE is non-nil, the comparison is done without paying
attention to case differences."
  (let ((start-pos (- (length string) (length suffix))))
    (and (>= start-pos 0)
         (eq t (compare-strings suffix nil nil
                                string start-pos nil ignore-case)))))

(compatold-defun split-string (string &optional separators omit-nulls trim)
  "Extend `split-string' by a TRIM argument.
The remaining arguments STRING, SEPARATORS and OMIT-NULLS are
handled just as with `split-string'."
  :prefix t
  (let* ((token (split-string string separators omit-nulls))
         (trimmed (if trim
                      (mapcar
                       (lambda (token)
                         (when (string-match (concat "\\`" trim) token)
                           (setq token (substring token (match-end 0))))
                         (when (string-match (concat trim "\\'") token)
                           (setq token (substring token 0 (match-beginning 0))))
                         token)
                       token)
                    token)))
    (if omit-nulls (delete "" trimmed) trimmed)))

(compatold-defun delete-consecutive-dups (list &optional circular)
  "Destructively remove `equal' consecutive duplicates from LIST.
First and last elements are considered consecutive if CIRCULAR is
non-nil."
  (let ((tail list) last)
    (while (cdr tail)
      (if (equal (car tail) (cadr tail))
          (setcdr tail (cddr tail))
        (setq last tail
              tail (cdr tail))))
    (if (and circular
             last
             (equal (car tail) (car list)))
        (setcdr last nil)))
  list)

;;* UNTESTED
(compatold-defun define-error (name message &optional parent)
  "Define NAME as a new error signal.
MESSAGE is a string that will be output to the echo area if such an error
is signaled without being caught by a `condition-case'.
PARENT is either a signal or a list of signals from which it inherits.
Defaults to `error'."
  (unless parent (setq parent 'error))
  (let ((conditions
         (if (consp parent)
             (apply #'append
                    (mapcar (lambda (parent)
                              (cons parent
                                    (or (get parent 'error-conditions)
                                        (error "Unknown signal `%s'" parent))))
                            parent))
           (cons parent (get parent 'error-conditions)))))
    (put name 'error-conditions
         (delete-dups (copy-sequence (cons name conditions))))
    (when message (put name 'error-message message))))

;;;; Defined in minibuffer.el

;;* UNTESTED
(compatold-defun completion-table-with-cache (fun &optional ignore-case)
  "Create dynamic completion table from function FUN, with cache.
This is a wrapper for `completion-table-dynamic' that saves the last
argument-result pair from FUN, so that several lookups with the
same argument (or with an argument that starts with the first one)
only need to call FUN once.  This can be useful when FUN performs a
relatively slow operation, such as calling an external process.

When IGNORE-CASE is non-nil, FUN is expected to be case-insensitive."
  (let* (last-arg last-result
                  (new-fun
                   (lambda (arg)
                     (if (and last-arg (string-prefix-p last-arg arg ignore-case))
                         last-result
                       (prog1
                           (setq last-result (funcall fun arg))
                         (setq last-arg arg))))))
    (completion-table-dynamic new-fun)))

;;* UNTESTED
(compatold-defun completion-table-merge (&rest tables)
  "Create a completion table that collects completions from all TABLES."
  (lambda (string pred action)
    (cond
     ((null action)
      (let ((retvals (mapcar (lambda (table)
                               (try-completion string table pred))
                             tables)))
        (if (member string retvals)
            string
          (try-completion string
                          (mapcar (lambda (value)
                                    (if (eq value t) string value))
                                  (delq nil retvals))
                          pred))))
     ((eq action t)
      (apply #'append (mapcar (lambda (table)
                                (all-completions string table pred))
                              tables)))
     (t
      (completion--some (lambda (table)
                          (complete-with-action action table string pred))
                        tables)))))

;;;; Defined in subr-x.el

;;* UNTESTED

;; Don't complicate such a primitive function as `require', instead:
;;      (provide 'subr-x)
;; by the user anywhere is much simpler

;; (compatold-advise require (feature &rest args)
;;   "Allow for Emacs 24.3 to require the inexistent FEATURE subr-x."
;;   :version "24.4"
;;   ;; As the compatibility advise around `require` is more a hack than
;;   ;; of of actual value, the highlighting is suppressed.
;;   :no-highlight t
;;   (if (eq feature 'subr-x)
;;       (progn
;;         (unless (memq 'subr-x features)
;;           (push 'subr-x features)
;;           (dolist (a-l-element after-load-alist)
;;             (when (eq (car a-l-element) 'subr-x)
;;               (mapc #'eval (cdr a-l-element)))))
;;         'subr-x)
;;     (apply oldfun feature args)))

(compatold-defun hash-table-keys (hash-table)
  "Return a list of keys in HASH-TABLE."
  (let (values)
    (maphash
     (lambda (k _v) (push k values))
     hash-table)
    values))

(compatold-defun hash-table-values (hash-table)
  "Return a list of values in HASH-TABLE."
  (let (values)
    (maphash
     (lambda (_k v) (push v values))
     hash-table)
    values))

(compatold-defun string-empty-p (string)
  "Check whether STRING is empty."
  (string= string ""))

(compatold-defun string-join (strings &optional separator)
  "Join all STRINGS using SEPARATOR.
Optional argument SEPARATOR must be a string, a vector, or a list of
characters; nil stands for the empty string."
  (mapconcat #'identity strings separator))

(compatold-defun string-blank-p (string)
  "Check whether STRING is either empty or only whitespace.
The following characters count as whitespace here: space, tab, newline and
carriage return."
  (string-match-p "\\`[ \t\n\r]*\\'" string))

(compatold-defun string-remove-prefix (prefix string)
  "Remove PREFIX from STRING if present."
  (if (string-prefix-p prefix string)
      (substring string (length prefix))
    string))

(compatold-defun string-remove-suffix (suffix string)
  "Remove SUFFIX from STRING if present."
  (if (string-suffix-p suffix string)
      (substring string 0 (- (length string) (length suffix)))
    string))

;;;; Defined in faces.el

;;* UNTESTED
(compatold-defun face-spec-set (face spec &optional spec-type)
  "Set the FACE's spec SPEC, define FACE, and recalculate its attributes.
See `defface' for the format of SPEC.

The appearance of each face is controlled by its specs (set via
this function), and by the internal frame-specific face
attributes (set via `set-face-attribute').

This function also defines FACE as a valid face name if it is not
already one, and (re)calculates its attributes on existing
frames.

The optional argument SPEC-TYPE determines which spec to set:
  nil, omitted or `face-override-spec' means the override spec,
    which overrides all the other types of spec mentioned below
    (this is usually what you want if calling this function
    outside of Custom code);
  `customized-face' or `saved-face' means the customized spec or
    the saved custom spec;
  `face-defface-spec' means the default spec
    (usually set only via `defface');
  `reset' means to ignore SPEC, but clear the `customized-face'
    and `face-override-spec' specs;
Any other value means not to set any spec, but to run the
function for defining FACE and recalculating its attributes."
  (if (get face 'face-alias)
      (setq face (get face 'face-alias)))
  ;; Save SPEC to the relevant symbol property.
  (unless spec-type
    (setq spec-type 'face-override-spec))
  (if (memq spec-type '(face-defface-spec face-override-spec
                        customized-face saved-face))
      (put face spec-type spec))
  (if (memq spec-type '(reset saved-face))
      (put face 'customized-face nil))
  ;; Setting the face spec via Custom empties out any override spec,
  ;; similar to how setting a variable via Custom changes its values.
  (if (memq spec-type '(customized-face saved-face reset))
      (put face 'face-override-spec nil))
  ;; If we reset the face based on its custom spec, it is unmodified
  ;; as far as Custom is concerned.
  (unless (eq face 'face-override-spec)
    (put face 'face-modified nil))
  ;; Initialize the face if it does not exist, then recalculate.
  (make-empty-face face)
  (dolist (frame (frame-list))
    (face-spec-recalc face frame)))

(provide 'compatold-24)
;;; compatold-24.el ends here
