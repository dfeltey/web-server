#lang typed/racket/base
(require #;racket/contract 
         web-server/http/typed-request-structs #;web-server/http/request-structs)

(: TEXT/HTML-MIME-TYPE Bytes)
(define TEXT/HTML-MIME-TYPE #"text/html; charset=utf-8")

(struct response ([code : Number] [message : Bytes] [seconds : Number] [mime : (Option Bytes)] [headers : (Listof header)] [output : (-> Output-Port Void)]))

(: response/full (-> Number Bytes Number (Option Bytes) (Listof header) (Listof Bytes) response))
(define (response/full code message seconds mime headers body)
  (response code message seconds mime
            (list* (make-header #"Content-Length" 
                                (string->bytes/utf-8
                                 (number->string
                                  (for/fold ([len 0])
                                    ([b (in-list body)])
                                    (+ len (bytes-length b))))))
                   headers)
            (lambda (op)
              (for ([b (in-list body)])
                (write-bytes b op)))))

(: response/output (->* ((-> Output-Port Void))
                        (#:code Number
                         #:message Bytes
                         #:seconds Number
                         #:mime-type (Option Bytes)
                         #:headers (Listof header))
                        response))
(define (response/output output
                         #:code [code 200]
                         #:message [message #"Okay"]
                         #:seconds [seconds (current-seconds)]
                         #:mime-type [mime-type TEXT/HTML-MIME-TYPE]
                         #:headers [headers '()])
  (response code message seconds mime-type headers
            output))

(provide (struct-out response)
         response/full
         response/output
         TEXT/HTML-MIME-TYPE)

#;(provide/contract
 [struct response
         ([code number?]
          [message bytes?]
          [seconds number?]
          [mime (or/c false/c bytes?)]
          [headers (listof header?)]
          [output (output-port? . -> . void)])]
 [response/full (-> number? bytes? number? (or/c false/c bytes?) (listof header?) (listof bytes?) response?)]
 [response/output (->* ((-> output-port? void?))
                       (#:code number?
                        #:message bytes?
                        #:seconds number?
                        #:mime-type (or/c bytes? #f)
                        #:headers (listof header?))
                       response?)]
 [TEXT/HTML-MIME-TYPE bytes?])
