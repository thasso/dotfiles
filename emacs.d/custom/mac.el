
;;; fix an issue with fn-left/right to start end line
(define-key global-map [home] 'beginning-of-line)
(define-key global-map [end] 'end-of-line)
(global-set-key [kp-delete]     'delete-char)	; in Carbon
(global-set-key [delete]        'delete-char)	; for X11

;; Hide the tool bar
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode 0))
