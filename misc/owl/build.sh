#!/bin/bash
../../../beebasm/beebasm -v -i ../../../Beeb1MHzBusFpga/misc/owl/owl.asm
truncate -s 256 owl.bin
od -An -tx1 -w1 -v owl.bin  | tr -d " " > owl.dat
