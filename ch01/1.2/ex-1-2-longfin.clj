;;ex 1.9

;; (recur-add 3 5)
;; (inc (recur-add 2 5))
;; (inc (inc (recur-add 1 5)))
;; (inc (inc (inc (recur-add 0 5))))
;; (inc (inc (inc 5)))
;; (inc (inc 6))
;; (inc 7)
;; 8
(defn recur-add [a b]
  (if (= a 0)
    b
    (inc (recur-add (dec a) b))))

;; (tail-recur-add 3 5)
;; (tail-recur-add 2 6)
;; (tail-recur-add 1 7)
;; (tail-recur-add 0 8)
;; 8
(defn tail-recur-add [a b]
  (if (= a 0)
    b
    (tail-recur-add (dec a) (inc b))))

;;ex 1.10

(defn A [x y]
  (cond (= y 0) 0
	(= x 0) (* 2 y)
	(= y 1) 2
	:else (A (- x 1)
		 (A x (- y 1)))))

;; user> (A 1 10)
;; (A 0 (A 1 9))
;; (* 2 (A 1 9))
;; (* 2 (A 0 (A 1 8)))
;; (* 2 (* 2 (A 0 (A 1 7))))
;; (* 2 (* 2 (* 2 (A 0 (A 1 6)))))
;; ...
;; 1024
;; user> (A 2 4)
;; (A 1 (A 2 3))
;; (A 1 (A 1 (A 2 2)))
;; (A 1 (A 1 (A 1 (A 2 1))))
;; (A 1 (A 1 (A 1 2)))
;; (A 1 (A 1 (A 0 (A 1 1))))
;; (A 1 (A 1 (* 2 2)))
;; (A 1 (A 1 4))
;; (A 1 (A 0 (A 1 3)))
;; (A 1 (A 0 (A 0 (A 1 2))))
;; (A 1 (A 0 (A 0 (A 0 (A 1 1)))))
;; (A 1 (A 0 (A 0 (A 0 2))))
;; (A 1 (* 2 (* 2 (* 2 2))))
;; (A 1 16)
;; (A 0 (A 1 15))
;; ...
;; (A 0 (A 0 (A 1 14)))
;; ...
;; 65536
;; user> (A 3 3)
;; 65536

(defn f [n]
  (A 0 n))

;; (f 3)
;; (A 0 3)
;; (* 2 3)
;; (f n) => 2n

(defn g [n]
  (A 1 n))

;; (g 3)
;; (A 1 3)
;; (A 0 (A 1 2)) == (A 0 (g 2))
;; (* 2 (A 0 (A 1 1))) == (* 2 (A 0 (g 1)))
;; (* 2 (* 2 2))
;; 8
;; (g n) => 2^n
 
(defn h [n]
  (A 2 n))
;; (h 3)
;; (A 2 3)
;; (A 1 (A 2 2))
;; (g (A 2 2)) == (g (h 2))
;; (g (A 1 (A 2 1)))
;; (g (g (A 2 1))) == (g (g (h 1)))
;; (g (g 2))
;; (g 4)
;; 16
;; (h n) => ?

;; ex.11
;; f(0) => 0
;; f(1) => 1
;; f(2) => 2
;; f(3) => f(2) + 2f(1) + 3f(0) => 2 + 2*1 + 3*0
;; f(4) => f(3) + 2f(2) + 3f(1) => 4 + 2*2 + 3*1
;; f(5) => f(4) + 2f(3) + 3f(2) => 11 + 2*3 + 3*2
(defn f-recur [n]
  (if (< n 3)
    n
    (+ (f-recur (- n 1))
       (* 2 (f-recur (- n 2)))
       (* 3 (f-recur (- n 3))))))

;; count = 0: a, b, c = f(0), f(1), f(2) 
;; count = 1: a, b, c = f(1), f(2), f(3)
;; count = 2: a, b, c = f(2), f(3), f(4)
;; count = 3: a, b, c = f(3), f(4), f(5)
;; count = 4: a, b, c = f(4), f(5), f(6)
(defn f-iter [n]
  (letfn [(_iter [a b c count]
		 (if (= count n)
		   a
		   (_iter
		    b
		    c
		    (+ c (* 2 b) (* 3 a))
		    (+ count 1)))
		 )]
    (_iter 0 1 2 0)))

;; ex 1.15
(defn cube [x]
  (* x x x))
(defn p [x]
  (- (* 3 x)
     (* 4 (cube x))))
(defn abs [n]
  (if (< n 0)
    (* -1 n)
    n))
(defn sine [angle]
  (if (not (> (abs angle) 0.1))
    angle
    (p (sine (/ angle 3.0)))))

;; (sine 12.15)
;; (p (sine (/ 12.15 3.0)))
;; (p (sine 4.05))
;; (p (p (sine (/ 4.05 3.0))))
;; (p (p (sine 1.35)))
;; (p (p (p (sine (/ 1.35 3.0)))))
;; (p (p (p (p (sine 0.45)))))
;; (p (p (p (p 0.45))))

(defn expt [b n]
  (letfn [(_iter [b counter product]
		 (if (= counter 0)
		   product
		   (_iter
		    b
		    (- counter 1)
		    (* b product))))]
    (_iter b n 1)))

(defn square [n]
  (* n n))
(defn fast-expt [b n]
  (cond (= n 0) 1
	(even? n) (square (fast-expt b (/ n 2)))
	:else (* b (fast-expt b (- n 1)))))
;; ex1.16
(defn fast-expt-iter [b n]
  (letfn [(_iter [b counter product]
		 (cond
		  (= counter 0) product
		  (even? counter) (_iter (* b b)
					 (/ counter 2)
					 product)
		  :else (_iter b
			       (- counter 1)
			       (* product b))))]
    (_iter b n 1)))