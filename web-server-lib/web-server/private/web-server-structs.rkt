#lang typed/racket/base
;(require racket/contract)

(: current-server-custodian (Parameterof (Option Custodian)))
(define current-server-custodian (make-parameter #f))

;; make-servlet-custodian: -> custodian
;; create a custodian for the dynamic extent of a servlet continuation
(: make-servlet-custodian (-> Custodian))
(define (make-servlet-custodian)
  (make-custodian (assert (current-server-custodian))))

(provide current-server-custodian make-servlet-custodian)
#;(provide/contract
 [current-server-custodian (parameter/c custodian?)]
 [make-servlet-custodian (-> custodian?)])
