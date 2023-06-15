
socket.so:
	cc -o3 -shared csocket.c -o csocket.so

clean:
	rm csocket.so
