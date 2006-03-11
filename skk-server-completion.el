;;; skk-server-completion.el --- server completion $B$N%/%i%$%"%s%H(B
;;
;; Copyright (C) 2005 Fumihiko MACHIDA <machida@users.sourceforge.jp>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
;; 02110-1301, USA

;;; Commentary:

;; Server completion $B$KBP1~$7$?<-=q%5!<%P$rMQ$$8+=P$78l$+$i;O$^$kA4$F$N(B
;; $B8l6g$N8!:w$r9T$J$$$^$9!#(B

;; $B$3$N%W%m%0%i%`$O0J2<$N(B 2 $B$D$N5!G=$rDs6!$7$^$9!#(B
;;
;; * skk-look $B$NF|K\8lHG!#FI$_$N:G8e$K(B `~' $B$rIU$1$FJQ49$9$k$H!"$=$NFI$_$+(B
;;   $B$i;O$^$kA4$F$N8uJd$rI=<($7$^$9!#(B
;;
;; $BNc!'(B
;;
;; $B"&$^$A$@(B~
;; ==> "$B$^$A$@(B" "$BD.ED(B" "$B$^$A$@$($-(B" "$BD.ED1X(B" "$B$^$A$@$*$@$-$e$&(B" "$BD.ED>.ED5^(B" ..
;;
;; * skk-comp $B$G!"(Bserver completion $B$r;HMQ(B
;;
;; $BNc!'(B
;;
;; $B"&$^$A$@(B-!- $B$G(B Tab $B$r2!$9$H!""&$^$A$@$($-(B $B"*(B $B"&$^$A$@$*$@$-$e$&(B $B!D!D(B
;; $B$H$J$j$^$9!#(B

;; [$B@_DjJ}K!(B]
;;
;; .skk $B$K!"0J2<$rDI2C$7$^$9!#(B
;;
;; (add-to-list 'skk-search-prog-list
;;	     '(skk-server-completion-search) t)
;;
;; (add-to-list 'skk-completion-prog-list
;;	     '(skk-comp-by-server-completion) t)
;;
;; $B$^$?!"(B`~' $B$rIU$1$?JQ497k2L$r8D?M<-=q$K3X=,$7$F$7$^$&$N$r$d$a$k$?$a$K$O(B
;; $B0J2<$rDI2C$7$F$/$@$5$$!#(B
;;
;; (add-hook 'skk-search-excluding-word-pattern-function
;; 	  #'(lambda (kakutei-word)
;; 	      (eq (aref skk-henkan-key (1- (length skk-henkan-key)))
;; 		  skk-server-completion-search-char)))

;;; Code:

(require 'skk)
(require 'skk-comp)


;;;###autoload
(defun skk-server-completion-search ()
  "$B%5!<%P!<%3%s%W%j!<%7%g%s$r9T$$!"F@$i$l$?3F8+=P$7$G$5$i$K8!:w$9$k!#(B
$BAw$jM-$jJQ49$K$OHsBP1~!#(B"
  (when (and (eq (aref skk-henkan-key (1- (length skk-henkan-key)))
		 skk-server-completion-search-char)
	     (not (or skk-henkan-okurigana
		      skk-okuri-char)))
    ;; skk-search $B$G$O8+=P$7$,?t;z$r4^$`;~$N$_(B
    ;; skk-use-numeric-conversion $B$,(B t $B$J8F=P$7$r$9$k$,!"(B
    ;; $B0l1~$=$l$K0MB8$7$J$$$h$&$K$7$F$$$k!#(B
    (let* ((henkan-key (substring skk-henkan-key
				  0 (1- (length skk-henkan-key))))
	   (numericp (and skk-use-numeric-conversion
			  (save-match-data
			    (string-match "[0-9$B#0(B-$B#9(B]" henkan-key))))
	   (conv-key (and numericp
			  (skk-num-compute-henkan-key henkan-key)))
	   (key (or conv-key henkan-key))
	   midasi-list result-list kouho-list)
      (setq midasi-list (skk-server-completion-search-midasi key))
      (dolist (skk-henkan-key midasi-list)
	;; $B8+=P$7$KBP1~$7$?%(%s%H%j$,%5!<%P$KB8:_$9$k;v$rA0Ds$H$7$F$$$k!#(B
	;; $BIT@09g$,$"$C$F$b%(%i!<$K$O$J$i$J$$$,!"8+=P$7$@$1$,I=<($5$l$k;v$K$J$k$N$G(B
	;; $B8!:wBP>]<-=q$+$iD>@\Jd408uJd$r@8@.$7$F$$$J$$%5!<%P$G$O1?MQ$K5$$r$D$1$k;v!#(B
	(setq kouho-list (cons (if numericp
				   (concat henkan-key
					   (substring skk-henkan-key
						      (length key)))
				 skk-henkan-key)
			       (skk-search-server-1 nil nil))
	      result-list (nconc result-list kouho-list)))
      result-list)))

(defun skk-server-completion-search-midasi (key)
  "server completion $B$rMxMQ$7$F!"(Bkey $B$+$i;O$^$k$9$Y$F$N8+=P$78l$N%j%9%H$rJV5Q$9$k!#(B"
  (when (skk-server-live-p (skk-open-server))
    (with-current-buffer skkserv-working-buffer
      (let ((cont t)
	    (count 0))
	(erase-buffer)
	(process-send-string skkserv-process (concat "4" key " "))
	(while (and cont (skk-server-live-p))
	  (accept-process-output)
	  (setq count (1+ count))
	  (when (> (buffer-size) 0)
	    (if (eq (char-after 1) ?1)	;?1
		;; found key successfully, so check if a whole line
		;; is received.
		(when (eq (char-after (1- (point-max)))
			  ?\n)		;?\n
		  (setq cont nil))
	      ;; not found or error, so exit
	      (setq cont nil))))
	(goto-char (point-min))
	(when skk-server-report-response
	  (skk-message "%d $B2s(B SKK $B%5!<%P!<$N1~EzBT$A$r$7$^$7$?(B"
		       "Waited for server response %d times"
		       count))
	(when (eq (following-char) ?1)	;?1
	  (forward-char 2)
	  (car (skk-compute-henkan-lists nil)))))))

;;;###autoload
(defun skk-comp-by-server-completion ()
  ;; skk-comp-prefix $B$O;H$o$J$$$N$G!"(B
  ;; $BI,MW$J$i(B skk-comp-restrict-by-prefix() $B$rJ;MQ$9$k!#(B
  "Server completion $B$KBP1~$7$?(B SKK $B%5!<%P$rMxMQ$9$kJd40%W%m%0%i%`!#(B
`skk-completion-prog-list' $B$NMWAG$K;XDj$7$F;H$&!#(B"
  (let* ((numericp (and skk-use-numeric-conversion
			(save-match-data
			  (string-match "[0-9$B#0(B-$B#9(B]" skk-comp-key))))
	 (conv-key (and numericp
			(skk-num-compute-henkan-key skk-comp-key)))
	 (comp-key (or conv-key skk-comp-key))
	 word)
    (when skk-comp-first
      (setq skk-server-completion-words
	    (skk-server-completion-search-midasi comp-key))
      (when (string= comp-key
		     (car skk-server-completion-words))
	(pop skk-server-completion-words)))
    (setq word (pop skk-server-completion-words))
    (when word
      (if numericp
	  (concat skk-comp-key
		  (substring word (length comp-key)))
	word))))

(provide 'skk-server-completion)


;;; skk-server-completion.el ends here
