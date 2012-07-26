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
