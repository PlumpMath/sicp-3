;; 3.3.1 Mutable List Structure

(define (ncons x y)
  (let ((new (get-new-pair)))
    (set-car! new x)
    (set-cdr! new y)
    new))


;; ex 3.12

(define (nappend x y)
  (if (null? x)
      y
      (cons (car x) (append (cdr x) y))))

(define (append! x y)
  (set-cdr! (last-pair x) y)
  x)

(define (last-pair x)
  (if (null? (cdr x))
      x
      (last-pair (cdr x))))

(define x (list 'a 'b))
;; [[a] [+]
;;        +-[[b] [nil]]
(define y (list 'c 'd))
;; [[c] [+]
;;        +-[[d] [nil]]
(define z (nappend x y))
;; [[a] [+]]
;;        +-[[b] [+]]
;;                    +-[[c] [+]]
;;                                +-[[d] [nil]]

(cdr x)
;;(b)

(define w (append! x y))
;; (last-pair x)
;; [[b] [nil]]

;;(set-cdr! (last-pair x) y)
;; [[b] [+]]
;;        +=> y

;; x
;; [[a] [+]]
;;        +-[[b] [+]]
;;                    +-[[c] [+]]
;;                                +-[[d] [nil]]

(cdr x)
;; [[b] [+]]
;;        +-[[c] [+]]
;;                   +-[[d] [nil]]

;; ex 3.13

(define (make-cycle x)
  (set-cdr! (last-pair x) x)
  x)

(define z (make-cycle (list 'a 'b 'c)))

;; (list 'a 'b 'c) => x
;; [[a] [+]]
;;        +-[[b] [+]]
;;                    +-[[c] [nil]]

;; (set-cdr! (last-pair x) x)
;; [[a] [+]]
;;        +-[[b] [+]]
;;                    +-[[c] [+]]
;;                                +=> x

;; z is infinite sequence.

;; ex 3.14

(define (mystery x)
  (define (loop x y)
    (if (null? x)
	y
	(let ((temp (cdr x)))
	  (set-cdr! x y)
	  (loop temp x))))
  (loop x '()))

(define v (list 'a 'b 'c 'd))

;; (list 'a 'b 'c 'd) => x1
;; [[a] [+]]
;;        +-[[b] [+]]
;;                    +-[[c] [+]]
;;                               +-[[d] [nil]]

;; '() => y1
;; nil

;; (cdr x1) => temp1
;; [[b] [+]]
;;        +-[[c] [+]]
;;                   +-[[d] [nil]]

;; (set-cdr! x1 y1) => x1'
;; [[a] [+]]
;;        +-[[b] [+]]
;;                    +-[[c] [+]]
;;                               +-[[d] [nil]]

;; temp1 => x2
;; x1' => y2

;; (cdr x2) => temp2
;; [[c] [+]]
;;        +-[[d] [nil]]

;; (set-cdr! x2 y2) => x2'
;; [[b] [+]]
;;        +-[[c] [+]]
;;                   +-[[d] [+]]
;;                               +- y2

;; temp2 => x3
;; x2' => y3
;; ....

;; mystery reverses sequence.

;; v : (a b c d)
;; w : (d c b a)


;; Sharing and identity

(define x (list 'a 'b))
;; [[a] [+]]
;;        +-[[b] [nil]]

(define z1 (cons x x))

;; [[+] [+]]
;;   +   +--+ 
;;   +-----+- x

(define z2 (cons (list 'a 'b) (list 'a 'b)))
;; [[+] [+]]
;;   +   +-[[a] [+]]
;;   +              +-[[b] [nil]]
;;   +-[[a] [+]]
;;              +-[[b] [nil]]

(define (set-to-wow! x)
  (set-car! (car x) 'wow)
  x)
(set-to-wow! z1)
(set-to-wow! z2)

;; ex 3.15

;; z1
;; [[+] [+]]
;;   +   +--+ 
;;   +-----+- [[wow] [+]]
;;                                 +-[[b] [nil]]

;; z2
;; [[+] [+]]
;;   +   +-[[a] [+]]
;;   +              +-[[b] [nil]]
;;   +-[[wow] [+]]
;;                    +-[[b] [nil]]

;; ex 3.16
(define (count-pairs x)
  (if (not (pair? x))
      0
      (+ (count-pairs (car x))
	 (count-pairs (cdr x))
	 1)))

(define count3 '(1 2 3))
;; [[1] [+]]
;;        +-[[2] [+]]
;;                    +-[[3] [nil]]
(count-pairs count3)

(define p (cons 1 2))
;; [[1] [+]]
;;        +-[[p] [nil]]
(define count4 (cons p (cons p 4)))
;; [[+] [+]]
;;   +   +-[[+] [4]]
;;   +          +   
;;   +          +-[[1] [2]
;;   +-[[1] [2]]
(count-pairs count4)

(define p2 (cons p p))
;; [[+] [+]]
;;   ++ +-[[1] [2]]
(define count7 (cons p2 p2))
;; [[+] [+]]
;;   +++
;;        +-[[+] [+]]
;;               +++-[[1] [2]]
(count-pairs count7)

(define counti (cons p p))
(set-cdr! counti counti)

;; [[+] [+]] => counti
;;   +   +-counti
;;   +-[[1] [2]]

;; ex 3.17

(define (contains? list x)
  (cond
   ((null? list) #f)
   ((eq? x (car list)) #t)
   (else (contains? (cdr list) x))))
(define (count-pairs x)
  (let ((founded '()))
    (define (count-pairs-inner x)
      (cond
       ((not (pair? x)) 0)
       ((contains? founded x) 0)
       (else
	(set! founded (cons x founded))
	(+
	 (count-pairs-inner (car x))
	 (count-pairs-inner (cdr x))
	 1))))
    (count-pairs-inner x)))

;; ex 3.18

(define (cycle? x)
  (let ((founded '()))
    (define (inner x)
      (cond
       ((not (pair? x)) #f)
       ((null? x) #f)
       ((contains? founded x) #t)
       (else
	(set! founded (cons x founded))
	(inner (cdr x)))))
    (inner x)))

(define x (cons 1 2))
(cycle? x)
;; #f
(set-cdr! x x)
(cycle? x)
;; #t

(define y (cons 3 x))
(set-cdr! x y)
(cycle? x)
;;#t

(set-car! x x)
(cycle? x)
;;#t

(define z (cons x 3))
(set-car! x z)
(cycle? x)
;;#t

;; ex 3.19

(define (cycle? x)
  (define (safe-cdr x)
    (if (pair? x)
	(cdr x)
	'()))
  (define (iter a b)
    (cond
     ((not (pair? a)) #f)
     ((not (pair? b)) #f)
     ((eq? a b) #t)
     ((eq? a (safe-cdr b)) #t)
     (else (iter (safe-cdr a)
		 (safe-cdr (safe-cdr b))))))
  (iter (safe-cdr x) (safe-cdr (safe-cdr x))))

;; 2nd and 4th
;; 2nd and 5th

;; 3nd and 6th
;; 3nd and 7th

;; ...


;; Mutation is just assignment

(define (ncons x y)
  (define (dispatch m)
    (cond ((eq? m 'car) x)
	  ((eq? m 'cdr) y)
	  (else (error "Undefined opertion -- CONS" m))))
  dispatch)

(define (ncar z) (z 'car))

(define (ncdr z) (z 'cdr))


(define (ncons x y)
  (define (set-x! v) (set! x v))
  (define (set-y! v) (set! y v))
  (define (dispatch m)
    (cond ((eq? m 'car) x)
	  ((eq? m 'cdr) y)
	  ((eq? m 'set-car!) set-x!)
	  ((eq? m 'set-cdr!) set-y!)
	  (else (error "Undefined opertaion -- CONS" m))))
  dispatch)

(define (ncar z) (z 'car))
(define (ncdr z) (z 'cdr))
(define (nset-car! z new-value)
  ((z 'set-car!) new-value)
  z)
(define (nset-cdr! z new-value)
  ((z 'set-cdr!) new-value)
  z)

;; ex 3.20

(define x (ncons 1 2))
;; G = [ncons=(...), ncar=(...), ncdr=(...), x=(E1.dispatch)]
;; E1 = [x=1, y=2,dispatch=(...)]

(define z (ncons x x))
;; G = [ncons=(...), ncar=(...), ncdr=(...), x=(E1.dispatch), z=(E2.dispatch)]
;; E1 = [x=1, y=2,dispatch=(...)]
;; E2 = [x=G.x, y=G.x, dispatch=(...)]

(nset-car! (ncdr z) 17)
(ncar x)
;; G = [ncons=(...), ncar=(...), ncdr=(...), x=(E1.dispatch), z=(E2.dispatch)]
;; E1 = [x=17, y=2,dispatch=(...)]
;; E2 = [x=G.x, y=G.x, dispatch=(...)]


;; 3.3.2 Representing Queues

(define (front-ptr queue) (car queue))
(define (rear-ptr queue) (cdr queue))
(define (set-front-ptr! queue item) (set-car! queue item))
(define (set-rear-ptr! queue item) (set-cdr! queue item))

(define (empty-queue? queue) (null? (front-ptr queue)))

(define (make-queue) (cons '() '()))

(define (front-queue queue)
  (if (empty-queue? queue)
      (error "FRONT called with an empty queue" queue)
      (car (front-ptr queue))))

(define (insert-queue! queue item)
  (let ((new-pair (cons item '())))
    (cond ((empty-queue? queue)
	   (set-front-ptr! queue new-pair)
	   (set-rear-ptr! queue new-pair)
	   queue)
	  (else
	   (set-cdr! (rear-ptr queue) new-pair)
	   (set-rear-ptr! queue new-pair)
	   queue))))

(define (delete-queue! queue)
  (cond ((empty-queue? queue)
	 (error "DELETE! called with an empty queue" queue))
	(else
	 (set-front-ptr! queue (cdr (front-ptr queue)))
	 queue)))

;; ex 3.21

(define q1 (make-queue))
;; (())
(insert-queue! q1 'a)
;; ((a) a)
(insert-queue! q1 'b)
;; ((a b) b)
(delete-queue! q1)
;; ((b) b)
(delete-queue! q1)
;; (() b)

(define (print-queue queue)
  (display (front-ptr queue))
  (display (newline)))

;; ex 3.22

(define (make-queue)
  (let ((front-ptr '())
	(rear-ptr '()))
    (define (empty?)
      (null? front-ptr))
    (define (front)
      (if (empty?)
	  (error "FRONT called with an empty queue")
	  (car front-ptr)))
    (define (insert! item)
      (let ((new-pair (cons item '())))
	(cond ((empty?)
	       (set! front-ptr new-pair)
	       (set! rear-ptr new-pair)
	       dispatch)
	      (else
	       (set-cdr! rear-ptr new-pair)
	       (set! rear-ptr new-pair)
	       dispatch))))
    (define (delete!)
      (cond ((empty?)
	     (error "DELETE! called with an empty queue"))
	    (else
	     (set! front-ptr (cdr front-ptr))
	     dispatch)))
    (define (print)
      (display front-ptr))
    (define (dispatch m)
      (cond ((eq? m 'insert!) insert!)
	    ((eq? m 'delete!) delete!)
	    ((eq? m 'empty?) empty?)
	    ((eq? m 'front) front)
	    ((eq? m 'display) print)
	    (else
	     (error "Unknown operation"))))
    dispatch))

(define q1 (make-queue))
((q1 'insert!) 'a)
((q1 'insert!) 'b)

((q1 'display))
;;(a b)
((q1 'delete!))

((q1 'display))
;;(b)

