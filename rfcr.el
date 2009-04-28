;;; rfcr.el - Interface to RFC repository at www.ietf.org

;; Copyright (C) 2001 Sami Salkosuo
;; Author: Sami Salkosuo 
;; Version: 0.3 Thu Oct 18 08:50:35 2001

;; This file is not part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;; Commentary:
;;
;; This is EMACS interface to http://www.ietf.org/rfc.html RFC
;; repository.
;;
;; Installation:
;;
;; Add rfcr.el to your load path and add
;; (require 'rfcr)
;; to .emacs
;;
;; If using rfcr from behind proxy
;; (setq rfcr-proxy-host )
;; (setq rfcr-proxy-port )
;;
;; Usage:
;; 
;; M-x rfcr-index displays RFC index, if index is not 
;; saved in rfcr directory then it's loaded from the IETF.

;; M-x rfcr-index-reload gets RFC index from IETF and saves it
;; to rfcr directory.
;;
;; M-x rfcr-get gets specified RFC from IETF and saves it
;; to rfcr directory. 
;; 
;; M-x rfcr lists RFCs in rfcr directory. If used with
;; prefix lists RFCs in reverse order.
;;
;; CHANGES
;;
;; v. 0.3
;;  -added index button to local repository user interface
;;  -renamed rfcr-local to rfcr
;;  -fixed bug when viewing local repository containing RFC(s) < 1000
;;  -added get RFC field & button to local repository user interface
;;  -local repository user interface tweaks
;;
;; v. 0.2
;;  -changed function name rfcr-reload to rfcr-index-reload
;;  -added rfcr-local function
;;
(require 'widget)

(defvar rfcr-proxy-host nil
  "HTTP proxy host")

(defvar rfcr-proxy-port nil
  "HTTP proxy port")

(defvar rfcr-directory "~/.rfcr"
  "RFC directory")

(defvar rfcr-url "www.ietf.org/iesg/1rfc_index.txt"
  "RFC index url")

(defvar rfcr-local-prefix nil
  "")

(defvar	rfcr-get-widget nil
  "")

(defun rfcr-index ()
  "Shows stored RFC index."
  (interactive)
  (let (

	)
    (if (not (file-exists-p (concat rfcr-directory "/RFC-index.txt")))
	(progn
	  (rfcr-index-reload)
	  )
      (progn
	(find-file (concat rfcr-directory "/RFC-index.txt"))
	(setq buffer-read-only t)
	)
      )

    )
  )

(defun rfcr-index-reload ()
  "Loads RFC index from http://www.ietf.org/iesg/1rfc_index.txt and saves it to rfcr directory"
  (interactive)
  (let (
	(host)
	(port 80)
	(buffer)
	(tcp-connection)
	(request)
	(rfcr-url "www.ietf.org/iesg/1rfc_index.txt")
	(rfcr-host "www.ietf.org")
	(rfcr-file "/iesg/1rfc_index.txt")
	)
    ;;set proxy if needed
    (if rfcr-proxy-host
	(progn
	  (setq file (concat "http://" rfcr-url))
	  (setq host rfcr-proxy-host)
	  (setq port rfcr-proxy-port)
	  )
      (progn
	(setq host rfcr-host)
	(setq file rfcr-file)
	)
      )
    (setq buffer (get-buffer-create "*RFC Index*"))
    (set-buffer buffer)
    (erase-buffer)
    (goto-char 0)

    (setq tcp-connection
	  (open-network-stream
	   "GET process-name"
	   buffer
	   host
	   port
	   ))

    (set-marker (process-mark tcp-connection) (point-min))
    (set-process-sentinel tcp-connection 'rfcr-sentinel)
    
    (setq request (concat "GET " file " HTTP/1.0\n\n"))
    (process-send-string tcp-connection request)
    (rfcr-parse tcp-connection)
    (delete-process tcp-connection)
    (switch-to-buffer buffer)
    (if (not (file-exists-p rfcr-directory))
	(make-directory rfcr-directory)
      )
    (write-file (concat rfcr-directory "/RFC-index.txt"))
    (setq buffer-read-only t)
    )
  )

(defun rfcr-parse (process)
  ""
  (let (
	(buffer)
	(header-end)
	(msg)
	(i)
	)
    (setq i 0)
    (while (eq (process-status process) 'open)
      (sit-for 0 200)
      (setq msg (concat "Downloading RFC index" (make-string i ?. )))
      (if (>= (length msg) (frame-width))
	  (progn
	    (setq i 0)
	    (setq msg (concat "Downloading RFC index" (make-string i ?. )))
	    )
	)
      (message msg)
      (setq i (1+ i))
      )
    (setq buffer (get-buffer-create "*RFC Index*"))
    (goto-char 0)
    (setq header-end (re-search-forward "\n\n" nil t))
    (delete-region 1 header-end)
    (setq header-end (re-search-forward "~$" nil t))
    (delete-region 1 (+ 2 header-end))
    )
  )

(defun rfcr-sentinel (process string)
  "Process the results from the efine network connection.
process - The process object that is being notified.
string - The string that describes the notification."
  )

(defun rfcr-get (rfc-number)
  "Gets specified RFC. Uses: http://www.ietf.org/rfc/rfcNNNN.txt"
  (interactive "nRFC number (nnnn): ")
  (let (
	(host)
	(port 80)
	(buffer)
	(buffer-name)
	(tcp-connection)
	(request)
	(rfc-url "www.ietf.org/rfc/rfc")
	(rfc-host "www.ietf.org")
	(rfc-file "rfc/rfc")
	)
    (setq rfc-number (number-to-string rfc-number ))
    (if (file-exists-p (concat rfcr-directory "/RFC" rfc-number ".txt"))
	(progn
	  (find-file (concat rfcr-directory "/RFC" rfc-number ".txt"))
	  (setq buffer-read-only t)
	  )
      (progn
      
	;;set proxy if needed
	(if rfcr-proxy-host
	    (progn
	      (setq file (concat "http://" rfc-url rfc-number ".txt"))
	      (setq host rfcr-proxy-host)
	      (setq port rfcr-proxy-port)
	      )
	  (progn
	    (setq host rfc-host)
	    (setq file (concat rfc-file rfc-number ".txt"))
	    )
	  )
	(setq buffer-name (concat "*RFC " rfc-number "*"))
	(setq buffer (get-buffer-create buffer-name))
	(set-buffer buffer)
	(erase-buffer)
	(goto-char 0)

	(setq tcp-connection
	      (open-network-stream
	       "GET process-name"
	       buffer
	       host
	       port
	       ))

	(set-marker (process-mark tcp-connection) (point-min))
	(set-process-sentinel tcp-connection 'rfcr-sentinel)
    
	(setq request (concat "GET " file " HTTP/1.0\n\n"))
	(process-send-string tcp-connection request)
	(rfcr-parse-rfc buffer-name tcp-connection rfc-number)
	(delete-process tcp-connection)
	(switch-to-buffer buffer)
	(if (not (file-exists-p rfcr-directory))
	    (make-directory rfcr-directory)
	  )
	(while (< (length rfc-number) 4)
	  (setq rfc-number (concat "0" rfc-number))
	  )
	(write-file (concat rfcr-directory "/RFC" rfc-number ".txt"))
	(setq buffer-read-only t)
	)
      )
    )
      
  )

(defun rfcr-parse-rfc (buffer-name process rfc-number)
  ""
  (let (
	(buffer)
	(header-end)
	(msg)
	(i 0)
	)
    (setq i 0)
    (while (eq (process-status process) 'open)
      (sit-for 0 200)
      (setq msg (concat "Downloading RFC" rfc-number (make-string i ?. )))
      (if (>= (length msg) (frame-width))
	  (progn
	    (setq i 0)
	    (setq msg (concat "Downloading RFC" rfc-number (make-string i ?. )))
	    )
	)
      (message msg)
      (setq i (1+ i))
      )
    (setq buffer (get-buffer-create buffer-name))
    (goto-char 0)
    ;;delete http headers
    (setq header-end (re-search-forward "\n\n" nil t))
    (delete-region 1 header-end)

    ;;delete empty lines
    (setq header-end  (re-search-forward "^[a-zA-Z0-9]" nil t))
    (delete-region 1 (1- header-end))

    )  
  )

(defun rfcr (arg &optional current-widget)
  "Local RFC repository. Lists files in rfcr directory.
   If used with prefix displays repositiroy newest rfc first."
  (interactive "P")
  (let (
	(buffer)
	(index-buffer)
	(rfc-files)
	(rfc-file)
	(rfc-number)
	(rfc-title)
	(index)
	
	)
    (if (null current-widget)
	(setq current-widget 1)
      )

    (if (bufferp (get-buffer "*Local RFC repository*"))
	(kill-buffer "*Local RFC repository*")
      )
    (if (not (file-exists-p (concat rfcr-directory "/RFC-index.txt")))
	(progn
	  (message "RFC index not found. Download RFC index with M-x rfcr-index.")
	  )
      (progn
	(setq buffer (get-buffer-create "*Local RFC repository*"))
	(setq rfcr-local-prefix arg)
	(setq index-buffer (get-buffer-create "*Local RFC repository TEMP*"))
	(set-buffer index-buffer)
	(insert-file-contents (concat rfcr-directory "/RFC-index.txt"))

	(set-buffer buffer)
	(widget-insert "Local RFC repository\n")
	(widget-create 'push-button	
			 :notify (lambda (&rest ignore)
				   (rfcr-index))
				   ;;(find-file (concat rfcr-directory "/RFC-index.txt")))
			 "RFC index")
	(widget-insert "\t")
	(widget-create 'push-button		   
		       :notify (lambda (&rest ignore)
				 (if rfcr-local-prefix
				     (rfcr t 2)
				   (rfcr nil 2))
				 )
		       "Refresh")    
	;;(widget-insert "\t")
 	(widget-insert "\n\nRFC: ")
 	(setq rfcr-get-widget (widget-create 'editable-field
 		       :size 4
		       :notify (lambda (widget &rest ignore)
				 (widget-setup)
				 (setq rfcr-get-widget widget)
				 ;(message (widget-value widget))
				   )
 		       ))
	(widget-insert "\t")
	(widget-create 'push-button	
			 :notify (lambda (&rest ignore)
				   (rfcr-get (string-to-number (widget-value rfcr-get-widget)))
				   ;;(message  (concat "Value: " (widget-value rfcr-get-widget)))
				   )
			 "Get")
	(widget-insert "\n\n")	
	(widget-create 'push-button		   
		       :notify (lambda (&rest ignore)
				 (if rfcr-local-prefix
				     (rfcr (not t) 5)
				   (rfcr (not nil) 5))
				 )
		       "Reverse list")
	(widget-insert "\n")	
	(setq rfc-files (directory-files rfcr-directory nil "RFC[0-9]+\\.txt\\'"))
	(if rfcr-local-prefix
	    (setq rfc-files (reverse rfc-files))
	  )
	(while rfc-files
	  (setq rfc-file (car rfc-files))
	  (setq rfc-number (substring rfc-file 3 (string-match "\\." rfc-file)))
	  (widget-create 'push-button
			 :value rfc-number
			 :notify (lambda (widget &rest ignore)
				   (find-file (concat rfcr-directory "/RFC" (widget-value widget) ".txt")))
			 rfc-number)
	  ;;get rfc title
	  (set-buffer index-buffer)
	  (goto-char 0)
	  (setq index (re-search-forward (concat "^" rfc-number ) nil t))
	  (setq rfc-title (buffer-substring index (re-search-forward "\\. " nil t)))
	  (set-buffer buffer)
	  (widget-insert "\t" rfc-title "\n")
	  (setq rfc-files (cdr rfc-files))
	  )
	(widget-minor-mode 1)
	(widget-setup)
	(goto-char 0)
	(widget-forward current-widget)
	(kill-buffer index-buffer)
	(switch-to-buffer buffer)
	)
      )
    )
  )

(provide 'rfcr)
