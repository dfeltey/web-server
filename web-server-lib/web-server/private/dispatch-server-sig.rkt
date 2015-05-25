#lang typed/racket/base
(require typed/racket/unit
         ;racket/contract
         typed/racket/async-channel
         ;web-server/private/util 
         ;unstable/contract ; this import seems unused
         web-server/private/connection-manager)

;; This isn't exactly right, but close enough for now
(define-type TCP-Listen-Port Natural)

(define-signature dispatch-server^
  ([serve : (->* () (#:confirmation-channel (Option (Async-Channelof Any))) (-> Void))]
   [serve-ports : (-> Input-Port Output-Port (-> Void))])
  #;((contracted
    [serve (->* () (#:confirmation-channel (or/c false/c async-channel?)) (-> void))]
    [serve-ports (input-port? output-port? . -> . (-> void))])))

(define-signature dispatch-server-connect^
  ([port->real-ports : (-> Input-Port Output-Port (Values Input-Port Output-Port))])
  #;((contracted
    [port->real-ports
     (-> input-port? output-port?
         (values input-port? output-port?))])))

(define-signature dispatch-server-config^
  ([port : TCP-Listen-Port]
   [listen-ip : (Option String)]
   [max-waiting : Natural]
   [initial-connection-timeout : Integer]
   [read-request : (-> Connection TCP-Listen-Port (-> Input-Port (Values String String)) (Values Any Boolean))]
   [dispatch : (-> Connection Any Void)])
  #;((contracted
    [port tcp-listen-port?]
    [listen-ip (or/c string? false/c)]
    [max-waiting exact-nonnegative-integer?]
    [initial-connection-timeout integer?]
    [read-request
     (connection? 
      tcp-listen-port?
      (input-port? . -> . (values string? string?))
      . -> .
      (values any/c boolean?))]
    [dispatch 
     (-> connection? any/c void)])))

(provide
 dispatch-server^
 dispatch-server-connect^
 dispatch-server-config^)
