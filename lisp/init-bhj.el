(defun sanityinc/local-push-company-backend (backend)
  "Add BACKEND to a buffer-local version of `company-backends'."
  (make-local-variable 'company-backends)
  (push backend company-backends))

(after-load 'company
  (add-hook 'sh-mode-hook
            (lambda () (sanityinc/local-push-company-backend 'company-shell)))
  (add-hook 'c-mode-hook
            (lambda () (sanityinc/local-push-company-backend 'company-clang)))
  (add-hook 'c++-mode-hook
            (lambda () (sanityinc/local-push-company-backend 'company-clang))))

(defun bhj-point-visible-p ()
  "Return t if current char is visible."
  (eq nil (delete-if ; delete the nils
           #'listp
           (mapcar (lambda (overlay)
                     (overlay-get overlay 'invisible))
                   (overlays-at (point))))))

(defun bhj-next-visible-char ()
  "Return the next visible char starting from (point).
Returns (point) if current-char is visible."
  (save-excursion
    (while (and (not (bhj-point-visible-p))
                (not (= (point) (point-max))))
      (goto-char (next-overlay-change (point))))
    (point)))

(defun bhj-next-invisible-char ()
  "Return the next invisible char starting from (point).
Returns (point) if current-char is visible."
  (save-excursion
    (while (and (bhj-point-visible-p)
                (not (= (point) (point-max))))
      (goto-char (next-overlay-change (point))))
    (point)))
(defun fix-cjk-spaces ()
  "Fix cjk spaces."
  (interactive)
  (unless (or
           (eq major-mode 'org-mode)
           (eq major-mode 'fundamental-mode)
           (eq major-mode 'markdown-mode)
           (eq major-mode 'text-mode))
    (if (yes-or-no-p "Are you sure to fix cjk spaces in non-org mode?")
        (when (not (region-active-p))
          (push-mark (line-beginning-position) nil t)
          (goto-char (line-end-position)))
      (user-error "Be careful to use fix-cjk-spaces in non-org mode")))
  (catch 'single-char-done
    (let ((my-point (point))
          (current-line-num (line-number-at-pos))
          (is-eol (looking-at "$"))
          (my-start (point-min))
          (my-end (point-max)))
      (when (region-active-p) ; for changing 1 space
        (setq my-start (min (mark) (point))
              my-end (max (mark) (point)))
        (let ((region-text (buffer-substring-no-properties (mark) (point))))
          (cond
           ((string= region-text " ")
            (delete-region (mark) (point))
            (insert " ")
            (throw 'single-char-done nil))
           ((string= region-text " ")
            (delete-region (mark) (point))
            (insert " ")
            (throw 'single-char-done nil)))))

      (save-mark-and-excursion
        (save-restriction
          (if (buffer-narrowed-p)
              (save-restriction
                (narrow-to-region my-start my-end)
                (setq my-start (point-min)
                      my-end (point-max))
                (while (< my-start my-end)
                  (goto-char my-start)
                  (goto-char (bhj-next-visible-char))
                  (setq my-end (bhj-next-invisible-char))
                  (shell-command-on-region (point) my-end "fix-cjk-spaces" nil t)
                  (goto-char my-end)
                  (goto-char (bhj-next-visible-char))
                  (setq my-start (point)
                        my-end (point-max))))
            (shell-command-on-region my-start my-end "fix-cjk-spaces" nil t))
          ))
      (if is-eol
          (progn
            (goto-char (point-min))
            (forward-line (1- current-line-num))
            (goto-char (line-end-position)))
        (goto-char (min my-point (point-max)))))))

(defun bhj-quote-it ()
  "Quote it."
  (interactive)
  (when (region-active-p)
    (save-restriction
      (narrow-to-region (point) (mark))
      (goto-char (point-min))
      (insert "「")
      (goto-char (point-max))
      (search-backward-regexp "[^ \n]")
      (forward-char)
      (insert "」\n--------------------------------\n"))))

(defmacro fix-Ctrl+cCtrl+k (package &optional package-map)
  `(use-package ,package
     :config
     (define-key
       (or ,package-map
           (symbol-value
            (intern
             (concat
              (symbol-name (quote ,package))
              (if (string-match "-mode$" (symbol-name (quote ,package)))
                  "-map"
                "-mode-map")))))
       (kbd "C-c C-k") nil)))

(fix-Ctrl+cCtrl+k cperl-mode)
(fix-Ctrl+cCtrl+k fence-edit)
(fix-Ctrl+cCtrl+k markdown-mode)
(fix-Ctrl+cCtrl+k json-mode)
(fix-Ctrl+cCtrl+k cc-mode c-mode-base-map)
(fix-Ctrl+cCtrl+k edit-indirect)
(fix-Ctrl+cCtrl+k tex-mode latex-mode-map)

(use-package fence-edit
  :config
  (define-key fence-edit-mode-map (kbd "C-x #") 'fence-edit-exit))

(use-package edit-indirect
  :config
  (define-key edit-indirect-mode-map (kbd "C-x #") #'edit-indirect-commit))

(use-package erc
  :config
  (require 'socks)
  (setq erc-server-connect-function 'socks-open-network-stream))

(define-key global-map (kbd "s-SPC") #'fix-cjk-spaces)
(define-key global-map (kbd "C-x n N") (lambda () (interactive) (when (looking-at-p "\\s ")
                                                                  (search-forward-regexp "\\sw")
                                                                  (beginning-of-line))
                                         (narrow-to-region (point) (point-max))))
(define-key global-map (kbd "<s-down>") #'next-error)
(define-key global-map (kbd "<s-up>") #'previous-error)
(define-key global-map (kbd "<s-left>") #'ajoke-pop-mark)
(define-key global-map (kbd "<s-right>") #'ajoke-pop-mark-back)
(define-key global-map (kbd "<M-left>") #'ajoke-pop-mark)
(define-key global-map (kbd "<M-right>") #'ajoke-pop-mark-back)

(provide 'init-bhj)
