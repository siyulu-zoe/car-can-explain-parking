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
(declare (usual-integrations make-cell cell?))

;; So that wheels can be accessed as a structure
(define-structure
  (wheels
   (type vector) (named 'wheels) (print-procedure #f))
  left-front right-front left-back right-back)

(define wheels-equal? equal?)

; Constants for conversions
(define speed-conversion 0.00621)
(define booster-constant 4)

(define (->wheels x)
  (if (wheels? x)
      x
      (make-wheels '0 '0 '0 '0)))

(define *vehicle-wheels*)

;;; The brake master cylinder converts the force applied by the driver
;;; and boosted by the brake booster into hydraulic brake pressure
;;; Handbook page : 931
;;; Controls slave cylinders located at the other end of the hydraulic system
(define (brake-master-cylinder foot-force 
			       front-pressure back-pressure 
			       #!optional given-name)
  (physob (list foot-pressure booster-constant)
	  (lambda ()
	    (let-cells ((hydraulic)
			(booster booster-constant)) 
		       (adder foot-force booster 
			      hydraulic)
		       (copier hydraulic
			       front-pressure)
		       (copier hydraulic
			       back-pressure)
		       (define (insides-name message)
			 (case message
			   ((hydraulic) hydraulic)
			   ((booster) booster)
			   ((foot-force) foot-force)
			   ((front-pressure) front-pressure)
			   ((back-pressure) back-pressure)
			   (else #f)))
		       insides-name))
  (if (default-object? given-name)
      `(,type ,(map name booster-constant)) ; naming not exactly right
      given-name)))

;;;Change this to get wheels  
;;;Want to pass in a set/list of wheels
(define (antilock-brake-system front-pressure back-pressure 
	     left-back-disk-brake right-back-disk-brake
	     left-front-disk-brake right-front-disk-brake #!optional
			       given-name)
  (physob (list front-pressure back-pressure 
		left-back-disk-brake right-back-disk-brake
		left-front-disk-brake right-front-disk-brake)
	  (lambda ()
	    (let-cells (hydraulic 
			(booster booster-constant)) 
		       (adder front-pressure booster 
			      hydraulic)
		       (copier back-pressure
			       left-back-disk-brake)
		       (copier back-pressure
			       right-back-disk-brake)
		       (copier back-pressure
			       left-front-disk-brake)
		       (copier front-pressure
			       right-front-disk-brake)
		       (define (insides-name message)
			 (case message
			   ((hydraulic) hydraulic)
			   ((booster) booster)
			   ((foot-pressure) foot-pressure)
			   ((front-pressure) front-pressure)
			   ((back-pressure) back-pressure)
			   (else #f)))
		       insides-name))
  (if (default-object? given-name)
      `(,type ,(map name booster-constant)) ; naming not exactly right
      given-name)))

; For basic brake modeling
(define (tire-object diameter-input pressure #!optional given-name)
  (physob (list diameter-input) 
   (lambda ()
     (let-cells (rotation friction (diameter diameter-input))
		(copier pressure friction)
		(inverter pressure rotation)
		(define (insides-name message)
		  (case message
		    ((diameter) diameter)
		    ((pressure) pressure)
		    ((rotation) rotation)
		    ((friction) friction)
		    (else #f)))
       insides-name))
  (if (default-object? given-name)
      `(,type ,(map name diameter-input))
      given-name)))

; May want to take in the entire wheel object
; caliper contains a piston
(define (disc-brake brake-fluid-pressure tire #!optional given-name)
  (physob (list brake-fluid-pressure)
	  (lambda ()
	    (let-cells (caliper rotor brake-pad friction)
		       ; do a bunch of actions on these objects
		       (define (insides-name message)
			 (case message
			   ((caliper) caliper)
			   ((rotor) rotor)
			   ((brake-pad) brake-pad)
			   ((friction) friction)
			   (else #f)))
		       insides-name))
	  (if (default-object? given-name)
	      `(,type ,(map name diameter))
	      given-name)))

; GPS operator
(define (gps heading rotation #!optional given-name)
  (physob (list heading rotation) 
   (lambda ()
     (let-cells (speed (speed-conversion-cell speed-conversion))
		(multiplier rotation speed-conversion-cell speed)
		(define (insides-name message)
		  (case message
		    ((heading) heading)
		    ((rotation) rotation)
		    ((speed) speed)
		    (else #f)))
       insides-name))
  (if (default-object? given-name)
      `(,type ,(map name diameter))
      given-name)))

;; Steering (operator)
;; Angle : Left-most  = 0x1BC (positive)
;;         Neutral    = 0
;;         Right-most = 0xE48 (negative)
;; Put in a direction qualitative 
(define (steering heading #!optional given-name)
  (physob (list heading) 
   (lambda ()
     (let-cells (direction)
		(define (insides-name message)
		  (case message
		    ((heading) heading)
		    ((direction) direction)
		    (else #f)))
       insides-name))
  (if (default-object? given-name)
      `(,type ,(map name diameter))
      given-name)))

; Throttle/gas pedal (operator)
(define (throttle gas tires #!optional given-name)
  (let ((left-back-tire (wheels-left-back tires))
	(right-back-tire (wheels-right-back tires))
	(left-front-tire (wheels-left-front tires))
	(right-front-tire (wheels-right-front tires)))
    (physob (list gas) 
	    (lambda ()
	      (let-cells (direction)
			 ; if statement for tires if gas inc 
			 ; conditional prop?
			 (define (insides-name message)
			   (case message
			     ((gas) gas)
			     ((direction) direction)
			     (else #f)))
			 insides-name))
	    (if (default-object? given-name)
		`(,type ,(map name diameter))
		given-name))))
; Sensor data with lidar
; 11 components 
; TODO - connection
(define (sensor component sensor-trace #!optional given-name)
  (let ((s1 (list-ref sensor-trace 0))
	(s2 (list-ref sensor-trace 1))
	(s3 (list-ref sensor-trace 2))
	(s4 (list-ref sensor-trace 3))
	(s5 (list-ref sensor-trace 4))
	(s6 (list-ref sensor-trace 5))
	(s7 (list-ref sensor-trace 6))
	(s8 (list-ref sensor-trace 7))
	(s9 (list-ref sensor-trace 8))
	(s10 (list-ref sensor-trace 9))
	(s11 (list-ref sensor-trace 10)))
    (physob (list component) 
	    (lambda ()
	      (let-cells (component)
			 ; if statement for tires if gas inc 
			 ; conditional prop?
			 (define (insides-name message)
			   (case message
			     ((component) component)
			     ((s1) s1)
			     ((s2) s2)
			     ((s3) s3)
			     ((s4) s4)
			     ((s5) s5)
			     ((s6) s6)
			     ((s7) s7)
			     ((s8) s8)
			     ((s9) s9)
			     ((s10) s10)
			     ((s11) s11)
			     (else #f)))
			 insides-name))
	    (if (default-object? given-name)
		`(,type ,(map name component))
		given-name))))

;;; Some things for initialization
(define (initialize-vehicle-system lower-bound upper-bound log-file)
  (let ((lower-state (fetch-snapshot lower-bound log-file))
	(upper-state (fetch-snapshot upper-bound log-file)))
    (let ((qual-summary (set-qual-summary lower-state upper-state
      (make-log-interval-qual (make-interval 0 0)
                              '? '? '? '? '? '? '? '? '?
                              '? '? '? '? '? '? '? '? '?))))  
      (pp qual-summary)
					; initialize car system
  (initialize-scheduler)
  (initialize-brake-system qual-summary)
  (initialize-engine-system qual-summary)
)))

;; Brake system
(define (initialize-brake-system qual-summary)
  (define-cells 
    (foot-brake-pressure front-brakes-pressure back-brakes-pressure
			 left-back-pressure right-back-pressure
			 left-front-pressure right-front-pressure
			 left-back-tire right-back-tire
			 left-front-tire right-front-tire))

  (define brake-master
    (brake-master-cylinder foot-brake-pressure 
			   front-brakes-pressure back-brakes-pressure 
			   'brake-master))
  (define antilock-brakes 
    (antilock-brake-system front-brakes-pressure back-brakes-pressure 
	     left-back-pressure right-back-pressure
	     left-front-pressure right-front-pressure 
	     'antilock-brakes))

  (define left-back-disk-brake
    (disc-brake left-back-pressure left-back-tire 
		'left-back-disk-brake))

  (define right-back-disk-brake
    (disc-brake right-back-pressure right-back-tire 
		'right-back-disk-brake))

  (define left-front-disk-brake
    (disc-brake left-front-pressure left-front-tire 
		'left-front-disk-brake))

  (define right-front-disk-brake
    (disc-brake right-front-pressure right-front-tire 
		'right-front-disk-brake))

  (tell! foot-brake-pressure (log-interval-qual-brake qual-summary) 
	 'brake-change-from-initialized-interval)

  (set! *vehicle-wheels* (make-wheels left-back-tire right-back-tire
				      left-front-tire right-front-tire))
  ;; Making car-environment for brakes; all exports below
  (set-access 
   (foot-brake-pressure front-brakes-pressure back-brakes-pressure
    left-back-pressure right-back-pressure
    left-front-pressure right-front-pressure
    left-back-tire right-back-tire left-front-tire right-front-tire
    brake-master antilock-brakes
    left-back-disk-brake right-back-disk-brake
    left-front-disk-brake right-front-disk-brake))
)

(define (initialize-perception-system qual-summary)
  (define-cell lidar-cell)
  (define-cell perception-cell)

  (define top-lidar
    (sensor perception-cell lidar-cell 'lidar))

  (tell! lidar-cell (log-interval-qual-lidar qual-summary) 
	 'lidar-change-from-initialized-interval)

  (tell! perception-cell (log-interval-qual-perception qual-summary)
	 'perception-change-from-initialized-interval)

  #|(set-access 
  # (heading-cell gas-cell rotation-cell internal-car-gps steering-wheel gas))|#
)

#|
  (inquire-readable (front-pressure brake-master))

  (inquire-readable (hydraulic antilock-brakes))
  (inquire (front-pressure antilock-brakes))
|#

;; The "engine" system consists of the gas pedal, gps and steering
;; wheel
(define (initialize-engine-system qual-summary)
  (define-cell heading-cell)
  (define-cell gas-cell)
  (define-cell rotation-cell)
  ; use rotation from one of the wheels

  (define internal-car-gps
    (gps heading-cell rotation-cell 'car-gps))

  (define steering-wheel
    (steering heading-cell 'steering))

  ; Figure out if these are tires or all the tires together
  (define gas-pedal
    (throttle gas-cell *vehicle-wheels* 'gas-pedal))

  ;(pp (log-interval-qual-heading qual-summary))

  (tell! heading-cell (log-interval-qual-heading qual-summary) 
	 'heading-change-from-initialized-interval)

  (tell! gas-cell (log-interval-qual-gas-pedal qual-summary)
	 'gas-change-from-initialized-interval)

  (set-access 
   (heading-cell gas-cell rotation-cell internal-car-gps steering-wheel gas))
)


;; Tire information 
(define (diameter tire)
  (tire 'diameter))

(define (pressure tire)
  (tire 'pressure))

(define (rotation tire)
  (tire 'rotation))

; May need to have more brake information
(define (friction brake)
  (brake 'friction))

; Cylinder information
(define (hydraulic cylinder)
  (cylinder 'hydraulic))

(define (booster cylinder)
  (cylinder 'booster))

(define (foot-pressure cylinder)
  (cylinder 'foot-pressure))

(define (front-pressure cylinder)
  (cylinder 'front-pressure))

(define (back-pressure cylinder)
  (cylinder 'back-pressure))

; Disk information
(define (caliper disk)
  (disk 'caliper))

(define (rotor disk)
  (disk 'rotor))

(define (brake-pad disk)
  (disk 'brake-pad))

(define (friction disk)
  (disk 'friction))

; GPS information
(define (heading gps)
  (gps 'heading))

(define (speed gps)
  (gps 'speed))

; Steering information
(define (direction steering)
  (steering 'direction))

(define (heading steering)
  (steering 'heading))

; Throttle Information
(define (gas throttle)
  (throttle 'gas))


#|

(load "load")

(ge car-environment)
;Value: #[environment 13]

(initialize-vehicle-system 0 1 "test.log")
#(qualitative 0)
(description 0)
;Value: #f

(inquire-readable (hydraulic antilock-brakes))
(hydraulic-brake-pressure antilock-brakes) has the value increasing change

This was computed from the following: 

function (+)
    inputs:
    (front-brakes-pressure)
    (booster-cell antilock-brakes)

    outputs:
    (hydraulic-brake-pressure antilock-brakes)


This value is supported by the following premises:

(brake-change-from-initialized-interval)

----------------------------------------
|#
