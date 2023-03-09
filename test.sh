#!/usr/bin/env bash

make main && time ./main | tee pi-computed.txt

/usr/bin/env python3 validate.py