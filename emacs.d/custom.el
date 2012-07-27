;;; load vendor dir
(add-to-list 'load-path "~/.emacs.d/vendor")

;;; custom custom file
(setq custom-file "~/.emacs.d/my-custom.el")
(load custom-file 'noerror)


;;; load custom things
(load "custom/theme")
(load "custom/fonts")
(load "custom/env")
(load "custom/global")
(load "custom/defuns")
(load "custom/ido")
(load "custom/ac-config")
(load "custom/mouse")
(load "custom/editing")
(load "custom/cua")
(load "custom/windows")
(load "custom/flymake")
(load "custom/utf8")
(load "custom/mac")
(load "custom/python-mode")

;;; vendor loads
(vendor 'magit 'magit-status)
(vendor 'autopair)
(vendor 'pbcopy)
(vendor 'expand-region)
(vendor 'helm)
(vendor 'pymacs)
(vendor 'python-mode 'python-mode)
(vendor 'nose)
(vendor 'ac-python)
