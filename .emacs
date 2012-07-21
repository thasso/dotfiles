;;; enable ido mode by default
(ido-mode t)

;;; color scheme
(add-to-list 'load-path "~/.emacs.d/colors")

;;; load commons
(add-to-list 'load-path "~/.emacs.d/commons")
(add-to-list 'custom-theme-load-path "~/.emacs.d/emacs-color-theme-solarized")

;;; Color scheme
(load-theme 'solarized-dark t)

;;; auto follow symkinks
(setq vc-follow-symlinks t)

;;; mouse selection
(require 'mouse)
(xterm-mouse-mode t)
(defun track-mouse (e)) 
(setq mouse-sel-mode t)

;;; CUA cut/copy/paste and other defaults
(require 'autopair)
(autopair-global-mode 1)
(cua-mode t)
;;; workaround to get shif up selection working
(if (equal "xterm" (tty-type))
      (define-key input-decode-map "\e[1;2A" [S-up]))
(defadvice terminal-init-xterm (after select-shift-up activate)
    (define-key input-decode-map "\e[1;2A" [S-up]))
(global-set-key (kbd "C-c r") 'cua-set-rectangle-mark)

;;; load magit
(add-to-list 'load-path "~/.emacs.d/magit")
(require 'magit)
(global-set-key (kbd "C-c g") 'magit-status)

;;; load python magic
(load-file "~/.emacs.d/emacs-python/epy-init.el")

;;; allow to switch between C source and header file
(add-hook 'c-mode-common-hook
  (lambda() 
    (local-set-key  (kbd "C-c o") 'ff-find-other-file)))
