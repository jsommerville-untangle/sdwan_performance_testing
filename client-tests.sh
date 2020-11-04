#!/bin/bash

NETPERF_SERV=$(</tmp/flent-server-location)

flent rrul -v -p all_scaled -L 60 -H $NETPERF_SERV -o rrul_all_scaled.png
flent tcp_1up -v -p totals -L 60 -H $NETPERF_SERV -o tcp_up_totals.png
flent tcp_1down -v -p totals -L 60 -H $NETPERF_SERV -o tcp_down_totals.png
flent tcp_bidirectional -v -p totals -L 60 -H $NETPERF_SERV -o tcp_bidirectional_totals.png
flent qdisc_stats -v -L 60 -H $NETPERF_SERV -o qdisc_stats.png
