(ido-mode t)
(require 'mouse)
(xterm-mouse-mode t)
(defun track-mouse (e)) 
(setq mouse-sel-mode t)

(add-to-list 'load-path "~/.emacs.d/magit")
(require 'magit)
  