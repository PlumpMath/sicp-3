; example 1.1

10

(+ 5 3 4)

(- 9 1)

(/ 6 2)

(+ (* 2 4) (- 4 6)

(def a 3)

(def b (+ a 1))

(+ a b (* a b))

(= a b)

(if (and (> b a) (< b (* a b)))
    b
    a)

(cond (= a 4) 6
      (= b 4) (+ 6 7 a)
      ; else 25 ;; clojure에서 else에 해당하는 것이 뭔지 모르겠네요.
      )

(+ 2 (if (> b a) b a))

(* (cond (> a b) a
         (< a b) b
         ; else -1
         )
   (+ a 1)) 

