# [Section 4.9 Example: Socket Operations](https://cisco.github.io/ChezScheme/csug9.5/foreign.html#./foreign:h9)

To avoid the error
> Exception in c-write: invalid foreign-procedure argument "(let ((x 3)) x)\n"

- I changed the `c-write` signature in the socket library  in Scheme to take `utf-8` instead of `u8*`, and also adjusted the other parameters to match the C code.

- When using `c-read`, I need to pass in a mutable buffer, so I do that in the client code.

- In the client code, I provide the start parameter as 0 both when calling `c-write` and `c-read`.
