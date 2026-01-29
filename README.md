# fib
A Zig program that uses GMP to calculate Fibonacci and Lucas numbers. The fast doubling algorithm is used for this purpose.
To build this, you must have Zig master (0.16.0-dev).

## Note for Windows users
Windows users must specify where GMP is installed using `--search-prefix`. If you have MSYS2 installed, you would do this:
```
$ zig build --search-prefix $MINGW_PREFIX
```
