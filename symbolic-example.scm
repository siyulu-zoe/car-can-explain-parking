;;; Voltage-divider

(initialize-scheduler)

(define-cell V)
(define-cell R1)
(define-cell R2)

(define n1 (node 'n1))
(define n2 (node 'n2))
(define gnd (node 'gnd))

(define VS
  ((voltage-source V 'VS) n1 gnd))

(define RL1
  ((linear-resistor R1 'RL1) n1 n2))
(define RL2
  ((linear-resistor R2 'RL2) n2 gnd))

(cap! n1)
(cap! n2)
(cap! gnd)


(tell! V 'V_s 'gjs1)

(tell! R1 'R_1 'gjs2)

(tell! R2 'R_2 'gjs3)

(tell! (potential gnd) 0 'gjs4)


(cpp (inquire (potential n2)))
#;
((potential n2)
 (has-value (*the-nothing*))
 (because ())
 (depends-on))
;;; Of course! no propagation.

;;; We can use a slice to get around this problem:

(define-cell R1+R2)
(define n3 (node 'n3))
(define n4 (node 'n4))

(define Rseries
  ((linear-resistor R1+R2 'Rseries) n3 n4))


;;; Install slice.  
;;; Note: do not cap n3 and n4

(sum R1 R2 R1+R2)

(identify-terminals (thing '(t1 RL1))
                    (thing '(t1 Rseries)))

(identify-terminals (thing '(t2 RL2))
                    (thing '(t2 Rseries)))


(cpp (inquire (potential n2)))
#;
((potential n2)
 (has-value (/ (* R_2 V_s) (+ R_1 R_2)))
 (because
  ((- ((potential n1) (v RL1)) (potential n2))
   (sum (v RL1) (potential n2) (potential n1))
   RL1))
 (depends-on (gjs2) (gjs3) (gjs4) (gjs1)))


;;; Alternatively, we could plunk down a variable and solve.

(initialize-scheduler)

(define-cell V)
(define-cell R1)
(define-cell R2)

(define n1 (node 'n1))
(define n2 (node 'n2))
(define gnd (node 'gnd))

(define VS
  ((voltage-source V 'VS) n1 gnd))

(define RL1
  ((linear-resistor R1 'RL1) n1 n2))
(define RL2
  ((linear-resistor R2 'RL2) n2 gnd))

(cap! n1)
(cap! n2)
(cap! gnd)


(tell! V 'V_s 'gjs1)

(tell! R1 'R_1 'gjs2)

(tell! R2 'R_2 'gjs3)

(tell! (potential gnd) 0 'gjs4)

(define *trace* '())
(((potential n2) 'probe!)
 (lambda (name content increment source answer)
   (pp `(probe: ,name ,content ,increment source))
   (set! *trace*
         (cons `(probe: ,name ,content ,increment ,source)
               *trace*))))

(plunk! (thing '(potential n2)))

(cpp (inquire (potential n2)))
#;
((potential n2)
 (has-value (/ (* R_2 V_s) (+ R_1 R_2)))
 (because
  (solver)
  ((- ((zero-i RL1) (current t1 RL1)) (current t2 RL1))
   (sum (current t1 RL1) (current t2 RL1) (zero-i RL1))
   RL1)
  ((- ((a n2) (current t1 RL2)) (current t2 RL1))
   (sum (current t1 RL2) (current t2 RL1) (a n2))
   n2))
 (depends-on (gjs1) (gjs2) (gjs3) (gjs4)))
;Unspecified return value

;;; Perhaps some synthesis

(initialize-scheduler)

(define-cell V)
(define-cell R1)
(define-cell R2)

(define n1 (node 'n1))
(define n2 (node 'n2))
(define gnd (node 'gnd))

(define VS
  ((voltage-source V 'VS) n1 gnd))

(define RL1
  ((linear-resistor R1 'RL1) n1 n2))
(define RL2
  ((linear-resistor R2 'RL2) n2 gnd))

(cap! n1)
(cap! n2)
(cap! gnd)

(tell! V 'V_s 'gjs1)

(tell! R1 '60000 'gjs2)

(tell! R2 'R_2 'gjs3)

(tell! (potential gnd) 0 'gjs4)

(tell! (thing '(potential n2))
       (/ 'V_s 3)
       'gjs5)
#|
(contradiction #[compound-procedure 38 me] (gjs3 gjs2 gjs5 gjs4 gjs1) (#[compound-procedure 39 me]))
;;;!!! problem !!!

(cpp (inquire R2))
(contradiction #[compound-procedure 38 me] (gjs3 gjs2 gjs5 gjs4 gjs1) (#[compound-procedure 39 me]))
#;
((R2)
 (has-value R_2)
 (because
  ((/ ((v RL2) (current t1 RL2)) (R2)) (product (R2) (current t1 RL2) (v RL2))
                                       RL2))
 (depends-on (gjs5) (gjs4) (gjs3)))

(cpp (name (unhash 39)))
#;
((+ ((current t1 RL1) (current t2 RL1)) (zero-i RL1))
 (sum (current t1 RL1) (current t2 RL1) (zero-i RL1))
 RL1)

(cpp (inquire (thing '(current t1 RL1))))
(contradiction #[compound-procedure 38 me] (gjs3 gjs2 gjs5 gjs4 gjs1) (#[compound-procedure 39 me]))
#;
((current t1 RL1)
 (has-value (* 1/90000 V_s))
 (because ((/ ((v RL1) (R1)) (current t1 RL1)) (product (R1) (current t1 RL1) (v RL1)) RL1))
 (depends-on (gjs2) (gjs5) (gjs4) (gjs1)))

(cpp (inquire (thing '(current t2 RL1))))
(contradiction #[compound-procedure 38 me] (gjs3 gjs2 gjs5 gjs4 gjs1) (#[compound-procedure 39 me]))
#;
((current t2 RL1)
 (has-value (/ (* -1/3 V_s) R_2))
 (because
  ((- ((a n2) (current t1 RL2)) (current t2 RL1)) (sum (current t1 RL2) (current t2 RL1) (a n2)) n2))
 (depends-on (gjs3) (gjs4) (gjs5)))

(name (unhash 38))
;Value: (zero-i RL1)

'(+ (/ (* -1/3 V_s) R_2) (* 1/90000 V_s))
;Value: (+ (/ (* -1/3 V_s) R_2) (* 1/90000 V_s))

(simple-solve
 (up '(+ (/ (* -1/3 V_s) R_2) (* 1/90000 V_s)))
 '(R_2)
 '()
 #t)
#|
(((+ (* 1/90000 R_2 V_s) (* -1/3 V_s)) (eq:0) (V_s R_2)))
|#
;Value: (*solution* () () (((= R_2 30000) (eq:0))) ())

;;; So the equation solver can win, but it is not consulted??
;;;  Ahhhh.  R2 was not a plunk variable!
|#

#|
(initialize-scheduler)

(define-cell V)
(define-cell R1)
(define-cell R2)

(define n1 (node 'n1))
(define n2 (node 'n2))
(define gnd (node 'gnd))

(define VS
  ((voltage-source V 'VS) n1 gnd))

(define RL1
  ((linear-resistor R1 'RL1) n1 n2))
(define RL2
  ((linear-resistor R2 'RL2) n2 gnd))

(cap! n1)
(cap! n2)
(cap! gnd)

(tell! V 'V_s 'gjs1)

(tell! R1 '60000 'gjs2)

;;; Declare R2 to be an unknown worth solving for.
(plunk! R2)

(tell! (potential gnd) 0 'gjs4)

(tell! (thing '(potential n2))
       (/ 'V_s 3)
       'gjs5)

(cpp (inquire R2))
#;
((R2)
 (has-value 30000)
 (because
  (solver)
  ((- ((zero-i RL1) (current t1 RL1)) (current t2 RL1))
   (sum (current t1 RL1) (current t2 RL1) (zero-i RL1))
   RL1)
  ((- ((a n2) (current t1 RL2)) (current t2 RL1)) (sum (current t1 RL2) (current t2 RL1) (a n2)) n2))
 (depends-on (gjs1) (gjs2) (gjs4) (gjs5)))
|#

;;; Full synthesis

(initialize-scheduler)

(define-cell V)
(define-cell R1)
(define-cell R2)

(define n1 (node 'n1))
(define n2 (node 'n2))
(define gnd (node 'gnd))

(define VS
  ((voltage-source V 'VS) n1 gnd))

(define RL1
  ((linear-resistor R1 'RL1) n1 n2))
(define RL2
  ((linear-resistor R2 'RL2) n2 gnd))

(cap! n1)
(cap! n2)
(cap! gnd)

(tell! V 'V_s 'gjs1)

;;; Declare R1 and R2 to be unknowns worth solving for.
(plunk! R1)

(plunk! R2)

(define-cell R1+R2)
(define-cell R1*R2)
(define-cell Parallel)

(sum R1 R2 R1+R2)
(product R1 R2 R1*R2)
(product Parallel R1+R2 R1*R2)

(tell! Parallel 20000 'gjs6)

(tell! (potential gnd) 0 'gjs4)

(tell! (thing '(potential n2))
       (/ 'V_s 3)
       'gjs5)

(cpp (inquire R1))
#;
((R1)
 (has-value 60000)
 (because
  ((+ ((current t1 RL1) (current t2 RL1)) (zero-i RL1))
   (sum (current t1 RL1) (current t2 RL1) (zero-i RL1))
   RL1)
  (RL1)
  ((solver))
  ((/ ((R1*R2) (R1+R2)) (Parallel)) (product (Parallel) (R1+R2) (R1*R2))))
 (depends-on (gjs1) (gjs4) (gjs5) (gjs6) (premise-R2_2)))

 (cpp (inquire R2))
 #;
 ((R2)
 (has-value 30000)
 (because
 ((/ ((v RL2) (current t1 RL2)) (R2)) (product (R2) (current t1 RL2) (v RL2))
 RL2)
 ((+ ((current t1 RL1) (current t2 RL1)) (zero-i RL1))
 (sum (current t1 RL1) (current t2 RL1) (zero-i RL1))
 RL1)
 (RL1)
 ((solver))
 ((/ ((R1*R2) (R1+R2)) (Parallel)) (product (Parallel) (R1+R2) (R1*R2))))
 (depends-on (gjs1) (gjs4) (gjs5) (gjs6) (premise-R2_2)))

;;; Problem! premises not dismissed...

(initialize-scheduler)

(define-cell V)
(define-cell R1)
(define-cell R2)

(define n1 (node 'n1))
(define n2 (node 'n2))
(define gnd (node 'gnd))

(define VS
  ((voltage-source V 'VS) n1 gnd))

(define RL1
  ((linear-resistor R1 'RL1) n1 n2))
(define RL2
  ((linear-resistor R2 'RL2) n2 gnd))

(cap! n1)
(cap! n2)
(cap! gnd)

(tell! V 'V_s 'gjs1)

;;; Declare R1 and R2 to be unknowns worth solving for.
(plunk! R1)

(plunk! R2)

(define-cell R1+R2)
(define-cell R1*R2)
(define-cell Parallel)

(sum R1 R2 R1+R2)
(product R1 R2 R1*R2)
(product Parallel R1+R2 R1*R2)

(tell! Parallel 'Rp 'gjs6)

(tell! (potential gnd) 0 'gjs4)

(tell! (thing '(potential n2))
       (/ 'V_s 'Ratio)
       'gjs5)

(cpp (inquire R1))
#;
((R1)
 (has-value (* Ratio Rp))
 (because
  ((+ ((current t1 RL1) (current t2 RL1)) (zero-i RL1))
   (sum (current t1 RL1) (current t2 RL1) (zero-i RL1))
   RL1)
  (RL1)
  ((solver))
  ((/ ((R1*R2) (R1+R2)) (Parallel)) (product (Parallel) (R1+R2) (R1*R2))))
 (depends-on (gjs1) (gjs4) (gjs5) (gjs6) (premise-R2_2)))

 (cpp (inquire R2))
 #;
((R2)
 (has-value (/ (* Ratio Rp) (+ -1 Ratio)))
 (because
  ((/ ((v RL2) (current t1 RL2)) (R2)) (product (R2) (current t1 RL2) (v RL2))
                                       RL2)
  ((+ ((current t1 RL1) (current t2 RL1)) (zero-i RL1))
   (sum (current t1 RL1) (current t2 RL1) (zero-i RL1))
   RL1)
  (RL1)
  ((solver))
  ((/ ((R1*R2) (R1+R2)) (Parallel)) (product (Parallel) (R1+R2) (R1*R2))))
 (depends-on (gjs1) (gjs4) (gjs5) (gjs6) (premise-R2_2)))
 