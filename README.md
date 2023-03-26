# spigot-pi-asm

## Introduction
This project implements the spigot algorithm used to compute the digits of Pi as outline in [Rabinowitz, S., & Wagon, S. (1995). A Spigot Algorithm for the Digits of π. The American Mathematical Monthly, 102(3), 195–203](https://doi.org/10.2307/2975006). This type of algorithm offers two main advantages over regular algorithms:
1. The algorithm outputs the digits of Pi one (-ish) at a time. This means it can be implemented as a stream.
2. The algorithm does not make use of floats, every operation is done on integers.

The second point makes the algorithm much simpler to implement on older machines, or on low-end ARM CPUs that do not have a FPU and instead rely on a slower, software FP32 implementation.

## Why
No reason, it sounded fun. This project was written in x86-64 assembly, and since most (all?) x86-based CPUs have FPUs, there is no advantage in using the algorithm on this platform. Use cases for streaming the digits of Pi are also somewhat limited, and since the algorithm is slower than more recent ones, it offers no true advantages for this project.

It would most likely also be more efficient to write this program in a higher-level language (like C), and to make use of multi-threading, but where's the fun in that.


## How to use
The number of digits calculated is currently hard-coded in the assembly file. To change how many digits are calculated and printed out, simply change this line: `%define DIGIT_COUNT [Your number here]`. An ELF64 executable can be built using `make all`.

To test the accuracy of the algorithm against known digits of pi, the `test.sh` file can be used. This script automatically compiles and runs the executable, and then compares its output against the first 1,000,000 digits of Pi (provided under the file `pi-million.txt`)
