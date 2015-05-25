#lang typed/racket/base
(require ;racket/contract
         racket/match
         "timer.rkt")

(struct connection-manager ([i : (Boxof Integer)] [tm : Timer-Manager]))
(define-struct connection ([id : Integer] [timer : (Option timer)] [i-port : Input-Port] [o-port : Output-Port] [custodian : Custodian] [close? : Boolean])
  #:mutable)

(define-type Connection connection)
(provide (struct-out connection)
         start-connection-manager
         new-connection
         kill-connection!
         adjust-connection-timeout!
         Connection)

#;(provide/contract
 [struct connection
         ([id integer?]
          [timer timer?]
          [i-port input-port?]
          [o-port output-port?]
          [custodian custodian?]
          [close? boolean?])]
 [start-connection-manager
  (-> connection-manager?)]
 [new-connection 
  (-> connection-manager? number? input-port? output-port? custodian? boolean?
      connection?)]
 [kill-connection!
  (connection? . -> . void)]
 [adjust-connection-timeout!
  (connection? number? . -> . void)])

;; start-connection-manager: custodian -> connection-manager
;; calls the timer manager
(: start-connection-manager (-> connection-manager))
(define (start-connection-manager)
  (connection-manager (box 0) (start-timer-manager)))

;; new-connection: connection-manager number i-port o-port custodian -> connection
;; ask the connection manager for a new connection
(: new-connection (-> connection-manager Real Input-Port Output-Port Custodian Boolean connection))
(define (new-connection cm time-to-live i-port o-port cust close?)
  (match-define (connection-manager i tm) cm)
  (define conn
    (make-connection
     ;; The id is just for debugging and isn't normally useful
     0 ;; (begin0 (unbox i) (set-box! i (add1 (unbox i))))
     #f i-port o-port cust close?))
  (define conn-wb (make-weak-box conn))
  (set-connection-timer! 
   conn
   (start-timer tm
                time-to-live
                (lambda () 
                  (cond
                    [(weak-box-value conn-wb)
                     => kill-connection-w/o-timer!]))))
  conn)

;; kill-connection!: connection -> void
;; kill this connection
(: kill-connection! (-> connection Void))
(define (kill-connection! conn)
  #;(printf "K: ~a\n" (connection-id conn))
  (with-handlers ([exn:fail? void])
    (cancel-timer! (assert (connection-timer conn))))
  (kill-connection-w/o-timer! conn))

(: kill-connection-w/o-timer! (-> connection Void))
(define (kill-connection-w/o-timer! conn)  
  (with-handlers ([exn:fail:network? void])
    (close-output-port (connection-o-port conn)))
  (with-handlers ([exn:fail:network? void])
    (close-input-port (connection-i-port conn)))
  (custodian-shutdown-all (connection-custodian conn)))

;; adjust-connection-timeout!: connection number -> void
;; change the expiration time for this connection
(: adjust-connection-timeout! (-> connection Real Any))
(define (adjust-connection-timeout! conn time)
  (increment-timer! (assert (connection-timer conn)) time))
