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

;;; Constraint-propagator-constructors

(define (sum x y total)
  (constraint-propagator (list x y total)
    (lambda ()
      (adder x y total)
      (subtractor total x y)
      (subtractor total y x))
    `(sum ,(name x) ,(name y) ,(name total))))

(define c:+ sum)

(define (product x y total)
  (constraint-propagator (list x y total)
    (lambda ()
      (multiplier x y total)
      (divider total x y)
      (divider total y x))
    `(product ,(name x) ,(name y) ,(name total))))

(define c:* product)


(define (c:negate x y)
  (constraint-propagator (list x y)
    (lambda ()
      (p:negate x y)
      (p:negate y x))
    `(c:negate ,(name x) ,name y)))

(define (c:invert x y)
  (constraint-propagator (list x y)
    (lambda ()
      (p:invert x y)
      (p:invert y x))
    `(c:invert ,(name x) ,name y)))                           

(define (c:exp x y)
  (constraint-propagator (list x y)
    (lambda ()
      (p:exp x y)
      (p:log y x))
    `(c:exp ,(name x) ,name y)))

(define (same x y)
  (constraint-propagator (list x y)
    (lambda ()
      (copier x y)
      (copier y x))
    `(same ,(name x) ,(name y))))

(define (controlled-same a b p)
  (constraint-propagator (list a b p)
    (lambda ()
      (spst-switch p a b)
      (spst-switch p b a))
    `(controlled-same ,(name a) ,(name b) ,(name p))))

(define (full-same a b p)
  (constraint-propagator (list a b p)
    (lambda ()
      (=? a b p)
      (spst-switch p a b)
      (spst-switch p b a))
    `(full-same ,(name a) ,(name b) ,(name p))))

;;; Logical constraints

(define (conjunction a b c)
  (constraint-propagator (list a b c)
    (lambda ()
      (conjoiner a b c)
      (p:dna c a b)
      (p:dna c b a)
      (p:imp c a)
      (p:imp c b))
    `(conjunction ,(name a) ,(name b) ,(name c))))

(define (disjunction a b c)
  (constraint-propagator (list a b c)
    (lambda ()
      (disjoiner a b c)
      (p:ro c a b)
      (p:ro c b a)
      (p:pmi c a)
      (p:pmi c b))
    `(disjunction ,(name a) ,(name b) ,(name c))))

(define (implication a b)
  (constraint-propagator (list a b)
    (lambda ()
      (p:imp a b)
      (p:pmi b a))))

(define (inversion a b)
  (constraint-propagator (list a b)
    (lambda ()
      (inverter a b)
      (inverter b a))
    `(inversion ,(name a) ,(name b))))

(define c:inverter inversion)

;;; p:sqrt delivers the positive square root.

(define (quadratic x x^2)
  (constraint-propagator (list x x^2)
    (lambda ()
      (p:square x x^2)
      (p:sqrt x^2 x))
    `(quadratic ,(name x) ,(name x^2))))


;;; These use AMB because square root and
;;;  reverse-abs are ambiguous as to sign.

(define (c:square x x^2)
  (constraint-propagator (list x x^2)
    (lambda ()
      (p:square x x^2)
      (let-cells (p (one 1) (m-one -1) mul +x)
        (conditional p one m-one mul)
        (binary-amb p)
        (p:sqrt x^2 +x)
        (product mul +x x)))
    `(c:square ,(name x) ,(name x^2))))

(define (+->+ x ax)
  (constraint-propagator (list x ax)
    (lambda ()
      (absolute-value x ax)
      (let-cells (p (one 1) (m-one -1) mul)
        (conditional p one m-one mul)
        (binary-amb p)
        (product mul ax x)))
    `(+->+ ,(name x) ,(name ax))))

(define c:abs +->+)

;;; Three boolean values, only one may be true

(define (choose-exactly-one u v w)
  (constraint-propagator (list u v w)
    (lambda ()
      (let-cells (-u -v -w u+v u+v+w)
	(inverter -u u)
	(inverter -v v)
	(inverter -w w)

	(p:imp u -v)
	(p:imp u -w)

	(p:imp v -u)
	(p:imp v -w)

	(p:imp w -u)
	(p:imp w -v)

	(disjunction u v u+v)
	(disjunction u+v w u+v+w)
	(add-content u+v+w #t)))
    `(choose-exactly-one ,(name u)
			 ,(name v)
			 ,(name w))))
			 

#|
(begin
  (initialize-scheduler)
  (define-cell x)
  (define-cell y)
  (define-cell z)
  (choose-exactly-one x y z)
  ((x 'probe!) (lambda args (pp args)))
  ((y 'probe!) (lambda args (pp args)))
  ((z 'probe!) (lambda args (pp args)))
  (run)
  (add-content x #t 'g)
  )
|#
