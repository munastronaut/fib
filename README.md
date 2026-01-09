# fib
A Zig program that uses GMP to calculate Fibonacci and Lucas numbers. The fast doubling algorithm is used for this purpose.

## Note for Windows users
Windows users must specify where GMP is installed using `--search-prefix`. If you have MSYS2 installed and you use UCRT64, you would do this:
```
$ zig build --search-prefix /ucrt64
```
