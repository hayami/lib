;;;		-*- Mode: Emacs-Lisp; coding: utf-8; indent-tabs-mode: nil -*-
;;;
;;; text-mode.el

;;;
;;; Text Mode
;;;
(add-hook 'text-mode-hook
          '(lambda ()
             (auto-fill-mode 1)
             (setq fill-column 67)
             (setq kinsoku-nobashi-limit 2)))

;;; 機種依存文字モード
;(require 'izonmoji-mode)
;(add-hook 'text-mode-hook 'izonmoji-mode-on)

;;; text-mode.el ends here
