#lang typed/racket/base
(require typed/racket/unit
         ;racket/contract
         ;web-server/private/util
         web-server/configuration/namespace ;typed
         web-server/configuration/configuration-table-structs) ;typed

(provide
 web-config^)
(define-type Port-Number Natural)
(define-signature
  web-config^
  ([max-waiting : Integer]
   [virtual-hosts : (-> String Integer)]
   [initial-connection-timeout : Integer]
   [port : Port-Number]
   [listen-ip : (Option String)]
   [make-servlet-namespace : Make-Servlet-Namespace])
  #;((contracted
    [max-waiting integer?]
    [virtual-hosts (string? . -> . host?)]
    [initial-connection-timeout integer?]
    [port port-number?]
    [listen-ip (or/c false/c string?)]
    [make-servlet-namespace make-servlet-namespace/c])))
