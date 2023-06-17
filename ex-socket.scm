
;;; sample session using base socket functionality

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
        (check 'execl (execl4 "/bin/sh" "/bin/sh" "-c" "exec chez"))
        (error 'client "returned!"))
      (lambda (pid) ; parent
       ; the parent waits for a connection from the client
        (set! client-pid pid)
        (set! client-socket (accept-socket server-socket))
        (check 'close (close server-socket)))))
(define put ; procedure to send data to client
    (lambda (x)
      (let* ([s (format "~s~%" x)]
             [bv (string->utf8 s)])
        (c-write client-socket bv 0 (bytevector-length bv)))
      (void)))
(define get ; procedure to read data from client
    (let ([buff (make-bytevector 1024)])
      (lambda ()
        (let* ([n (c-read client-socket buff 0 (bytevector-length buff))]
               [bv (make-bytevector n)])
          (bytevector-copy! buff 0 bv 0 n)
          (printf "client:~%~a~%server:~%" (utf8->string bv))))))

(get)
;; client:
;; Chez Scheme Version 9.5.1
;; Copyright 1984-2017 Cisco Systems, Inc.
;; 
;; >
;; server:
(put '(let ((x 3)) x))
(get)
;; client:
;; 3
;; >
;; server:
(terminate-process client-pid)
(exit)


;;; sample session using process port

(define p (transcoded-port (open-process "exec scheme -q") (native-transcoder)))
(pretty-print '(+ 3 4) p)
(read p)
;; 7
(pretty-print '(define (f x) (if (= x 0) 1 (* x (f (- x 1))))) p)
(pretty-print '(f 10) p)
(read p)
;; 3628800
(pretty-print '(exit) p)
(read p)
;;#!eof
(close-port p)
