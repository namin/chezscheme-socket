(define client-pid)

(define client-socket)

(let* ([server-socket-name (tmpnam 0)]
         [server-socket (setup-server-socket server-socket-name)])
   ; fork a child, use it to exec a client Scheme process, and set
   ; up server-side client-pid and client-socket variables.
    (dofork   ; child
      (lambda () 
       ; the child establishes the socket input/output fds as
       ; stdin and stdout, then starts a new Scheme session
        (check 'close (close server-socket))
        (let ([sock (setup-client-socket server-socket-name)])
          (dodup 0 sock)
          (dodup 1 sock))
        (check 'execl (execl4 "/bin/sh" "/bin/sh" "-c" "exec scheme -q"))
        (errorf 'client "returned!"))
      (lambda (pid) ; parent
       ; the parent waits for a connection from the client
        (set! client-pid pid)
        (set! client-socket (accept-socket server-socket))
        (check 'close (close server-socket)))))

(define put ; procedure to send data to client
    (lambda (x)
      (let ([s (format "~s~%" x)])
        (c-write client-socket s 0 (string-length s)))
      (void)))

(define get ; procedure to read data from client
    (let ([buff (make-bytevector 1024 0)])
      (lambda ()
        (let ([n (c-read client-socket buff 0 (bytevector-length buff))])
          (let ([r (list->string (map integer->char (bytevector->u8-list buff)))])
            (printf "client:~%~a~%server:~%" (substring r 0 n)))))))
;; (get)
;; server:
(put '(let ([x 3]) x))
(get)
;; client:
;; 3
;; server:
(terminate-process client-pid)
(exit)
