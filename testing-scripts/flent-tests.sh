#!/bin/bash
mkdir $1
cd $1
flent rrul -p all_scaled -l 60 -H $PERF_SRV -o rrul_all_scaled.png
flent tcp_1up -p totals -l 60 -H $PERF_SRV -o tcp_up_totals.png
flent tcp_1down -p totals -l 60 -H $PERF_SRV -o tcp_down_totals.png
flent tcp_bidirectional -p totals -l 60 -H $PERF_SRV -o tcp_bidirectional_totals.png
flent qdisc_stats -l 60 -H $PERF_SRV -o qdisc_stats.png