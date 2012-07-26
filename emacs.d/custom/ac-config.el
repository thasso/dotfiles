;;; load auto complete configuration
(add-to-list 'load-path "~/.emacs.d/vendor/auto-complete")

(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/vendor/auto-complete/ac-dict")
(setq ac-dwim t)
(setq ac-use-quick-help t)
(define-key ac-mode-map (kbd "M-TAB") 'auto-complete)
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
(add-to-list 'interpreter-mode-alist '("python" . python-mode))
(ac-config-default)
(global-auto-complete-mode t)
