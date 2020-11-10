#!/bin/bash
cd $1
#Change these to look like this:
flent rrul -p all_scaled -l 60 -H 0.0.0.0 -o rrul_all_scaled.png --control-host $PERF_SRV
flent tcp_1up -p totals -l 60 -H 0.0.0.0 -o tcp_up_totals.png --control-host $PERF_SRV
flent tcp_1down -p totals -l 60 -H 0.0.0.0 -o tcp_down_totals.png --control-host $PERF_SRV
flent tcp_bidirectional -p totals -l 60 -H 0.0.0.0 -o tcp_bidirectional_totals.png --control-host $PERF_SRV
flent qdisc_stats -l 60 -H 0.0.0.0 -o qdisc_stats.png --control-host $PERF_SRV