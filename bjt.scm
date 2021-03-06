(define (bjt-active-beta-model VBEthreshold VCEsaturation beta
                               #!optional given-name)
  (3-terminal-device '(bjt-active-beta-model b c e) given-name
    (lambda (VBE IB VCE IC)
      (let-cells (type                ;+ for NPN, - for PNP
                  VBEsign VCEsign IBsign ICsign
                  absVBEthreshold absVCEsaturation
		  absVBE absVCE absIC IE
                  (false #f))

        (sign VBEthreshold type)

        (same VBEsign type)
        (sign VBE VBEsign)

        (same VCEsign type)
        (sign VCE VCEsign)

        (same IBsign type)
        (sign IB IBsign)

        (same ICsign type)
        (sign IC ICsign)

        (absolute-value VBEthreshold absVBEthreshold)
        (absolute-value VBE absVBE)

        (absolute-value VCEsaturation absVCEsaturation)

        ;; Active transistor
        (<=? absVCE absVCEsaturation false)    ;Not saturated
        (same VBE VBEthreshold)                ;Not cutoff
        (product beta IB IC)
	)
      trivial-insides)
    VBEthreshold VCEsaturation beta))

(define (exponential-diode IS q/kT #!optional given-name)
  (2-terminal-device '(exponential-diode anode cathode) given-name
    (lambda (v i)
      (let-cells (v*q/kT e^v*q/kT e^v*q/kT-1 (one 1))
        (product v q/kT v*q/kT)
        (c:exp v*q/kT e^v*q/kT)
        (sum one e^v*q/kT-1 e^v*q/kT)
        (product e^v*q/kT-1 IS i))
      trivial-insides)
    IS q/kT))

(define (bjt-active-EberMoll-model VBEthreshold VCEsaturation beta IS
                                   #!optional given-name)
  (3-terminal-device '(bjt-active-EberMoll-model b c e) given-name
    (lambda (VBE IB VCE IC)
      (let-cells (type                ;+ for NPN, - for PNP
                  VBEsign VCEsign IBsign ICsign
                  absVBEthreshold absVCEsaturation
		  absVBE absVCE absIC IE
                  (false #f))

        (sign VBEthreshold type)

        (same VBEsign type)
        (sign VBE VBEsign)

        (same VCEsign type)
        (sign VCE VCEsign)

        (same IBsign type)
        (sign IB IBsign)

        (same ICsign type)
        (sign IC ICsign)

        (absolute-value VBEthreshold absVBEthreshold)
        (absolute-value VBE absVBE)

        (absolute-value VCEsaturation absVCEsaturation)

        ;; Active transistor
        (<=? absVCE absVCEsaturation false)    ;Not saturated


	((exponential-diode IS q/kT)
	 (my-node 'b) (my-node 'e))

	#;	
        (let-cells (v*q/kT e^v*q/kT e^v*q/kT-1 (one 1)
			   mIE (mone -1))
          (product VBE q/kT v*q/kT)
          (c:exp v*q/kT e^v*q/kT)
          (sum one e^v*q/kT-1 e^v*q/kT)
          (product e^v*q/kT-1 IS mIE)
          (product mone mIE IE))

        (product beta IB IC)
	)
      trivial-insides)
    VBEthreshold VCEsaturation beta IS))

#|
;;; Test diode

(initialize-scheduler)

(define TOP (node 'TOP))
(define GND (node 'GND))

;(define-cell IS 1e-14)
(define-cell IS 'I_S)
;(define-cell q/kT 38)
(define-cell q/kT 'q/kT)

(define D
  ((exponential-diode IS q/kT 'D) TOP GND))

(tell! (potential GND) 0 'test1)

(inquire (thing '(current anode D)))
;Value: ((current anode D) (has-value (*the-nothing*)) (because ()) (depends-on))

(tell! (thing '(current anode D)) 'I_D 'test2)

(inquire (potential TOP))
;Value:
((potential TOP)
 (has-value (*number* (expression (/ (log (+ 1 (/ I_D I_S))) q/kT))))
 (because ((+ ((v D) (potential GND)) (potential TOP))
	   (sum (v D) (potential GND) (potential TOP))
	   D))
 (depends-on (test1) (test2)))
;;; This is correct.

;;; But! Numerically...

(initialize-scheduler)

(define TOP (node 'TOP))
(define GND (node 'GND))

(define-cell IS 1e-14)
(define-cell q/kT 38)

(define D
  ((exponential-diode IS q/kT 'D) TOP GND))

(tell! (potential GND) 0 'test1)
(tell! (thing '(current anode D)) '.01 'test2)

(inquire (potential TOP))
;Value: ((potential TOP)
         (has-value .7271321346297249)
         (because ((+ ((v D) (potential GND)) (potential TOP))
		   (sum (v D) (potential GND) (potential TOP))
		   D))
        (depends-on (test1) (test2)))
|#

#|
;;; Beta model of common-emitter amplifier.

(initialize-scheduler)

(define TOP (node 'TOP))
(define GND (node 'GND))

(define B (node 'B))
(define C (node 'C))
(define E (node 'E))

(define-cell VThreshold)
(define-cell VSaturation)
(define-cell beta)

(define Q
  ((bjt-active-beta-model VThreshold VSaturation beta 'Q)
   B C E))

(define-cell RB1)
(define RBU ((linear-resistor RB1 'RB1) TOP B))

(define-cell RB2)
(define RBD ((linear-resistor RB2 'RB2) B GND))

(define-cell RC)
(define RPU ((linear-resistor RC 'RC) TOP C))

(define-cell RE)
(define RPD ((linear-resistor RE 'RE) E GND))

(define-cell VCC)
(define VS  ((voltage-source VCC 'VCC) TOP GND))

(cap! TOP)
(cap! GND)
(cap! B)
(cap! C)
(cap! E)

;;; E96 1% values

(tell! VCC 15 'gjs1)
(tell! (potential GND) 0 'gjs2)

(tell! RB2 20000  'gjs3)
(tell! RB1 162000 'gjs4)
(tell! RC  4990   'gjs5)
(tell! RE  1000   'gjs6)

(tell! VThreshold 0.65 'gjs7)		
(tell! VSaturation 0.2 'gjs7)
(tell! beta 100 'gjs8)

(cpp (inquire (thing '(current c Q))))
#;
((current c Q) (has-value (*the-nothing*)) (because ()) (depends-on))

(plunk! (thing '(potential B)))

(cpp (inquire (thing '(current c Q))))
#;
((current c Q) (has-value 8.403477939136069e-4)
 (because ((* ((beta) (current b Q)) (current c Q))
	   (product (beta) (current b Q) (current c Q))
	   Q))
 (depends-on (gjs2) (gjs3) (gjs4) (gjs1) (gjs6) (gjs7) (gjs8)))

(cpp (inquire (thing '(current b Q))))
#;
((current b Q) (has-value 8.40347793913607e-6)
 (because ((- ((a B) (current t2 RB1)) (current b Q))
           (sum (current t2 RB1) (current b Q) (a B)) B))
 (depends-on (gjs7) (gjs6) (gjs8) (gjs1) (gjs4) (gjs3) (gjs2)))
;Unspecified return value

(cpp (inquire (thing '(potential B))))
#;
((potential B) (has-value 1.4987512718527425)
 (because (solver)
          ((- ((i12 Q) (current c Q)) (current b Q))
           (sum (current b Q) (current c Q) (i12 Q)) Q)
          ((- ((a B) (current t2 RB1)) (current b Q))
           (sum (current t2 RB1) (current b Q) (a B)) B))
 (depends-on (gjs7) (gjs6) (gjs8) (gjs1) (gjs4) (gjs3) (gjs2)))

(cpp (inquire (thing '(P Q))))
#;
((P Q) (has-value 8.373572680951747e-3)
 (because ((+ ((P1 Q) (P2 Q)) (P Q)) (sum (P1 Q) (P2 Q) (P Q)) Q))
 (depends-on (gjs5) (gjs7) (gjs6) (gjs8) (gjs1) (gjs4) (gjs3) (gjs2)))
|#

#|
;;; Exponential-diode model of BJT in common-emitter amplifier.

;;; This does not yet work

(initialize-scheduler)

(define TOP (node 'TOP))
(define GND (node 'GND))

(define B (node 'B))
(define C (node 'C))
(define E (node 'E))

(define-cell VThreshold)
(define-cell VSaturation)
(define-cell beta)
(define-cell IS)

(define-cell q/kT 38)

(define Q
  ((bjt-active-EberMoll-model VThreshold VSaturation beta IS 'Q)
   B C E))

(define-cell RB1)
(define RBU ((linear-resistor RB1 'RB1) TOP B))

(define-cell RB2)
(define RBD ((linear-resistor RB2 'RB2) B GND))

(define-cell RC)
(define RPU ((linear-resistor RC 'RC) TOP C))

(define-cell RE)
(define RPD ((linear-resistor RE 'RE) E GND))

(define-cell VCC)
(define VS  ((voltage-source VCC 'VCC) TOP GND))

(cap! TOP)
(cap! GND)
(cap! B)
(cap! C)
(cap! E)

;;; E96 1% values

(tell! VCC 15 'gjs1)
(tell! (potential GND) 0 'gjs2)

(tell! RB2 20000  'gjs3)
(tell! RB1 162000 'gjs4)
(tell! RC  4990   'gjs5)
(tell! RE  1000   'gjs6)

(tell! VThreshold 0.65 'gjs7)		
(tell! VSaturation 0.2 'gjs7)
(tell! beta 100 'gjs8)
(tell! IS 1e-14 'gjs8)


;;; the following buggy version has exponential diode in model...

(cpp (inquire (thing '(current c Q))))
#;
((current c Q) (has-value (*the-nothing*)) (because ()) (depends-on))

(plunk! (thing '(potential B)))

(cpp (inquire (thing '(current c Q))))
#;
((current c Q) (has-value (*the-nothing*)) (because ()) (depends-on))

(plunk! (thing '(current c Q)))
#|
(contradiction #[compound-procedure 76 me]
	       (gjs6 gjs8 gjs1 gjs4 gjs3 gjs2)
	       (#[compound-procedure 77 me]
		#[compound-procedure 78 me]))
|#

(name (unhash 76))
;Value: (potential E)

(cpp (name (unhash 77)))
#|
((+ ((v RE) (potential GND)) (potential E))
 (sum (v RE) (potential GND) (potential E))
 RE)
|#

(cpp (name (unhash 78)))
#|
((- ((potential B) (v (exponential-diode ((IS) (q/kT)) (B) (E)) Q)) (potential E))
 (sum (v (exponential-diode ((IS) (q/kT)) (B) (E))) (potential E) (potential B))
 (exponential-diode ((IS) (q/kT)) (B) (E))
 Q)
|#
;;; UGH!

;;; in symbolic-equal? defined in plunk-and-solve.scm, ugh!

;;; Problem is that generic-zero? as used in apply-f-multiply (in
;;; propagators.scm) must be very strict to exclude 1e-14=0 for
;;; setting i_diode to be zero, but it must be very loose for
;;; symbolic-equal? (defined in plunk-and-solve.scm) to prevent
;;; contradictions based on roundoff on reverse propagation in a
;;; circuit.
|#








