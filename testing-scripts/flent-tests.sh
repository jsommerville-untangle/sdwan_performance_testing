#!/bin/bash
cd $1

flent rrul -p all_scaled -l 60 -H $PERF_SRV -o rrul_all_scaled.png
flent tcp_1up -p totals -l 60 -H $PERF_SRV -o tcp_up_totals.png
flent tcp_1down -p totals -l 60 -H $PERF_SRV -o tcp_down_totals.png
flent tcp_bidirectional -p totals -l 60 -H $PERF_SRV -o tcp_bidirectional_totals.png
flent qdisc-stats -l 60 -H $PERF_SRV -o qdisc_stats.png

#Iterate the results and append them into the results.txt file
for f in *.flent.gz
do
    flent $f >> results.txt
done