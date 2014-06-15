;;;		-*- Mode: Emacs-Lisp; coding: utf-8; indent-tabs-mode: nil -*-
;;;
;;;	まず最初に、system-name を FQDN ではなく short name にする
;;;	(frame title に FQDN が表示されなくする)
;;;
;;;	The symbol system-name is a variable as well as a function.
;;;	In fact, the function returns whatever value the variable
;;;	system-name currently holds. Thus, you can set the variable
;;;	system-name in case Emacs is confused about the name of your
;;;	system. The variable is also useful for constructing frame
;;;	titles (see Frame Titles). 
;;;
(setq system-name (car (split-string system-name "\\.")))


;;;
;;;	site-lisp とそのサブディレクトリを load-path に加える
;;;
(let ((dir "/usr/local/share/emacs/site-lisp"))
  (when (and
         (not (member dir load-path))
         (file-accessible-directory-p dir))
    (add-to-list 'load-path dir)
    (let ((default-directory dir))
      (normal-top-level-add-subdirs-to-load-path))))


;;;
;;;	$HOME/sys/local/share/emacs/site-lisp があれば load-path に加える
;;;
(let ((dir (expand-file-name "~/sys/local/share/emacs/site-lisp")))
  (when (and
         (not (member dir load-path))
         (file-accessible-directory-p dir))
    (add-to-list 'load-path dir)
    (let ((default-directory dir))
      (normal-top-level-add-subdirs-to-load-path))))


;;;
;;;	与えられたリストから basename が一致するディレクトリのリストを返す
;;;
(defun basename-match (basename directory-path)
  (let ((list nil))
    (dolist (path directory-path)
      (setq dir (car (last (split-string path "/"))))
      (cond ((and (string= basename dir)
                  (file-accessible-directory-p path))
             (add-to-list 'list path t nil))))
    (eval 'list)))


;;;
;;;
;;;	GNU Emacs 24.x 用各種設定
;;;
(load-file "~/.elisp/ja-env.el")
(load-file "~/.elisp/keybind.el")
(cond ((basename-match "wnn7" load-path)
       (load-file "~/.elisp/wnn7-egg.el")))
(cond (window-system
       (load-file "~/.elisp/x-client.el")))
(load-file "~/.elisp/highlight.el")
(load-file "~/.elisp/text-mode.el")
(load-file "~/.elisp/shell-mode.el")
(load-file "~/.elisp/cc-mode.el")
(load-file "~/.elisp/misc.el")


;;; EOF
