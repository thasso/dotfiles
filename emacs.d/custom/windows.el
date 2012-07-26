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
