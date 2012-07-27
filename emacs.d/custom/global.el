;;; global customizations

;; Don't show the startup screen
(setq inhibit-startup-message t)

;; "y or n" instead of "yes or no"
(fset 'yes-or-no-p 'y-or-n-p)

;; Highlight regions and add special behaviors to regions.
;; "C-h d transient" for more info
(setq transient-mark-mode t)

;; Display line and column numbers
(setq line-number-mode t)
(setq column-number-mode t)
(require 'linum)
(setq linum-format "%d ")
(linum-mode 1)
(global-linum-mode 1)

;;; auto follow symkinks
(setq vc-follow-symlinks t)

;; Small fringes
;;(set-fringe-mode '(1 . 1))

;; Explicitly show the end of a buffer
(set-default 'indicate-empty-lines t)

;; Prevent the annoying beep on errors
(setq visible-bell t)

;; Emacs gurus don't need no stinking scroll bars
(when (fboundp 'toggle-scroll-bar)
  (toggle-scroll-bar -1))

;; Make sure all backup files only live in one place
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))

;; Gotta see matching parens
(show-paren-mode t)

;; Don't truncate lines
(setq truncate-lines t)
(setq truncate-partial-width-windows nil)

;; For emacsclient
(server-start)

;; Trailing whitespace is unnecessary
(add-hook 'before-save-hook (lambda () (whitespace-cleanup)))

(setq-default ispell-program-name "aspell")
(setq ispell-list-command "list")
(setq ispell-extra-args '("--sug-mode=ultra"))

;;; use spaces instead of tabs
(setq-default indent-tabs-mode nil)
(setq default-tab-width 4)
