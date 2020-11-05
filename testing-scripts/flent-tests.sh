#!/bin/bash

flent rrul -p all_scaled -L 60 -H $PERF_SRV -o rrul_all_scaled.png
flent tcp_1up -p totals -L 60 -H $PERF_SRV -o tcp_up_totals.png
flent tcp_1down -p totals -L 60 -H $PERF_SRV -o tcp_down_totals.png
flent tcp_bidirectional -p totals -L 60 -H $PERF_SRV -o tcp_bidirectional_totals.png
flent qdisc_stats -L 60 -H $PERF_SRV -o qdisc_stats.png