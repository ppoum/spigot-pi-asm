#!/usr/bin/env bash

make all && time ./spigot-pi | tee pi-computed.txt

/usr/bin/env python3 validate.py