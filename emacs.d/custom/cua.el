;;; CUA cut/copy/paste and other defaults
(cua-mode t)
;;; workaround to get shif up selection working
(if (equal "xterm" (tty-type))
      (define-key input-decode-map "\e[1;2A" [S-up]))
(defadvice terminal-init-xterm (after select-shift-up activate)
      (define-key input-decode-map "\e[1;2A" [S-up]))
;;; enable cua rectangle selection on
(global-set-key (kbd "C-c r") 'cua-set-rectangle-mark)

;; disable cua keys in graphical mode on os x, here we can use the command keys

(defun system-type-is-darwin ()
  (interactive)
  "Return true if system is darwin-based (Mac OS X)"
  (string-equal system-type "darwin")
)
(when (system-type-is-darwin) (when (display-graphic-p)
                                 (progn
                                   (global-set-key (kbd "C-Z") nil)
                                   (setq cua-enable-cua-keys nil)
                                   )))
