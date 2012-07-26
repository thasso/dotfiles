(defun pm-init-keyboard ()
  (local-set-key  (kbd "C-c j") 'rope-jump-to-global)
  (local-set-key  (kbd "C-c g") 'rope-goto-definition)
  (local-set-key  (kbd "C-c i") 'rope-show-doc)
  (local-set-key (kbd "C-t a") 'nosetests-all)
  (local-set-key (kbd "C-t m") 'nosetests-module)
  (local-set-key (kbd "C-t o ") 'nosetests-one)
)

(defun pm-init-rope-loading ()
  (cond ((file-exists-p ".ropeproject")
         (rope-open-project default-directory))
        ((file-exists-p "../.ropeproject")
         (rope-open-project (concat default-directory "..")))
        )
)

(defun pm-init-rope ()
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
)

(defun pm-init-flymake ()
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

)

(pm-init-rope)
(pm-init-rope-loading)
(require 'flymake)
(pm-init-flymake)
;; load rope and autocomplete support
(add-to-list 'ac-sources 'ac-source-ropemacs)
(require 'ac-python)
(ac-ropemacs-initialize)
(pm-init-keyboard)

(add-hook 'python-mode-hook
          (lambda ()
            (pm-init-rope)
            (pm-init-rope-loading)
            (require 'flymake)
            (pm-init-flymake)
            ;; load rope and autocomplete support
            (add-to-list 'ac-sources 'ac-source-ropemacs)
            (require 'ac-python)
            (ac-ropemacs-initialize)
            (pm-init-keyboard)
          )
)
