(add-to-list 'load-path "~/.emacs.d/python-mode")
(setq py-install-directory "~/.emacs.d/python-mode")
(require 'python-mode)

;;; load pymacs
(require 'pymacs)
(autoload 'pymacs-apply "pymacs")
(autoload 'pymacs-call "pymacs")
(autoload 'pymacs-eval "pymacs" nil t)
(autoload 'pymacs-exec "pymacs" nil t)
(autoload 'pymacs-load "pymacs" nil t)

;;; configure ropemacs
(setq ropemacs-enable-shortcuts nil)
(setq ropemacs-enable-autoimport t)
;; Stops from erroring if there's a syntax err
;;(setq ropemacs-codeassist-maxfixes 3)
;; Configurations
(setq ropemacs-guess-project t)
(setq ropemacs-enable-autoimport t)
(setq ropemacs-autoimport-modules '("os" "shutil" "sys" "logging"
				      "django.*"))

(pymacs-load "ropemacs" "rope-")

;;; load nosetest support
(require 'nose)

;;; add flymake/pyflakes support
;; code checking via pyflakes+flymake
(when (load "flymake" t)
  (defun flymake-pyflakes-init ()
    (let* ((temp-file (flymake-init-create-temp-buffer-copy
                       'flymake-create-temp-inplace))
           (local-file (file-relative-name
                        temp-file
                        (file-name-directory buffer-file-name))))
      (list "pyflakes" (list local-file))))
 
  (add-to-list 'flymake-allowed-file-name-masks
               '("\\.py\\'" flymake-pyflakes-init)))
 
(add-hook 'find-file-hook 'flymake-find-file-hook)


;; Adding hook
;; automatically open a rope project if there is one
;; in the current or in the upper level directory
;; and add python specific key bindings
(add-hook 'python-mode-hook
          (lambda ()
            (cond ((file-exists-p ".ropeproject")
                   (rope-open-project default-directory))
                  ((file-exists-p "../.ropeproject")
                   (rope-open-project (concat default-directory "..")))
                  )
            (local-set-key  (kbd "C-c j") 'rope-jump-to-global)
            (local-set-key  (kbd "C-c g") 'rope-goto-definition)
            (local-set-key  (kbd "C-c i") 'rope-show-doc)
            (local-set-key (kbd "C-t a") 'nosetests-all)
            (local-set-key (kbd "C-t m") 'nosetests-module)
            (local-set-key (kbd "C-t o ") 'nosetests-one)
            )
          )
