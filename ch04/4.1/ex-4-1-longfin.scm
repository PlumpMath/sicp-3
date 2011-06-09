(define (error reason . args)
      (display "Error: ")
      (display reason)
      (for-each (lambda (arg) 
                  (display " ")
		  (write arg))
		args)
      (newline)
      (scheme-report-environment 5))
;; 4. Metalinguistic Abstraction


;; 4.1 The Metacircular Evaluator
;; 1. To evaluate a combination(a compound expresssion other than a special form), *evaluate the subexpressi;;    ons* and then *apply the value of operator subexpression to the values of the operand subexpression*.
;; 2. To apply a compound procedure to a set of argumnets, evaluate the body of the procedure in a new envir;;    oment. To construct this environment, extend the enviornment part of the procedure object by a frame i;;    n which the formal parameters of the procedure are bound to the arguments to which the procedure is ap;;    plied.

;; 4.1.1 The Core of the Evaluator


;; Eval

(define (my-eval exp env)
  (cond ((self-evaluating? exp) exp)
		((variable? exp) (lookup-variable-value exp env))
		((quoted? exp) (text-of-qutation exp))
		((assignment? exp) (eval-assignment exp env))
		((definition? exp) (eval-definition exp env))
		((if? exp) (eval-if exp env))
		((lambda? exp)
		 (make-procedure (lambda-parameters exp)
						 (lambda-body exp)
						 env))
		((begin? exp)
		 (eval-sequence (begin-actions exp) env))
		((cond? exp) (my-eval (cond->if exp) env))
		((application? exp)
		 (my-apply (my-eval (operator exp) env)
				(list-of-values (operands exp) env)))
		(else
		 (error "Unknown expression type --EVAL"))))

;; Apply

(define (my-apply procedure arguments)
  (cond ((primitive-procedure? procedure)
		 (apply-primitive-procedure procedure arguments))
		((compound-procedure? procedure)
		 (eval-sequence
		  (procedure-body procedure)
		  (extend-environment
		   (procedure-parameters procedure)
		   arguments
		   (procedure-environment procedure))))
		(else
		 (error
		  "Unknown procedure type -- APPLY" procedure))))


;; Procedure arguments

(define (list-of-values exps env)
  (if (no-operands? exps)
	  '()
	  (cons (my-eval (first-operand exps) env)
			(list-of-values (rest-operands exps) env))))

;; Conditionals

(define (eval-if exp env)
  (if (true? (my-eval (if-predicate exp) env))
	  (my-eval (if-consequent exp) env)
	  (my-eval (if-alternative exp) env)))

;; Sequences

(define (eval-sequence exps env)
  (cond ((last-exp? exps) (my-eval (first-exp exps) env))
		(else (my-eval (first-exp exps) env)
			  (eval-sequence (rest-exps exps) env))))

;; Assignments and definitions

(define (eval-assignment exp env)
  (set-variable-value! (assignment-variable exp)
					   (my-eval (assignment-value exp) env)
					   env)
  'ok)

(define (eval-definition exp env)
  (define-variable! (definition-variable exp)
	(my-eval (definition-value exp) env)
	env)
  'ok)

;; ex 4.1

;;ltr version
(define (list-of-values-ltr exps env)
  (if (no-operands? exps)
	  '()
	  (let ((first (my-eval (first-operand exps) env))
			(rest (list-of-values (rest-operands exps) env)))
		(cons first rest))))

;;rtl version
(define (list-of-values-rtl exps env)
  (if (no-operands? exps)
	  '()
	  (let ((rest (list-of-values (rest-operands exps)))
			(first (my-eval (first-operand exps) env)))
		(cons first rest))))

;; 4.1.2 Representing Expressions

;; 3,4,5
(define (self-evaluating? exp)
  (cond ((number? exp) #t)
		((string? exp) #t)
		(else #f)))

;; a,b,c
(define (variable? exp) (symbol? exp))

;; ('quote apple),('quote banana),('quote orange)
(define (quoted? exp)
  (tagged-list? exp 'quote))
(define (text-of-quotation exp) (cadr exp))
(define (tagged-list? exp tag)
  (if (pair? exp)
	  (eq? (car exp) tag)
	  #f))

;; (set! <var> <exp>)
(define (assignment? exp)
  (tagged-list? exp 'set!))
(define (assignment-variable exp) (cadr exp))
(define (assignment-value exp) (caddr exp))

;; (define <var> <val>)
;; (define (<var> <arg>) <body>)
(define (definition? exp)
  (tagged-list? exp 'define))
(define (definition-variable exp)
  (if (symbol? (cadr exp))
	  (cadr exp)
	  (caadr exp)))
(define (definition-value exp)
  (if (symbol? (cadr exp))
	  (caddr exp)
	  (make-lambda (cdadr exp)     ;; arg
				   (cddr exp))))	;; body

(define (lambda? exp) (tagged-list? exp 'lambda))
(define (lambda-parameters exp) (cadr exp))
(define (lambda-body exp) (cddr exp))
(define (make-lambda parameters body)
  (cons 'lambda (cons parameters body)))

;; (if <pred> <exp1> <exp2>)
(define (if? exp) (tagged-list? exp 'if))
(define (if-predicate exp) (cadr exp))
(define (if-consequent exp) (caddr exp))
(define (if-alternative exp)
  (if (not (null? (caddr exp)))
	  (cadddr exp)
	  #f))
(define (make-if predicate consequent alternative)
  (list 'if predicate consequent alternative))

;; (begin (<exp1> <exp2> ...))
(define (begin? exp) (tagged-list? exp 'begin))
(define (begin-actions exp) (cdr exp))
(define (last-exp? seq) (null? (cdr seq)))
(define (first-exp seq) (car seq))
(define (rest-exps seq) (cdr seq))

(define (sequence->exp seq)
  (cond ((null? seq) seq)
		((last-exp? seq) (first-exp seq))
		(else (make-begin seq))))
(define (make-begin seq) (cons 'begin seq))


(define (application? exp) (pair? exp))
(define (operator exp) (car exp))
(define (operands exp) (cdr exp))
(define (no-operands? ops) (null? ops))
(define (first-operand ops) (car ops))
(define (rest-operands ops) (cdr ops))

;; Derived expressions


;; (cond ((<pred1> <exp1>) (<pred2> <exp2>) .. (else <exp-else>)))
(define (cond? exp) (tagged-list? exp 'cond))
(define (cond-clauses exp) (cdr exp))
(define (cond-else-clause? clause)
  (eq? (cond-predicate clause) 'else))
(define (cond-predicate clause) (car clause))
(define (cond-actions clause) (cdr clause))
(define (cond->if exp)
  (expand-clauses (cond-clauses exp)))

(define (expand-clauses clauses)
  (if (null? clauses)
	  #f
	  (let ((first (car clauses))
			(rest (cdr clauses)))
		(if (cond-else-clause? first) ;;(else <exp-else>)
			(if (null? rest)
				(sequence->exp (cond-actions first))
				(error "ELSE clause isn't last -- COND" clauses))
			(make-if (cond-predicate first)
					 (sequence->exp (cond-actions first))
					 (expand-clauses rest))))))

;; ex 4.2

(define (louis-eval exp env)
  (cond ((self-evaluating? exp) exp)
		((variable? exp) (lookup-variable-value exp env))
		((quoted? exp) (text-of-quotation exp))
		((assignment? exp) (eval-assignment exp env))
		((application? exp)
		 (my-apply (my-eval (operator exp) env)
				(list-of-values (operands exp) env)))
		((definition? exp) (eval-definition exp env))
		((if? exp) (eval-if exp env))
		((lambda? exp)
		 (make-procedure (lambda-parameters exp)
						 (lambda-body exp)
						 env))
		((begin? exp)
		 (eval-sequence (begin-actions exp) env))
		((cond? exp) (my-eval (cond->if exp) env))
		(else
		 (error "Unknown expression type --EVAL"))))

;; a. if exp is (define x 3), louis-eval can't determine it is definition.(every special form is also APPLICATION)

;; b.

(define (louis-eval exp env)
  (cond ((self-evaluating? exp) exp)
		((variable? exp) (lookup-variable-value exp env))
		((quoted? exp) (text-of-quotation exp))
		((assignment? exp) (eval-assignment exp env))
		((louis-application? exp)
		 (my-apply (my-eval (louis-operator exp) env)
				(list-of-values (louis-operands exp) env)))
		((definition? exp) (eval-definition exp env))
		((if? exp) (eval-if exp env))
		((lambda? exp)
		 (make-procedure (lambda-parameters exp)
						 (lambda-body exp)
						 env))
		((begin? exp)
		 (eval-sequence (begin-actions exp) env))
		((cond? exp) (my-eval (cond->if exp) env))
		(else
		 (error "Unknown expression type --EVAL"))))

(define (louis-application? exp)
  (tagged-list? exp 'call))
(define (louis-operator exp)
  (cadr exp))
(define (louis-operands exp)
  (cddr exp))

;; ex 4.3

(define (my-eval-ddp exp env)
  (let ((f (get 'eval (car exp))))
	(if (null? f)
		(cond ((self-evaluating? exp) exp)
			  ((variable? exp) (lookup-variable-value exp env))
			  ((application? exp) (my-apply (my-eval (operator exp) env)
											(list-of-values (operands exp) env))))
		(f exp env))))

;;quoted?
(put 'eval 'quote (lambda (exp env)
					(text-of-quotation)))

;;assignment?
(put 'eval 'set! eval-assignment)

;;definition?
(put 'eval 'define eval-definition)

;;if?
(put 'eval 'if eval-if)

;;lambda?
(put 'eval 'lambda (lambda (exp env)
					 (make-procedure (lambda-parameters exp)
									 (lambda-body exp)
									 env)))
;;begin?
(put 'eval 'begin (lambda (exp env)
					(eval-sequence (begin-actions exp) env)))

;;cond?
(put 'eval 'cond (lambda (exp env)
				   (my-eval-ddp (cond->if exp) env)))

;; ex 4.4

(define (eval-and exp env)
  (define (iter exp)
	(if (null? exp)
		#t
		(let ((first (car exp))
			  (rest (cdr exp))
			  (val (my-eval (car exp) env)))
		  (if val
			  (if (null? rest)
				  val
				  (iter rest))
			  #f))))
  (iter (cdr exp)))

(define (eval-or exp env)
  (define (iter exp)
	(if (null? exp)
		#f
		(let ((first (car exp))
			  (rest (cdr exp))
			  (val (my-eval (car exp) env)))
		  (if val
			  val
			  (if (null? rest)
				  #f
				  (iter rest env))))))
  (iter (cdr exp)))


(define (my-eval exp env)
  (cond ((self-evaluating? exp) exp)
		((variable? exp) (lookup-variable-value exp env))
		((quoted? exp) (text-of-quotation exp))
		((assignment? exp) (eval-assignment exp env))
		((definition? exp) (eval-definition exp env))
		((if? exp) (eval-if exp env))
		((lambda? exp)
		 (make-procedure (lambda-parameters exp)
						 (lambda-body exp)
						 env))
		((begin? exp)
		 (eval-sequence (begin-actions exp) env))
		((cond? exp) (my-eval (cond->if exp) env))
		((application? exp)
		 (my-apply (my-eval (operator exp) env)
				(list-of-values (operands exp) env)))
		((and? exp) (eval-and exp env))
		((or? exp) (eval-or exp env))
		(else
		 (error "Unknown expression type --EVAL"))))

(define (and? exp)
  (tagged-list? exp 'and))

(define (or? exp)
  (tagged-list? exp 'or))

;; derived version.[true/false only]

(define (eval-and exp env)
  (define (and->if exp)
	(if (null? exp)
		#t
		(make-if (my-eval (car exp) env) (and->if (cdr exp)) #f)))
  (my-eval (and->if (cdr exp)) env))

(define (eval-or exp env)
  (define (or->if exp)
	(if (null? exp)
		#f
		(make-if (my-eval (car exp) env) #t (or->if (cdr exp)))))
  (my-eval (or->if (cdr exp)) env))

;; ex 4.5

;; (cond ((<pred1> <exp1>) (<pred2> <exp2>) .. (else <exp-else>)))
;; (cond (<test> => <recipient>))
(define (cond? exp) (tagged-list? exp 'cond))
(define (cond-clauses exp) (cdr exp))
(define (cond-else-clause? clause)
  (eq? (cond-predicate clause) 'else))
(define (cond-predicate clause) (car clause))
(define (cond-actions clause) (cdr clause))
(define (cond->if exp)
  (expand-clauses (cond-clauses exp)))
(define (cond-test-clause? caluse)
  (eq? (cadr clause) '=>))
(define (cond-recipient clause)
  (caddr clause))

(define (expand-clauses clauses)
  (if (null? clauses)
	  #f
	  (let ((first (car clauses))
			(rest (cdr clauses)))
		(if (cond-else-clause? first) ;;(else <exp-else>)
			(if (null? rest)
				(sequence->exp (cond-actions first))
				(error "ELSE clause isn't last -- COND" clauses))
			(if (cond-test-clause? first)
				(make-if (cond-predicate first)
						 (my-apply (cond-recipient first) (my-apply (cond-predicate first))))
				(make-if (cond-predicate first)
						 (sequence->exp (cond-actions first))
						 (expand-clauses rest)))))))

;; ex 4.6
(define (my-eval exp env)
  (cond ((self-evaluating? exp) exp)
		((variable? exp) (lookup-variable-value exp env))
		((quoted? exp) (text-of-quotation exp))
		((assignment? exp) (eval-assignment exp env))
		((definition? exp) (eval-definition exp env))
		((if? exp) (eval-if exp env))
		((lambda? exp)
		 (make-procedure (lambda-parameters exp)
						 (lambda-body exp)
						 env))
		((begin? exp)
		 (eval-sequence (begin-actions exp) env))
		((cond? exp) (my-eval (cond->if exp) env))
		((let? exp) (my-eval (let->combination exp) env))
		((and? exp) (eval-and exp env))
		((or? exp) (eval-or exp env))
		((application? exp)
		 (my-apply (my-eval (operator exp) env)
				   (list-of-values (operands exp) env)))
		(else
		 (error "Unknown expression type --EVAL"))))

(define (let? exp)
  (tagged-list? exp 'let))

;; (let ((<var> <exp>) ... (<var> <exp>))
;;    <body>)
;; =>
;; ((lambda (<var> ... <var>)
;;     <body>)
;;   <exp> ... <exp>)

(define (let->combination exp)
  (let ((bindings (cadr exp))
		(body (cddr exp)))
	(cons (make-lambda (map car bindings) body)
		  (map cadr bindings))))

;; ex 4.7

(define (make-let bindings body)
  (list 'let bindings body))
(define (let*->nested-lets exp)
  (let ((body (caddr exp)))
	(define (make bindings)
	  (if (null? bindings) body
		  (make-let (list (car bindings))
					(make (cdr bindings)))))
	(make (cadr exp))))

;; for test
(eval (let*->nested-lets '(let* ((a 1) (b (+ a 1))) (+ a 3))) (scheme-report-environment 5))

;; ex 4.8

;; (let <letvar> ((<var> <exp>) ...) <body>)
;; ((lambda (<var> ...)
;;    <body>)
;;   <exp> ...)

;; (let ((<letvar> (lambda (<letvar> <var> ...)
;;                    (let ((<letvar> (lambda (<exp> ...)
;;                                       (<letvar> <letvar> <exp> ...))))
;;                            <body>))))
;;    (<letvar> <letvar> <exp> ...))

(define (let->combination exp)
  (let* ((var (if (= (length exp) 4) (cadr exp) '()))
		 (bindings (if (= (length exp) 4) (caddr exp) (cadr exp)))
		 (body (if (= (length exp) 4) (cadddr exp) (cddr exp)))
		 (args (map car bindings))
		 (exps (map cadr bindings))
		 (f (make-lambda args body))
		 (wrapped-f (make-lambda (cons var args)
								 (list (make-let (list (list var (make-lambda args
																			  (list (cons var (cons var args))))))
												 body)))))
	(if (null? var)
		(cons f exps)
		(make-let
		 (list (list var wrapped-f))
		 (cons var (cons var exps))))))
		
;; test
(eval
 (let->combination
	   '(let fib-iter ((a 1)
					   (b 0)
					   (count 10))
		  (if (= count 0)
			  b
			  (fib-iter (+ a b) a (- count 1)))))
 (scheme-report-environment 5))


;; ex 4.9

;; (while <pred> <body>)

(define (eval-while exp env)
  (let ((pred (cadr exp))
		(body (caddr body)))
	(if (my-eval pred env)
		(begin
		  (my-eval exp)
		  (eval-while exp env)))))

;; ex 4.10
;; skip


;;4.1.3 Evaluator Data Structures

;; Testing of predicates

(define (true? x) (not (eq? x #f)))
(define (false? x) (eq? x #f))

;; Representing procedures

(define (make-procedure parameters body env)
  (list 'procedure parameters body env))
(define (compound-procedure? p)
  (tagged-list? p 'procedure))

(define (procedure-parameters p) (cadr p))
(define (procedure-body p) (caddr p))
(define (procedure-environment p) (cadddr p))

;; Operations on Environments

(define (enclosing-environment env) (cdr env))
(define (first-frame env) (car env))
(define the-empty-environment '())

(define (make-frame variables values)
  (cons variables values))
(define (frame-variables frame) (car frame))
(define (frame-values frame) (cdr frame))
(define (add-binding-to-frame! var val frame)
  (set-car! frame (cons var (car frame)))
  (set-cdr! frame (cons val (cdr frame))))

(define (extend-environment vars vals base-env)
  (if (= (length vars) (length vals))
	  (cons (make-frame vars vals) base-env)
	  (if (< (length vars) (length vals))
		  (error "Too many arguments supplied" vars vals)
		  (error "Too few arguments supplied" vars vals))))

(define (lookup-variable-value var env)
  (define (env-loop env)
	(define (scan vars vals)
	  (cond ((null? vars)
			 (env-loop (enclosing-environment env)))
			((eq? var (car vars))
			 (car vals))
			(else (scan (cdr vars) (cdr vals)))))
	(if (eq? env the-empty-environment)
		(error "Unbound variable" var)
		(let ((frame (first-frame env)))
		  (scan (frame-variables frame) (frame-values frame)))))
  (env-loop env))

(define (set-variable-value! var val env)
  (define (env-loop env)
	(define (scan vars vals)
	  (cond ((null? vars)
			 (env-loop (enclosing-environment env)))
			((eq? var (car vars))
			 (set-car! vals val))
			(else (scan (cdr vars) (cdr vals)))))
	(if (eq? env the-empty-environment)
		(error "Unbound variable -- SET!" var)
		(let ((frame (first-frame env)))
		  (scan (frame-variables frame) (frame-values frame)))))
  (env-loop env))

(define (define-variable! var val env)
  (let ((frame (first-frame env)))
	(define (scan vars vals)
	  (cond ((null? vars)
			 (add-binding-to-frame! var val frame))
			((eq? var (car vars))
			 (set-car! vals val))
			(else (scan (cdr vars) (cdr vals)))))
	(scan (frame-variables frame) (frame-values frame))))


;; ex 4.11

(define (make-frame variables values)
  (map cons variables values))
(define (frame-variables frame)
  (map car frame))
(define (frame-values frame)
  (map cdr frame))
(define (add-binding-to-frame! var val frame)
  (set-cdr! frame (cons (cons var val) (cdr frame))))

;; ex 4.12

(define (env-loop env action)
  (if (eq? env the-empty-environment)
	  (error "Unbound variable!")
	  (scan (frame-variables frame) (frame-values frame) action)))

(define (scan vars vals action)
  (cond ((null? vars)
		 (env-loop (enclosing-environment env)))
		((eq? var (car vars))
		 (action vars vals))
		(else (scan (cdr vars) (cdr vals)))))
  

(define (ex-lookup-variable-value var env)
  (env-loop env (lambda (vars vals)
				  (cdr vals))))

(define (ex-set-variable-value! var val env)
  (env-loop env (lambda (vars vals)
						  (set-car! vals val))))
  

(define (ex-define-variable! var val env)
  (let ((frame (first-frame env)))
	 (scan (frame-variables frame)
		   (frame-values frame)
		   (lambda (vars vals)
			 (set-car! vals val)))))

;; ex 4.13
;; make-unbound! should remove only the binding in the first frame of the environment. if we try to remove(unbound) 'x' on some environment, it means remove 'x' from environment that we contact.

(define (make-unbound! var env)
  (env-loop env (lambda (vars vals)
				  (set-cdr! (vars (cddr vars)))
				  (set-cdr! (vals (cddr vals))))))

;; 4.1.4 Running the Evaluator as a Program

(define (setup-environment)
  (let ((initial-env
		 (extend-environment (primitive-procedure-names)
							 (primitive-procedure-objects)
							 the-empty-environment)))
	(define-variable! 'true #t initial-env)
	(define-variable! 'false #f initial-env)
	initial-env))

(define (primitive-procedure? proc) (tagged-list? proc 'primitive))
(define (primitive-implementation proc) (cadr proc))
(define primitive-procedures
  (list (list 'car car)
		(list 'cdr cdr)
		(list 'cons cons)
		(list 'null? null?)
		(list '+ +)
		(list '* *)))
(define (primitive-procedure-names)
  (map car primitive-procedures))
(define (primitive-procedure-objects)
  (map (lambda (proc) (list 'primitive (cadr proc)))
	   primitive-procedures))
(define the-global-environment (setup-environment))

(define (apply-primitive-procedure proc args)
  (apply-in-underlying-scheme
   (primitive-implementation proc) args))
(define apply-in-underlying-scheme apply)

(define input-prompt ";;; M-Eval input:")
(define output-prompt ";;; M-Eval value:")
(define (driver-loop)
  (prompt-for-input input-prompt)
  (let ((input (read)))
	(let ((output (my-eval input the-global-environment)))
	  (announce-output output-prompt)
	  (user-print output)))
  (driver-loop))

(define (prompt-for-input string)
  (newline)
  (newline)
  (display string)
  (newline))
(define (announce-output string)
  (newline)
  (display string)
  (newline))

 (define (user-print object)
  (if (compound-procedure? object)
	  (display (list 'compound-procedure
					 (procedure-parameters object)
					 (procedure-body object)
					 '<procedure-env>))
	  (display object)))

(define the-global-environment (setup-environment))

(driver-loop)

;; ex 4.14

(define primitive-procedures
  (list (list 'car car)
		(list 'cdr cdr)
		(list 'cons cons)
		(list 'null? null?)
		(list '+ +)
		(list '* *)
		(list 'map map)))
(define the-global-environment (setup-environment))

;; (driver-loop)

;; ;;; M-Eval input:
;; (map (lambda (x) (+ x 1)) '(1 2 3))
;; (map (lambda (x) (+ x 1)) (quote (1 2 3)))
;; procedure application: expected procedure, given: (procedure (x) ((+ x 1)) (((false true car cdr cons null? + * map) #f #t (primitive #<procedure:mcar>) (primitive #<procedure:mcdr>) (primitive #<procedure:mcons>) (primitive #<procedure:null?>) (primitive #<procedure:+>) (primitive #<procedure:*>) (pri...; arguments were: 1

;;  === context ===
;; /Applications/Racket v5.0.1/collects/racket/mpair.rkt:27:2: mmap
;; stdin::12925: driver-loop
;; /Applications/Racket v5.0.1/collects/racket/private/misc.rkt:74:7
;; /Applications/Racket v5.0.1/collects/r5rs/run.rkt: [running body]

;; map(system ver) requires <procedure>(system ver). not procedure that we made

;; 4.1.5 Data as Programs

(my-eval '(* 5 5) the-global-environment)
;; 25

(my-eval (cons '* (list 5 5)) the-global-environment)
;; 25

;; ex 4.15

;; (define (run-forever) (run-forever))

;; (define (try p)
;;   (if (halts? p p)
;; 	  (run-forever)
;; 	  'halted))


;; if (try try) runs infinitely, (halts? try try) is true.
;; if (try try) stops. (halts? try try) is false

;; 4.1.6 Internal Definitions

;; (define (f x)
;;   (define (even? n)
;; 	(if (= n 0)
;; 		#t
;; 		(odd? (- n 1))))
;;   (define (odd? n)
;; 	(if (= n 0)
;; 		#f
;; 		(even? (- n 1))))
;;   <rest of body of f>)

;; ex 4.16

;; a


(define (lookup-variable-value var env)
  (define (env-loop env)
	(define (scan vars vals)
	  (cond ((null? vars)
			 (env-loop (enclosing-environment env)))
			((eq? var (car vars))
			 (if (eq? (car vals) '*unassigned*)
				 (error "Unassigned variable" var)
				 (car vals)))
			(else (scan (cdr vars) (cdr vals)))))
	(if (eq? env the-empty-environment)
		(error "Unbound variable" var)
		(let ((frame (first-frame env)))
		  (scan (frame-variables frame) (frame-values frame)))))
  (env-loop env))

;; b
(define (filter pred list)
  (define (iter list result)
	(if (null? list)
		result
		(iter (cdr list)
			  (if (pred (car list))
				  (cons (car list) result)
				  result))))
  (iter list '()))
(define (scan-out-defines proc-body)
  (let ((defines (filter definition? proc-body))
		(rest-of-proc (filter (lambda (clause)
								(not (definition? clause))) proc-body)))
	(if (null? defines)
		proc-body
		(let ((bindings (map (lambda (clause)
							   (list (definition-variable clause)
									 ''*unassigned*)) defines))
			  (assignments (map (lambda (clause)
								  (list 'set!
										(definition-variable clause)
										(definition-value clause))) defines)))
		  (list (make-let bindings (append assignments rest-of-proc)))))))

(define qf (make-procedure
			'x
			'((define (my-even? n)
				(if (= n 0)
					#t
					(my-odd? (- n 1))))
			  (define (my-odd? n)
				(if (= n 0)
					#f
					(my-even? (- n 1))))
			  (my-odd? x))
			the-global-environment))

(scan-out-defines (procedure-body qf))

;;c

;; modify when eval
(define (make-procedure parameters body env)
  (list 'procedure parameters (scan-out-defines body) env))

;; modify when apply.
;; (define (procedure-body proc)
;;  (scan-out-defines (caddr proc)))

(define qf2 '(define (f x)
			   (define (adder n)
				 (+ n x))
			   (adder x)))

(my-eval '(let ((x 10)) (+ x 5)) the-global-environment)
(my-eval qf2 the-global-environment)
(my-eval '(f 3) the-global-environment)

;; I suggest installing in (make-procedure). because it called only eval time.
