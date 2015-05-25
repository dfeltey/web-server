;; NOTE:
;; Sometimes when a functions has an argument
;; with the same name as a struct/type name
;; then the name of the type becomes no longer in scope
;; requiring a type alias definition


#lang typed/racket/base
(require ;racket/contract
         typed/racket/async-channel)

(struct timer-manager ([thread : Thread] [timer-ch : (Async-Channelof (-> (Listof timer) (Listof timer)))]))
(define-struct timer ([tm : timer-manager] [evt : (Evtof Any)] [expire-seconds : Real] [action : (-> Void)])
  #:mutable)

(define-type Timer timer)

;; start-timer-manager : -> timer-manager?
;; The timer manager thread
(: start-timer-manager (-> timer-manager))
(define (start-timer-manager)
  (: timer-ch (Async-Channelof (-> (Listof timer) (Listof timer))))
  (define timer-ch (make-async-channel))
  (timer-manager
   (thread
    (lambda ()
      (let loop ([timers : (Listof timer) null])
        ;; (printf "Timers: ~a\n" (length timers))
        ;; Wait for either...
        (apply sync
               ;; ... a timer-request message ...
               (handle-evt
                timer-ch
                (lambda ([req : (-> (Listof timer) (Listof timer))])
                  ;; represent a req as a (timer-list -> timer-list) function:
                  ;; add/remove/change timer evet:
                  (loop (req timers))))
               ;; ... or a timer
               (map (lambda ([timer : timer])
                      (handle-evt
                       (timer-evt timer)
                       (lambda (_)
                         ;; execute timer
                         ((timer-action timer))
                         (loop (remq timer timers)))))
                    timers)))))
   timer-ch))

;; Limitation on this add-timer: thunk cannot make timer
;;  requests directly, because it's executed directly by
;;  the timer-manager thread
;; add-timer : timer-manager number (-> void) -> timer
(: add-timer (-> timer-manager Real (-> Void) timer))
(define (add-timer manager msecs thunk)
  (define now (current-inexact-milliseconds))
  (define t
    (timer manager
           (alarm-evt (+ now msecs))
           (+ now msecs)
           thunk))
  ((inst async-channel-put (-> (Listof timer) (Listof timer)))
   (timer-manager-timer-ch manager)
   (lambda (timers)
     (list* t timers)))
  t)

;; revise-timer! : timer msecs (-> void) -> timer
;; revise the timer to ring msecs from now
(: revise-timer! (-> timer Real (-> Void) Void))
(define (revise-timer! timer msecs thunk)
  (define now (current-inexact-milliseconds))
  ((inst async-channel-put (-> (Listof Timer) (Listof Timer)))
   (timer-manager-timer-ch (timer-tm timer))
   (lambda (timers)
     (set-timer-evt! timer (alarm-evt (+ now msecs)))
     (set-timer-expire-seconds! timer (+ now msecs))
     (set-timer-action! timer thunk)
     timers)))

(: cancel-timer! (-> timer Void))
(define (cancel-timer! timer)
  (async-channel-put
   (timer-manager-timer-ch (timer-tm timer))
   (lambda ([timers : (Listof Timer)])
     ((inst remq Timer) timer timers))))

;; start-timer : timer-manager num (-> void) -> timer
;; to make a timer that calls to-do after sec from make-timer's application
(: start-timer (-> timer-manager Real (-> Void) timer))
(define (start-timer tm secs to-do)
  (add-timer tm (* 1000 secs) to-do))

;; reset-timer : timer num -> void
;; to cause timer to expire after sec from the adjust-msec-to-live's application
(: reset-timer! (-> timer Real Any))
(define (reset-timer! timer secs)
  (revise-timer! timer (* 1000 secs) (timer-action timer)))

;; increment-timer! : timer num -> void
;; add secs to the timer, rather than replace
(: increment-timer! (-> timer Real Any))
(define (increment-timer! timer secs)
  (revise-timer! timer
                 (+ (- (timer-expire-seconds timer) (current-inexact-milliseconds))
                    (* 1000 secs))
                 (timer-action timer)))
(define-type Timer-Manager timer-manager)
(provide timer-manager?
         Timer-Manager
         (struct-out timer)
         start-timer-manager
         start-timer
         reset-timer!
         increment-timer!
         cancel-timer!)
#;
(provide/contract
 [timer-manager?
  (-> any/c boolean?)]
 [struct timer ([tm timer-manager?]
                [evt evt?]
                [expire-seconds number?]
                [action (-> void)])]
 [start-timer-manager (-> timer-manager?)]
 [start-timer (timer-manager? number? (-> void) . -> . timer?)]
 [reset-timer! (timer? number? . -> . void)]
 [increment-timer! (timer? number? . -> . void)]
 [cancel-timer! (timer? . -> . void)])

;; --- timeout plan

;; start timeout on connection startup
;; for POST requests increase the timeout proportionally when content-length is read
;; adjust timeout in read-to-eof
;; adjust timeout to starting timeout for next request with persistent connections

;; adjust timeout proportionally when responding
;; for servlet - make it a day until the output is produced
