;;; Here, transistor is set to be saturated

(initialize-scheduler)

(define TOP (node 'TOP))

(define GND (node 'GND))

(define B (node 'B))

(define C (node 'C))

(define E (node 'E))

(define-cell VThreshold)
(define-cell VSaturation)
(define Q
  ((bjt-crude-bias VThreshold VSaturation 'Q 'saturated)
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
(tell! RC 15000 'gjs8)
(tell! RE  1000   'gjs6)

(tell! VThreshold 0.65 'gjs7)
(tell! VSaturation 0.2 'gjs7)

(cpp (inquire (thing '(current c Q))))
#;
((current c Q) (has-value (*the-nothing*)) (because ()) (depends-on))

(cpp (inquire (thing '(potential B))))
#;
((potential B) (has-value (*the-nothing*)) (because ()) (depends-on))

(plunk! (thing '(potential B)))

(cpp (inquire (thing '(potential B))))
#;
((potential B)
 (has-value 1.5786695986805936)
 (because
  (solver)
  ((- ((a GND) (a GND)) (current t2 VCC))
   (sum (a GND) (current t2 VCC) (a GND))
   GND)
  ((- ((zero-i VCC) (current t1 VCC)) (current t2 VCC))
   (sum (current t1 VCC) (current t2 VCC) (zero-i VCC))
   VCC))
 (depends-on (gjs6) (gjs3) (gjs4) (gjs8) (gjs7) (gjs2) (gjs1)))

(cpp (inquire (thing '(current c Q))))
#;
((current c Q)
 (has-value 9.247553600879603e-4)
 (because
  ((- ((i12 Q) (current b Q)) (current c Q))
   (sum (current b Q) (current c Q) (i12 Q))
   Q))
 (depends-on (gjs6) (gjs3) (gjs4) (gjs8) (gjs7) (gjs2) (gjs1)))

(cpp (inquire (thing '(potential E))))
#;
((potential E)
 (has-value .9286695986805936)
 (because
  ((- ((potential B) (v13 Q)) (potential E))
   (sum (v13 Q) (potential E) (potential B))
   Q))
 (depends-on (gjs6) (gjs3) (gjs4) (gjs8) (gjs7) (gjs2) (gjs1)))
