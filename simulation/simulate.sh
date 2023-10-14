#!/bin/bash

ghdl -a ../src/iir_filter.vhd
ghdl -a iir_filter_tb.vhd
ghdl -e iir_filter_tb
ghdl -r iir_filter_tb --vcd="audio.vcd" | head -100 | tee audio.log

cut -d" " -f4 audio.log | grep -v meta > audio.dat

gnuplot -e 'plot "audio.dat" with points; pause 5'
gtkwave audio.vcd
