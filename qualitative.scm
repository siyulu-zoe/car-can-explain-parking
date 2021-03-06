;;; ----------------------------------------------------------------------
;;; Copyright 2016 Leilani H Gilpin, Ben Z Yuan and Gerald Jay Sussuman 
;;; ----------------------------------------------------------------------
;;; This file is part of Artistic Propagator Prototype.
;;; 
;;; Artistic Propagator Prototype is free software; you can
;;; redistribute it and/or modify it under the terms of the GNU
;;; General Public License as published by the Free Software
;;; Foundation, either version 3 of the License, or (at your option)
;;; any later version.
;;; 
;;; Artistic Propagator Prototype is distributed in the hope that it
;;; will be useful, but WITHOUT ANY WARRANTY; without even the implied
;;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;;; See the GNU General Public License for more details.
;;; 
;;; You should have received a copy of the GNU General Public License
;;; along with Artistic Propagator Prototype.  If not, see
;;; <http://www.gnu.org/licenses/>.
;;; ----------------------------------------------------------------------

;;; This is a qualitative structure with 4 values: 
;;;   increasing ('inc), decreasing ('dec), no change/zero ('0) and 
;;;   unknown change ('?)
;;; Currently only the following basic generic operations are supported:
;;; adding, subtracting, multiplication, division.

(define-structure
  (qualitative
   (type vector) (named 'qualitative) (print-procedure #f))
  description)
;  magnitude)

(define qualitative-equal? equal?)

(define (pp-qualitative qual)
  (if (not (qualitative? qual)) 
      (display "cannot display value for non-qualitative value")
      (cond ((isUnknown? qual) (display "unknown change"))
	    ((isIncreasing? qual) (display "increasing change"))
	    ((isDecreasing? qual) (display "decreasing change"))
	    (else (display "no change")))))

(define (->qualitative x)
  (if (qualitative? x)
      x
      (make-qualitative x)))

(define (isUnknown? qual)
  (if (eqv? (qualitative-description qual) '?) 
      #t 
      #f))

(define (isIncreasing? qual)
  (if (eqv? (qualitative-description qual) 'inc) 
      #t 
      #f))

(define (isDecreasing? qual)
  (if (eqv? (qualitative-description qual) 'dec) 
      #t 
      #f))

(define (isZero? qual)
  (if (eqv? (qualitative-description qual) '0) 
      #t 
      #f))

(define (add-qualitative x y)
  (let ((x-description (qualitative-description x))
	(y-description (qualitative-description y)))
    (cond ((equal? x-description y-description)
	   (make-qualitative x-description))
	  ((or (equal? x-description '?) 
	       (equal? y-description '?)) 
	   (make-qualitative '?))
	  ((equal? x-description '0) 
	   (make-qualitative y-description))
	  ((equal? y-description '0) 
	   (make-qualitative x-description))
	  (else (make-qualitative '?)))))

; This may not be the correct logic
(define (sub-qualitative x y)
  (add-qualitative x (negate-qualitative y)))

;; Very similar to addition
(define (mul-qualitative x y)
  (add-qualitative x y))

; LG - I don't think we will need this
#|
(define (empty-qualitative? x)
  (if (
  (> (qualitative-low x) (qualitative-high x)))
|#

;;; Might need some type of identity function

(define (negate-qualitative x)
  (let ((desc (qualitative-description x)))
    (cond ((equal? desc 'inc) (make-qualitative 'dec))
	  ((equal? desc 'dec) (make-qualitative 'inc))
	  (else (make-qualitative '?))))) ; unsure if correct

;; This may need to be changes
;; The logic is that a positive number corresponds to a positive
;; change, and a negative number corresponds to a decreasing change
;; If the number is 0, you return the qual...
(define (add-qualitative-number qual num)
  qual)

(define (multiply-qualitative-number qual num)
  (cond ((> num 0)
	 (mul-qualitative qual (make-qualitative 'inc)))
	((eqv? 0 num) qual)
	(else
	 (mul-qualitative qual (make-qualitative 'dec)))))


(assign-operation '+ add-qualitative qualitative? qualitative?)
(assign-operation '+ add-qualitative-number qualitative? number?)
(assign-operation '+ (reverse-args add-qualitative-number) number? qualitative?)

(assign-operation '- sub-qualitative qualitative? qualitative?)
(assign-operation '- (coercing ->qualitative sub-qualitative) number? qualitative?)
(assign-operation '- (coercing ->qualitative sub-qualitative) qualitative? number?)

(assign-operation '* mul-qualitative qualitative? qualitative?)
(assign-operation '* multiply-qualitative-number number? qualitative?)
(assign-operation '* (reverse-args multiply-qualitative-number) qualitative? number?)
(assign-operation 'not negate-qualitative qualitative?)

(assign-operation 'pp pp-qualitative qualitative?)

;; Right now, this is just an add
(define (merge-qualitatives content increment)
  (add-qualitative content increment))

(define (merge-qualitative-number qual number)
  number)

(assign-operation 'merge merge-qualitatives qualitative? qualitative?)
(assign-operation 'merge merge-qualitative-number qualitative? number?)
(assign-operation 'merge (reverse-args merge-qualitative-number) 
		  number? qualitative?)

;; I think qualtitative description is defined
(define (equivalent-qualitatives? i1 i2)
  (eqv? (qualitative-description il)
		       (qualitative-description i2)))

(assign-operation 'equivalent? equivalent-qualitatives? qualitative? qualitative?)
(assign-operation 'equivalent? (coercing ->qualitative equivalent-qualitatives?) 
		  number? qualitative?)
(assign-operation 'equivalent? (coercing ->qualitative equivalent-qualitatives?) 
		  qualitative? number?)

