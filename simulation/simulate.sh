#!/bin/bash -e

ghdl -a ../src/iir_filter.vhd
ghdl -a iir_filter_tb.vhd
ghdl -e iir_filter_tb
ghdl -r iir_filter_tb --vcd="audio.vcd" --stop-time=1ms

if [ -z "$DISPLAY" ]; then
    echo Display not set, skipping gtkwave
else
    gtkwave audio.vcd iir_filter.gtkw
fi
