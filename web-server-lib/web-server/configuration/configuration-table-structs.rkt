#lang typed/racket/base
(require ;mzlib/contract
         typed/net/url)
(require web-server/http/response-structs
         web-server/http/typed-request-structs ;web-server/http/request-structs
         #;"../private/util.rkt") ; this seems unused in this file      

; configuration-table = (make-configuration-table nat nat num host-table (listof (cons str host-table)))
(define-struct configuration-table
  ([port : Natural] [max-waiting : Natural] [initial-connection-timeout : Natural] [default-host : host-table] [virtual-hosts : (Listof (Pairof String host-table))]))

; host-table = (make-host-table (listof str) sym messages timeouts paths)
(define-struct host-table ([indices : (Listof String)] [log-format : Symbol] [messages : messages] [timeouts : timeouts] [paths : paths]))

(define-struct host ([indices : (Listof String)] [log-format : Symbol] [log-path : (Option Path-String)] [passwords : (Option Path-String)] [responders : responders] [timeouts : timeouts] [paths : paths]))  

(define-struct responders
  ([servlet : (-> url Any response)]
   [servlet-loading : (-> url Any response)]
   [authentication : (-> url header response)]
   [servlets-refreshed : (-> response)]
   [passwords-refreshed : (-> response)]
   [file-not-found : (-> request response)]
   [protocol : (-> url response)]
   [collect-garbage : (-> response)]))

; messages = (make-messages str^6)
(define-struct messages
  ([servlet : String] [authentication : String] [servlets-refreshed : String] [passwords-refreshed : String] [file-not-found : String] [protocol : String] [collect-garbage : String]))

; timeouts = (make-timeouts nat^5)
(define-struct timeouts ([default-servlet : Natural] [password : Natural] [servlet-connection : Natural] [file-per-byte : Natural] [file-base : Natural]))

; paths = (make-paths str^6)
(define-struct paths ([conf : Path-String] [host-base : Path-String] [log : Path-String] [htdocs : Path-String] [servlet : Path-String] [mime-types : Path-String] [passwords : Path-String]))

(provide (struct-out configuration-table)
         (struct-out host-table)
         (struct-out host)
         (struct-out responders)
         (struct-out messages)
         (struct-out timeouts)
         (struct-out paths))
#;
(provide/contract
 [struct configuration-table
         ([port port-number?]
          [max-waiting exact-nonnegative-integer?]
          [initial-connection-timeout natural-number/c]
          [default-host host-table?]
          [virtual-hosts (listof (cons/c string? host-table?))])]
 [struct host-table 
         ([indices (listof string?)]
          [log-format symbol?]
          [messages messages?]
          [timeouts timeouts?]
          [paths paths?])]
 [struct host 
         ([indices (listof string?)]
          [log-format symbol?]
          [log-path (or/c false/c path-string?)]
          [passwords (or/c false/c path-string?)]
          [responders responders?]
          [timeouts timeouts?]
          [paths paths?])]
 [struct responders
         ([servlet (url? any/c . -> . response?)]
          [servlet-loading (url? any/c . -> . response?)]
          [authentication (url? header? . -> . response?)]
          [servlets-refreshed (-> response?)]
          [passwords-refreshed (-> response?)]
          [file-not-found (request? . -> . response?)]
          [protocol (url? . -> . response?)]
          [collect-garbage (-> response?)])]
 [struct messages
         ([servlet string?]
          [authentication string?]
          [servlets-refreshed string?]
          [passwords-refreshed string?]
          [file-not-found string?]
          [protocol string?]
          [collect-garbage string?])]
 [struct timeouts 
         ([default-servlet number?]
          [password number?]
          [servlet-connection number?]
          [file-per-byte number?]
          [file-base number?])]
 [struct paths 
         ([conf (or/c false/c path-string?)]
          [host-base (or/c false/c path-string?)]
          [log (or/c false/c path-string?)]
          [htdocs (or/c false/c path-string?)]
          [servlet (or/c false/c path-string?)]
          [mime-types (or/c false/c path-string?)]
          [passwords (or/c false/c path-string?)])])
