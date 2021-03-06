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


(declare (usual-integrations make-cell))

;;; Construction of propagators. 
;;;  A propagator is represented by a message-acceptor.
;;;  A propagator has a parent, of which it is a part.
;;;  There is a top-level parent of the sytem.  The fluid
;;;  variable *my-parent* is defined in scheduler.scm

(define (propagator inputs outputs to-do #!optional name)
  (define (me message)
    (case message
      ((name) name)
      ((set-name!)
       (lambda (new)
         (set! name new)
         (eq-put! me 'name name)))
      ((inputs) inputs)
      ((outputs) outputs)
      ((to-do) to-do)
      (else
       (error "Unknown message" message)
       me)))
  (set! inputs (listify inputs))
  (set! outputs (listify outputs))
  (for-each (lambda (cell)
              (new-neighbor! cell to-do))
            inputs)
  (if (default-object? name)
      ((me 'set-name!) me)
      ((me 'set-name!) name))
  (eq-put! me 'propagator #t)
  (eq-put! me 'parent *my-parent*)
  (eq-adjoin! *my-parent* 'children me)
  (alert-propagators to-do)
  me)

(define (propagator? thing)
  (eq-get thing 'propagator))

(define (propagator-name propagator)
  (propagator 'name))

(define (set-propagator-name! propagator name)
  ((propagator 'set-name!) name))

(define (propagator-inputs propagator)
  (propagator 'inputs))

(define (propagator-outputs propagator)
  (propagator 'outputs))

(define (propagator-to-do propagator)
  (propagator 'to-do))

;;; Primitive propagators are constructed from Scheme functions

(define (function->propagator-constructor f #!optional my-name lifter)
  (if (default-object? lifter) (set! lifter apply-f-strictly))
  (lambda cells
    (let ((output (car (last-pair cells)))
          (inputs (except-last-pair cells))
          (lifted-f (lifter f)))
      ;; The output isn't a neighbor, Because the propagation
      ;; activities do not depend upon changes in the content of the
      ;; output cell.
      (define me
        (propagator inputs output
          (lambda ()
            (fluid-let ((*my-parent* me))
              (add-content output
                           (apply lifted-f
                                  (content output)
                                  (map content inputs))
                           me)))
	  (if (default-object? my-name)
	      `(function-propagator ,(name f)
				    ,(map name inputs)
				    ,(name output))
	      `(,my-name
                ,(map name inputs)
                ,(name output)))))
      (eq-put! me 'type 'primitive)
      (eq-put! me 'action f)
      me)))

(define (apply-f-strictly f)
  (lambda (output . args)
    (if (any (lambda (x)
               (or (nothingness? x)
                   (contradictory? x)))
             args)
        nothing
        (apply f args))))

(define *apply-f-multiply/divide-zero-tolerance* 1e-20)

(define (gzero? x)
  (let ((v (generic-extract-value x)))
    (if (nothingness? v)
        #f
        (fluid-let ((*equality-tolerance*
                     *apply-f-multiply/divide-zero-tolerance*))
          (generic-zero? v)))))

(define (apply-f-multiply f)
  (lambda (result . args)
    (if (any contradictory? args)
        nothing
        (let ((zs (filter gzero? args)))
          (cond ((null? zs)
                 (if (any nothingness? args)
                     nothing
                     (apply f args)))
                ((null? (cdr zs))
                 (generic-identity (car zs)))
                (else
                 (apply f zs)))))))

(define (apply-f-divide f)
  (lambda (result . args)
    (cond ((or (contradictory? result)
               (any contradictory? args))
           nothing)
          ((nothingness? (car args))
	   nothing)
          ((gzero? (cadr args))         ;divisor=0
           (if (gzero? (car args))      ;dividend=0
               nothing                  ;0/0 can be anything
               (error "Division of non-zero by zero"
                      args result)))
          ((gzero? (car args))               ;dividend=0
           (if (gzero? result)               ;quotient=0
               (generic-identity (car args)) ;a good reason!
               (if (or (gzero? (cadr args))
                       (nothingness? (cadr args)))
                   nothing              ;0/0 can be anything
                   (apply f args))))    ;possible contradiction
          ((nothingness? (cadr args))   ;unknown divisor
           nothing)
          (else (apply f args)))))

;;; Compound propagators must build themselves.
;;;  Policy is build if there is a non-nothing input.

(define (compound-propagator inputs outputs to-build #!optional name)
  (let ((done? #f)
        (inputs (listify inputs))
        (outputs (listify outputs)))
    (define (test)
      (if done?
          'ok
          (if (every nothingness? (map content inputs))
              'ok
              (begin (set! done? #t)
                     (fluid-let ((*my-parent* me))
                       (to-build))))))
    (define me
      (propagator inputs outputs test name))
    (eq-put! me 'type 'compound)
    (eq-put! me 'action to-build)
    me))


;;; A constraint propagator is a compound propagator with
;;; inputs=outputs.

(define (constraint-propagator cells to-build #!optional name)
  (compound-propagator cells cells to-build name))


(define (physob? x)
  (eq-get x 'physob))
