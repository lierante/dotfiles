;;; init.el -*- lexical-binding: t -*-
;;; Commentary: my lisp machine configuration.

(add-to-list 'package-archives '("elpa" . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(defmacro install-packages (&rest packages)
  `(progn
     ,@(mapcar (lambda (pkg)
                 (if (consp pkg)
                     `(use-package ,(car pkg) ,@(cdr pkg)
                        :ensure t))) packages)))
(install-packages
 (multiple-cursors)
 (fontawesome)
 (lua-mode)
 (rainbow-delimiters :hook (prog-mode . rainbow-delimiters-mode))
 (rainbow-mode       :hook ((css-mode
                             lua-mode
                             emacs-lisp-mode) . rainbow-mode))
 (smartparens        :hook ((prog-mode . smartparens-mode)
                            (lisp-mode . smartparens-strict-mode)))
 (undo-fu)
 (undo-fu-session    :after undo-fu
                     :config (undo-fu-session-global-mode)))

(defun reload ()
  (interactive)
  (let ((config-dir (expand-file-name "el/" user-emacs-directory)))
    (mapc (lambda (file)
            (let ((file-path (expand-file-name file config-dir)))
              (when (file-readable-p file-path)
                          (load-file file-path)))) '("fl.el"
                                                     "fm.el"
                                                     "kb.el")))) (reload)
(defun export ()
  (interactive)
  (if-let ((file buffer-file-name))
      (let* ((backup-dir  (expand-file-name "backups/" user-emacs-directory))
             (backup-name (read-string      "file-name: " (file-name-nondirectory file)))
             (backup-path (expand-file-name  backup-name backup-dir)))
        (make-directory backup-dir t)
        (copy-file file backup-path t)
        (message "file exported to %s" backup-path))
    (message "buffer is not associated with a file")))

(setq make-backup-files nil
      create-lockfiles nil
      auto-save-default nil
      auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))

(prefer-coding-system 'utf-8)

;; assign clipboard
(defun wl-copy (text)
  (let ((p (make-process :name "wl-copy"
                         :command '("wl-copy")
                         :connection-type 'pipe)))
    (process-send-string p text)
    (process-send-eof p)))
(setq interprogram-cut-function 'wl-copy)

;; editor greetings
(defun display-startup-echo-area-message ()
  (let ((user-name (getenv "USER")))
    (message "hi %s, happy hacking!" user-name)))

(defalias 'yes-or-no-p 'y-or-n-p)

(setq inhibit-startup-screen t
      initial-buffer-choice nil
      confirm-kill-processes nil
      confirm-nonexistent-file-or-buffer nil)

;; line by line scrolling
(setq scroll-step 1
      scroll-margin 5
      scroll-conservatively 10
      scroll-preserve-screen-position t)

(setq default-frame-alist
      '((font . "Iosevka Comfy Medium 10")
        (tool-bar-lines . 0)
        (menu-bar-lines . 0)
        (left-fringe . 0)
        (right-fringe . 0)
        (internal-border-width . 25)
        (vertical-scroll-bars . nil)
        (window-divider-default-right-width . 4)
        (window-divider-default-places . right-only)))

(window-divider-mode 1)
(global-hl-line-mode 1)
(blink-cursor-mode 0)
(show-paren-mode 1)
(delete-selection-mode 1)

;; disable line wrap, prefer spaces over tabs
(setq-default truncate-lines t
              indent-tabs-mode nil)

;; remove dollar sign at the end of truncated lines
(set-display-table-slot standard-display-table 0 ?\ )
(setq tab-width 4)

;; trim trailing whitespaces on save
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; EWW EEEEEE!!!!!!!!!!!!!!!!!! THATS POOOOPP!!!
(defvar url-address
  '(("emacs"      . "http://web.archive.org/web/20070808235903/https://www.gnu.org/software/emacs/")
    ("emacs girl" . "https://4chanarchives.com/board/k/thread/29900098")
    ("g"          . "https://boards.4chan.org/g/")
    ("fa"         . "https://boards.4chan.org/fa/")
    ("his"        . "https://boards.4chan.org/his/")
    ("furret"     . "https://e621.net/posts?page=4&tags=ke_mo_suke")))

(defun docs()
  (interactive)
  (let ((buffer-name "*docs*"))
    (with-current-buffer (get-buffer-create buffer-name)
      (erase-buffer)
      (insert "\nyou're fucking gay \n\n")
      (let ((max-title-length (apply 'max (mapcar #'length
                                                  (mapcar #'car url-address)))))
        (dolist (item url-address)
          (let ((url-title (car item))
                (url       (cdr item)))
            (insert-button url-title 'action (lambda (_) (eww url)))
            (insert (make-string (- (+ 2 max-title-length)
                                    (length url-title)) ?\s))
            (insert (format "%s\n" url))
            (insert (make-string (window-width) ?-))
            (insert "\n")))))
    (switch-to-buffer buffer-name)))

;; my fudgee barr
(setq-default mode-line-format nil)

(defun fudgee-barr ()
  (dolist (window (window-list))
    (with-current-buffer (window-buffer window)
      (let* ((str-right (format "(%d, %d)    "
                                (line-number-at-pos)
                                (current-column)))

             (file-name (if (eq major-mode 'eww-mode)
                            (let ((url (plist-get eww-data :url)))
                               (if url (concat "URL: " url)
                                 "EWW"))
                            (file-name-nondirectory
                               (or buffer-file-name "Untitled"))))

             (str-left (format " %s [%s] (#%s) (%s%s%s)"
                               file-name
                               (if (boundp 'edit-state) edit-state "OTHERS")
                               (if vc-mode (substring vc-mode 5) "?")
                               (format-mode-line mode-name)
                               (if abbrev-mode " ABBREV" "")
                               (if eldoc-mode " ELDOC" "")))

             (fill-length (max 0 (- (window-width window)
                                    (length str-left)
                                    (length str-right) 0)))

             (face (if (eq window (selected-window))
                       'mode-line
                       'mode-line-inactive))

             (icon (if (eq window (selected-window))
                       (propertize "    " 'face 'icon-face)
                       (propertize "    " 'face 'icon-face-inactive)))

             (str-left-p  (propertize str-left 'face face))
             (str-right-p (propertize str-right 'face face))
             (str-cents-p (propertize (make-string fill-length ?\s) 'face face))
             (x (concat icon
                        str-left-p
                        str-cents-p
                        str-right-p)))
            (setq-local header-line-format x)))))

(add-hook 'window-configuration-change-hook 'fudgee-barr)
(add-hook 'post-command-hook 'fudgee-barr)
