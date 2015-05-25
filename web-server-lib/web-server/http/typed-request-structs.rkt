#lang typed/racket
(require typed/net/url)

(require/typed/provide "request-structs.rkt"
                       [#:struct header
                                 ([field : Bytes]
                                  [value : Bytes])
                                 #:constructor-name make-header]
                       [headers-assq (-> Bytes (Listof header) (Option header))]
                       [headers-assq* (-> Bytes (Listof header) (Option header))]
                       [#:struct binding
                                 ([id : Bytes])
                                 #:constructor-name make-binding]
                       [#:struct (binding:form binding)
                                 ([value : Bytes])
                                 #:constructor-name make-binding:form]
                       [#:struct (binding:file binding)
                                 ([filename : Bytes]
                                  [headers : (Listof header)]
                                  [content : Bytes])
                                 #:constructor-name make-binding:file]
                       [bindings-assq (-> Bytes (Listof binding) (Option binding))]
                       [bindings-assq-all (-> Bytes (Listof binding) (Listof binding))]
                       [#:struct request
                                 ([method : Bytes]
                                  [uri : url]
                                  [headers/raw : (Listof header)]
                                  [bindings/raw-promise : (Promise (Listof binding))]
                                  [post-data/raw : (Option Bytes)]
                                  [host-ip : String]
                                  [host-port : Number]
                                  [client-ip : String])
                                 #:constructor-name make-request]
                       [request-bindings/raw (-> request (Listof binding))])
