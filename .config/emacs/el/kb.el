;;; kb.el -*- lexical-binding: t -*-
;;; Commentary: ^^

;; i have tried evil and meow, unfortunately they
;; failed to satisfy me, did not taste like salad,
;; it wasn't the best memorable experience either.

;; i don't like it when things get out of scope and
;; try to be much more than a modal editing system,
;; haha they really remind me of emacs?

;; there is nothing special about kb.el, but having
;; the safety mode and insert mode should be enough
;; to fix this stupid editor.

(defun incremental-search ()
  (interactive)
  (if isearch-mode
      (isearch-repeat-forward)
    (isearch-forward)))

(defun kill-line-saw ()
  (interactive)
  (if (region-active-p)
      (kill-region (region-beginning) (region-end))
    (if (looking-at "^$")
        (kill-whole-line)
      (kill-line))))

(defun surround-region ()
  (interactive)
  (let* ((choice (read-char-exclusive
                  "() [] {} <> '' \"\" "))
         (pairs (pcase choice
                     (?\( "()")
                     (?\[ "[]")
                     (?\{ "{}")
                     (?\< "<>")
                     (?\' "''")
                     (?\" "\"\""))))
    (if (region-active-p)
        (progn
          (goto-char (region-end))
          (insert (substring pairs 1))
          (goto-char (region-beginning))
          (insert (substring pairs 0 1))
          (deactivate-mark))
      (insert pairs)
      (backward-char))))

;; unset defaults
(dolist (kb-df '("C-a" "C-b" "C-c" "C-d" "C-e" "C-f" "C-g"
                 "C-h" "C-k" "C-l" "C-n" "C-o" "C-p" "C-q"
                 "C-s" "C-t" "C-u" "C-v" "C-w" "C-y" "C-z"
                 "C-/" "C-?" "<C-next>" "<C-prior>"
                 "<C-SPC>" "<escape>" "\e"))

  (define-key global-map           (kbd kb-df) nil)
  (define-key minibuffer-local-map (kbd kb-df) nil))

;; modal editing base
(defvar edit-state 'NORMAL)
(defvar map-normal (make-sparse-keymap))
(defvar map-insert (make-sparse-keymap))

(defun switch-to-insert-mode ()
  (interactive)
  (if buffer-read-only
      (message "Error: buffer is read-only.")
    (use-local-map map-insert)
    (setq edit-state 'INSERT)
    (setq-local cursor-type 'hbar)))

(defun switch-to-normal-mode ()
  (interactive)
  (unless buffer-read-only
    (use-local-map map-normal)
    (setq edit-state 'NORMAL)
    (setq-local cursor-type 'box)))

(defun abort ()
  (interactive)
  (cond ((active-minibuffer-window) (abort-recursive-edit))
        ((bound-and-true-p multiple-cursors-mode) (mc/keyboard-quit))
        (t (switch-to-normal-mode)))
      (keyboard-quit))

(defun my-self-insert-command ()
  (interactive)
  (if (and (eq edit-state 'NORMAL)
           (not (minibufferp)))
      (message "🧸 Press 'a' to switch to insert mode.")
    (call-interactively #'self-insert-command)))

(add-hook 'after-change-major-mode-hook #'switch-to-normal-mode)
(global-set-key [remap self-insert-command] #'my-self-insert-command)

;; editor bindings
(defmacro kb (mode &rest bindings)
  `(dolist (binding ',bindings)
     (define-key (pcase ,mode
                    (:normal map-normal)
                    (:insert map-insert)
                    (:any    global-map))

       (kbd (car binding)) (cdr binding))))

(kb :normal
    ("a" . switch-to-insert-mode)
    ("w" . move-beginning-of-line)
    ("e" . move-end-of-line)
    ("g" . beginning-of-buffer)
    ("G" . end-of-buffer)
    ("D" . open-line)
    ("d" . kill-line-saw)
    ("V" . kill-ring-save)
    ("v" . set-mark-command))

(kb :any
    ("<tab>"     . abort)
    ("<escape>"  . abort)

    ("C-s"       . incremental-search)
    ("C-z"       . undo-only)
    ("C-S-z"     . undo-redo)
    ("C-S-v"     . clipboard-yank)

    ("C-c b"     . eww-back-url)
    ("C-c k"     . describe-key)
    ("C-x C-f"   . find-file)
    ("C-x b"     . ibuffer)
    ("C-x k"     . kill-buffer)
    ("C-x 0"     . delete-window)
    ("C-x 1"     . delete-other-windows)
    ("C-x 2"     . split-window-below)
    ("C-x 3"     . split-window-right)

    ("M-x"       . execute-extended-command)
    ("M-f"       . forward-word)
    ("M-b"       . backward-word)
    ("M-e"       . forward-sentence)
    ("M-a"       . backward-sentence)

    ("<M-up>"    . windmove-up)
    ("<M-down>"  . windmove-down)
    ("<M-left>"  . windmove-left)
    ("<M-right>" . windmove-right)
    ("<S-up>"    . shrink-window)
    ("<S-down>"  . enlarge-window)
    ("<S-left>"  . shrink-window-horizontally)
    ("<S-right>" . enlarge-window-horizontally)

    ("<M-home>"  . mc/edit-lines)
    ("<M-end>"   . mc/vertical-align-with-space)
    ("<M-prior>" . mc/unmark-previous-like-this)
    ("<M-next>"  . mc/unmark-next-like-this)
    ("<S-prior>" . mc/mark-previous-like-this)
    ("<S-next>"  . mc/mark-next-like-this))

(with-eval-after-load 'eww
  (kb :any
      ("C-h b" . eww-back-url)
      ("C-h r" . eww-reload)))
