
  (define apply-safely
    (lambda (proc args)
      (with-handlers ([(lambda (exn) #t)      ; catch any error
                       (lambda (exn)          ; evaluate to a failed test result
                         (cons #f
                               (if (exn? exn)
                                   (exn-message exn)
                                   exn)))])
        (let ([actual (apply proc args)])
          (cons #t actual)))))

  ;; run-experiment :
  ;;  ((a ...) -> b) * (a ...) * b * (b * b -> bool)
  ;;  -> (cons bool b)

  ;; usage: (run-experiment fn args correct-answer equal-answer?)
  ;; Applies fn to args.  Compares the result to correct-answer.
  ;; Returns (cons bool b) where bool indicates whether the
  ;; answer is correct.

  (define run-experiment
    (lambda (fn args correct-answer equal-answer?)
      (let*
          ((result (apply-safely fn args))
           ;; ans is either the answer or the args to eopl:error
           (error-thrown? (not (car result)))
           (ans (cdr result)))

        (cons
         (if (eqv? correct-answer 'error)
             error-thrown?
             (equal-answer? ans correct-answer))
         ans))))

  (define stop-after-first-error (make-parameter #f))
  (define run-quietly (make-parameter #t))

  ;; run-tests! : (arg -> outcome) * (any * any -> bool) * (list-of test)
  ;;             -> unspecified

  ;; where:
  ;; test ::= (name arg outcome)
  ;; outcome ::= ERROR | any

  ;; usage: (run-tests! run-fn equal-answer? tests)

  ;; for each item in tests, apply run-fn to the arg.  Check to see if
  ;; the outcome is right, comparing values using equal-answer?.

  ;; print a log of the tests.

  ;; at the end, print either "no bugs found" or the list of tests
  ;; failed.

  ;; Normally, run-tests! will recover from any error and continue to
  ;; the end of the test suite.  This behavior can be altered by
  ;; setting (stop-after-first-error #t).

  (define (run-tests! run-fn equal-answer? tests)
    (let ((tests-failed '()))
      (for-each
       (lambda (test-item)
         (let ((name (car test-item))
               (pgm (cadr test-item))
               (correct-answer (caddr test-item)))
           (printf "test: ~a~%" name)
           (let* ((result
                   (run-experiment
		     run-fn (list pgm) correct-answer equal-answer?))
                  (correct? (car result))
                  (actual-answer (cdr result)))
             (if (or
                   (not correct?)
                   (not (run-quietly)))
               (begin
                 (printf "~a~%" pgm)
                 (printf "correct outcome: ~a~%" correct-answer)
                 (printf "actual outcome:  ")
                 (pretty-display actual-answer)))
             (if correct?
                 (printf "correct~%~%")
                 (begin
                   (printf "incorrect~%~%")
                   ;; stop on first error if stop-after-first? is set:
                   (if (stop-after-first-error)
                       (error name "incorrect outcome detected"))
                   (set! tests-failed
                         (cons name tests-failed)))))))
       tests)
      (if (null? tests-failed)
          (printf "no bugs found~%")
          (printf "incorrect answers on tests: ~a~%"
            (reverse tests-failed)))))
