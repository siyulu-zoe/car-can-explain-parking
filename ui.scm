;;; ----------------------------------------------------------------------
;;; Copyright 2016 Alexey Radul and Gerald Jay Sussman
;;; ----------------------------------------------------------------------
;;; This file is part of New Propagator Prototype.  It is derived from
;;; the Artistic Propagator Prototype previously developed by Alexey
;;; Radul and Gerald Jay Sussman.
;;; 
;;; New Propagator Prototype is free software; you can redistribute it
;;; and/or modify it under the terms of the GNU General Public License
;;; as published by the Free Software Foundation, either version 3 of
;;; the License, or (at your option) any later version.
;;; 
;;; New Propagator Prototype is distributed in the hope that it will
;;; be useful, but WITHOUT ANY WARRANTY; without even the implied
;;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;;; See the GNU General Public License for more details.
;;; 
;;; You should have received a copy of the GNU General Public License
;;; along with New Artistic Propagator Prototype.  If not, see
;;; <http://www.gnu.org/licenses/>.
;;; ----------------------------------------------------------------------

;;; Some nice user interface code, to be improved.

(declare (usual-integrations make-cell cell?))


;;; This removes those annoying hash numbers after ;Value:
(set! repl:write-result-hash-numbers? #f)

;;; Make for nice transcripts.
(define (cpp x)
  (display "#;\n")
  (pp x))

;;; This is part of paranoid programming.
(define (assert p #!optional error-comment irritant)
  (if (not p)
      (begin
	(if (not (default-object? irritant))
	    (pp irritant))
	(error
	 (if (default-object? error-comment)
	     "Failed assertion"
	     error-comment)))))

;;; This is required because (run) returns old value if there is
;;; nothing to do.  This is a problem if a contradiction is resolved
;;; by a kick-out! with no propagation.

(define (tell! cell information . premises)
  (assert (cell? cell) "Can only tell something to a cell.")
  (for-each (lambda (p) (eq-put! p 'premise #t)) premises)
  (set! *last-value-of-run* 'done)
  (add-content cell
	       (make-tms
		(supported information premises)))
  (run))

(define (retract! premise)
  (set! *last-value-of-run* 'done)
  (assert (eq-get premise 'premise) "Not a premise")
  (kick-out! premise)
  (run))

(define (assert! premise)
  (set! *last-value-of-run* 'done)
  (assert (eq-get premise 'premise) "Not a premise")
  (bring-in! premise)
  (run))

(define (inquire cell)
  (assert (cell? cell) "Can only inquire of a cell.")
  (let ((v (run)))
    (if (not (eq? v 'done)) (write-line v)))
  (show-value cell (tms-query (->tms (content cell)))))

(define (show-value cell v&s)
  (if (nothing? v&s)
      `(,(nickname cell) (has-value ,v&s))
      `(,(nickname cell)
        (has-value ,(g:simplify (v&s-value v&s)))
        (because ,@(show-reasons (v&s-reasons v&s)))
        (depends-on ,@(map nickname (v&s-support v&s))))))

(define (show-reasons reasons)
  (filter (lambda (x) (not (null? x)))
	  (map name reasons)))

(define (explain cell)
  (assert (cell? cell) "Can only explain a cell.")
  (let ((mark (make-eq-hash-table)))
    (define (walk cell)
      (let ((seen (hash-table/get mark cell #f)))
	(if (not seen)
            (let ((val (tms-query (->tms (content cell)))))
              (hash-table/put! mark cell #t)
              (cons (show-value cell val)
                    (append-map
                     (lambda (reason)
		       (cond ((eq? reason *universal-ancestor*)
			      '())
			     ((propagator? reason)
			      (append-map walk
					  (propagator-inputs reason)))
			     (else
			      (list reason))))
                     (v&s-reasons val))))
            '())))
    (walk cell)))



