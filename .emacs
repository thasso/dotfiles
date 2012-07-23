;;; enable ido mode by default
(ido-mode t)
(setq ido-enable-flex-matching t)
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

;;; autopairing
(require 'autopair)
(autopair-global-mode 1)

;;; CUA cut/copy/paste and other defaults
(cua-mode t)
; workaround to get shif up selection working
(if (equal "xterm" (tty-type))
      (define-key input-decode-map "\e[1;2A" [S-up]))
(defadvice terminal-init-xterm (after select-shift-up activate)
    (define-key input-decode-map "\e[1;2A" [S-up]))
(global-set-key (kbd "C-c r") 'cua-set-rectangle-mark)
;;; add mac os x terminal clipboard support
(require 'pbcopy)
(turn-on-pbcopy)


;;; magit git support
(add-to-list 'load-path "~/.emacs.d/magit")
(require 'magit)
(global-set-key (kbd "C-c g") 'magit-status)

;;; load python magic
(load-file "~/.emacs.d/emacs-python/epy-init.el")

;;; allow to switch between C source and header file
(add-hook 'c-mode-common-hook
  (lambda() 
    (local-set-key  (kbd "C-c o") 'ff-find-other-file)))

;;; fix Iterm2 issue with meta arrow keys
;;; to enable window navigation
(add-hook 'term-setup-hook
  '(lambda ()
     (define-key function-key-map "\e[1;9A" [M-up])
     (define-key function-key-map "\e[1;9B" [M-down])
     (define-key function-key-map "\e[1;9C" [M-right])
     (define-key function-key-map "\e[1;9D" [M-left])))

;;; window navigation
(require 'windmove)
(windmove-default-keybindings 'meta)

