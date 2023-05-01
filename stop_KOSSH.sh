#!/bin/sh
col=30
eips $col 3 "killing...                    "
lipc-send-event com.lab126.hal powerButtonPressed
sleep 5
cat KOSSH.pid | xargs kill
killall dropbear
lipc-set-prop -i com.lab126.powerd preventScreenSaver 0
sleep 1
eips $((col-5)) 0 "                               "
eips $col 3 "                              "
