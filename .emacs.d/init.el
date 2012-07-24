;;; enable ido mode by default
(ido-mode t)
(setq ido-enable-flex-matching t)

;;; load commons
(add-to-list 'load-path "~/.emacs.d/commons")

;;; color scheme
(add-to-list 'custom-theme-load-path "~/.emacs.d/emacs-color-theme-solarized")
(load-theme 'solarized-dark t)

;;; auto follow symkinks
(setq vc-follow-symlinks t)

;;; mouse support
(require 'mouse)
(xterm-mouse-mode t)
(defun track-mouse (e)) 
(setq mouse-sel-mode t)
(defun up-slightly () (interactive) (scroll-up 1))
(defun down-slightly () (interactive) (scroll-down 1))
(global-set-key (kbd "<mouse-4>") 'down-slightly)
(global-set-key (kbd "<mouse-5>") 'up-slightly)

;;; autopairing
(require 'autopair)
(autopair-global-mode 1)

;;; show matching parenthesis
(show-paren-mode 1)

;;; auto indent
(global-set-key (kbd "RET") 'newline-and-indent)

;;; CUA cut/copy/paste and other defaults
(cua-mode t)
;;; workaround to get shif up selection working
(if (equal "xterm" (tty-type))
      (define-key input-decode-map "\e[1;2A" [S-up]))
(defadvice terminal-init-xterm (after select-shift-up activate)
    (define-key input-decode-map "\e[1;2A" [S-up]))
;;; enable cua rectangle selection on 
(global-set-key (kbd "C-c r") 'cua-set-rectangle-mark)
;;; add mac os x terminal clipboard support to copy selection
;;; to system clipboard
(require 'pbcopy)
(turn-on-pbcopy)

;;;;;;;;; Window navigation
;;; fix Iterm2 issue with meta arrow keys
;;; to enable window navigation
(add-hook 'term-setup-hook
  '(lambda ()
     (define-key function-key-map "\e[1;10A" [S-M-up])
     (define-key function-key-map "\e[1;10B" [S-M-down])
     (define-key function-key-map "\e[1;10C" [S-M-right])
     (define-key function-key-map "\e[1;10D" [S-M-left])

     (define-key function-key-map "\e[1;9A" [M-up])
     (define-key function-key-map "\e[1;9B" [M-down])
     (define-key function-key-map "\e[1;9C" [M-right])
     (define-key function-key-map "\e[1;9D" [M-left])))
(require 'windmove)
(windmove-default-keybindings 'meta)

;;; line numbers
(require 'linum)
(setq linum-format "%d ")
(linum-mode 1)
(global-linum-mode 1)

;;; use spaces instead of tabs
(setq-default indent-tabs-mode nil) 
(setq default-tab-width 4)

;;;;; auto complete mode
(add-to-list 'load-path "~/.emacs.d/auto-complete/")
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/auto-complete/ac-dict")
(setq ac-dwim t)
(setq ac-use-quick-help t)
(define-key ac-mode-map (kbd "M-TAB") 'auto-complete)
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
(add-to-list 'interpreter-mode-alist '("python" . python-mode))
(ac-config-default)
(global-auto-complete-mode t)

;;; yasnippets
(add-to-list 'load-path "~/.emacs.d/yasnippet")
(require 'yasnippet)
(yas/global-mode 1)

;;; move lines
; code copied from http://stackoverflow.com/questions/2423834/move-line-region-up-and-down-in-emacs
(defun move-text-internal (arg)
  (cond
   ((and mark-active transient-mark-mode)
    (if (> (point) (mark))
        (exchange-point-and-mark))
    (let ((column (current-column))
          (text (delete-and-extract-region (point) (mark))))
      (forward-line arg)
      (move-to-column column t)
      (set-mark (point))
      (insert text)
      (exchange-point-and-mark)
      (setq deactivate-mark nil)))
   (t
    (let ((column (current-column)))
      (beginning-of-line)
      (when (or (> arg 0) (not (bobp)))
        (forward-line)
        (when (or (< arg 0) (not (eobp)))
          (transpose-lines arg))
        (forward-line -1))
      (move-to-column column t)))))

(defun move-text-down (arg)
  "Move region (transient-mark-mode active) or current line
  arg lines down."
  (interactive "*p")
  (move-text-internal arg))

(defun move-text-up (arg)
  "Move region (transient-mark-mode active) or current line
  arg lines up."
  (interactive "*p")
  (move-text-internal (- arg)))

(global-set-key (kbd "S-M-<up>") 'move-text-up)
(global-set-key (kbd "S-M-<down>") 'move-text-down)

;;; magit support
(add-to-list 'load-path "~/.emacs.d/magit")
(require 'magit)
(global-set-key (kbd "C-c g") 'magit-status)
;;;;;;;;; load more customizations
;;; load pythin
(load-file "~/.emacs.d/custom-py.el")
;;; load c
(load-file "~/.emacs.d/custom-c.el")
