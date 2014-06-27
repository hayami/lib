;;;		-*- Mode: Emacs-Lisp; coding: utf-8; indent-tabs-mode: nil -*-
;;;
;;; cc-mode.el

;;;
;;; CC Mode
;;; For editing files containing C, C++,
;;; Objective-C, Java, and CORBA IDL code.
;;;
(add-hook 'c-mode-common-hook
          '(lambda ()
             (c-set-style "linux")
             (setq c-basic-offset 4)))

;;; cc-mode.el ends here
