#!/bin/bash

if [ "$(cat /sys/class/power_supply/ADP1/online)" = "1" ]; then
    busctl call net.hadess.PowerProfiles \
        /net/hadess/PowerProfiles \
        org.freedesktop.DBus.Properties \
        Set ssv net.hadess.PowerProfiles ActiveProfile s performance
else
    busctl call net.hadess.PowerProfiles \
        /net/hadess/PowerProfiles \
        org.freedesktop.DBus.Properties \
        Set ssv net.hadess.PowerProfiles ActiveProfile s balanced
fi
