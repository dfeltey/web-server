#lang typed/racket/base
(require ;racket/contract
         racket/list
         racket/runtime-path)

(define-runtime-module-path racket-module-spec racket)
(define mred-module-spec 'mred)

(define default-to-be-copied-module-specs (list racket-module-spec mred-module-spec))

(define-runtime-module-path racket/base-module-spec racket/base)

(define-type Make-Servlet-Namespace
  (->* ()
       (#:additional-specs (Listof (U Resolved-Module-Path Module-Path)))
       Namespace))
                           

(: make-make-servlet-namespace (->* ()
                                    (#:to-be-copied-module-specs (Listof (U Resolved-Module-Path Module-Path)))
                                    Make-Servlet-Namespace))
(define (make-make-servlet-namespace
         #:to-be-copied-module-specs [to-be-copied-module-specs empty])    
  ;; get the names of those modules.
  (: get-name (-> (U Module-Path Resolved-Module-Path) (Option Module-Path)))
  (define (get-name spec)
    (assert
     (if (symbol? spec)
        spec
        (with-handlers ([exn:fail? (lambda _ #f)])
          ((current-module-name-resolver) (assert spec module-path?) #f #f #t)))
     (lambda ([m : Any]) (or (not m) (module-path? m)))))
  (define to-be-copied-module-names
    ((inst map (Option Module-Path) (U Module-Path Resolved-Module-Path)) get-name 
         (append default-to-be-copied-module-specs
                 to-be-copied-module-specs)))
  (lambda (#:additional-specs [additional-specs empty])
    (define server-namespace (current-namespace))
    (define new-namespace (make-base-empty-namespace))
    (define additional-names (map get-name additional-specs))
    (parameterize ([current-namespace new-namespace])
      (namespace-require racket/base-module-spec)
      (for-each (lambda ([name : (Option Module-Path)])
                  (with-handlers ([exn:fail? void])
                    (when name
                      (namespace-attach-module server-namespace name))))
                (append to-be-copied-module-names
                        additional-names))
      new-namespace)))

#;(define make-servlet-namespace/c
  (->* ()
       (#:additional-specs (listof (or/c resolved-module-path? module-path?)))
       namespace?))

(provide Make-Servlet-Namespace
         make-make-servlet-namespace)
#;(provide/contract
 [make-servlet-namespace/c contract?]
 [make-make-servlet-namespace 
  (->* ()
       (#:to-be-copied-module-specs (listof (or/c resolved-module-path? module-path?)))
       make-servlet-namespace/c)])
