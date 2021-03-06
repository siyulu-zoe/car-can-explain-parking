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

;;; Interval code that is necessary to run examples,
(define-structure
  (interval
   (type list) (named 'interval) (print-procedure #f))
  low high)

(define (->interval x)
  (if (interval? x)
      x
      (make-interval x x)))

(define (add-interval x y)
  (make-interval (+ (interval-low x) (interval-low y))
		 (+ (interval-high x) (interval-high y))))

(define (sub-interval x y)
  (make-interval (- (interval-low x) (interval-high y))
		 (- (interval-high x) (interval-low y))))

(define (mul-interval x y)
  (let ((ll (* (interval-low x) (interval-low y)))
        (lh (* (interval-low x) (interval-high y)))
        (hl (* (interval-high x) (interval-low y)))
        (hh (* (interval-high x) (interval-high y))))
    (make-interval (min ll lh hl hh)
                   (max ll lh hl hh))))

(define (div-interval x y)
  (mul-interval x
                (make-interval (/ 1.0 (interval-high y))
                               (/ 1.0 (interval-low y)))))

(define (square-interval x)
  (make-interval (square (interval-low x))
                 (square (interval-high x))))

(define (sqrt-interval x)
  (make-interval (sqrt (interval-low x))
                 (sqrt (interval-high x))))

(define (sign-interval x)
  (let ((sl (sign-of-number (interval-low x)))
        (sh (sign-of-number (interval-high x))))
    (cond ((and (= sl 1) (= sh 1)) 1)
          ((and (= sl -1) (= sh -1)) -1)
          (else 0))))

(define (negate-interval y)
  (make-interval (- 0.0 (interval-high y))
		 (- 0.0 (interval-low y))))

(define (invert-interval y)
  (make-interval (/ 1.0 (interval-high y))
		 (/ 1.0 (interval-low y))))

(define (abs-interval x)
  (let ((al (abs (interval-low x)))
        (ah (abs (interval-high x))))
    (make-interval (min al ah) (max al ah))))



(define (=-interval x y)
  (and (= (interval-high x) (interval-high y))
       (= (interval-low x) (interval-low y))))


(define (<-interval x y)
  (< (interval-high x) (interval-low y)))

(define (>-interval x y)
  (> (interval-low x) (interval-high y)))

(define (<=-interval x y)
  (<= (interval-high x) (interval-low y)))

(define (>=-interval x y)
  (>= (interval-low x) (interval-high y)))


(define (empty-interval? x)
  (> (interval-low x) (interval-high x)))

(define (intersect-intervals x y)
  (make-interval
   (max (interval-low x) (interval-low y))
   (min (interval-high x) (interval-high y))))

(define (subinterval? interval-1 interval-2)
  (and (>= (interval-low interval-1) (interval-low interval-2))
       (<= (interval-high interval-1) (interval-high interval-2))))

(define (within-interval? number interval)
  (<= (interval-low interval) number (interval-high interval)))

(assign-operation '+ add-interval interval? interval?)
(assign-operation '+ (coercing ->interval add-interval) number? interval?)
(assign-operation '+ (coercing ->interval add-interval) interval? number?)

(assign-operation '- sub-interval interval? interval?)
(assign-operation '- (coercing ->interval sub-interval) number? interval?)
(assign-operation '- (coercing ->interval sub-interval) interval? number?)

(assign-operation '* mul-interval interval? interval?)
(assign-operation '* (coercing ->interval mul-interval) number? interval?)
(assign-operation '* (coercing ->interval mul-interval) interval? number?)

(assign-operation '/ div-interval interval? interval?)
(assign-operation '/ (coercing ->interval div-interval) number? interval?)
(assign-operation '/ (coercing ->interval div-interval) interval? number?)


(assign-operation 'generic-= =-interval interval? interval?)
(assign-operation 'generic-= (coercing ->interval =-interval) number? interval?)
(assign-operation 'generic-= (coercing ->interval =-interval) interval? number?)

(assign-operation 'generic-< <-interval interval? interval?)
(assign-operation 'generic-< (coercing ->interval <-interval) number? interval?)
(assign-operation 'generic-< (coercing ->interval <-interval) interval? number?)

(assign-operation 'generic-> >-interval interval? interval?)
(assign-operation 'generic-> (coercing ->interval >-interval) number? interval?)
(assign-operation 'generic-> (coercing ->interval >-interval) interval? number?)

(assign-operation 'generic-<= <=-interval interval? interval?)
(assign-operation 'generic-<= (coercing ->interval <=-interval) number? interval?)
(assign-operation 'generic-<= (coercing ->interval <=-interval) interval? number?)

(assign-operation 'generic->= >=-interval interval? interval?)
(assign-operation 'generic->= (coercing ->interval >=-interval) number? interval?)
(assign-operation 'generic->= (coercing ->interval >=-interval) interval? number?)


(assign-operation 'square square-interval interval?)
(assign-operation 'sqrt sqrt-interval interval?)
(assign-operation 'generic-sign sign-interval interval?)
(assign-operation 'negate negate-interval interval?)
(assign-operation 'invert invert-interval interval?)
(assign-operation 'abs abs-interval interval?)

(define (merge-interval-number int num)
  (if (within-interval? num int)
      num
      the-contradiction))

(define (merge-intervals content increment)
  (let ((new-range (intersect-intervals content increment)))
    (cond ((=-interval new-range content) content)
	  ((=-interval new-range increment) increment)
	  ((empty-interval? new-range) the-contradiction)
	  (else new-range))))


(assign-operation 'merge merge-intervals interval? interval?)
(assign-operation 'merge merge-interval-number interval? number?)
(assign-operation 'merge
                  (reverse-args merge-interval-number)
                  number? interval?)
