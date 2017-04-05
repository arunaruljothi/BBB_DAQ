#!/bin/bash
SLOTS=/sys/devices/bone_capemgr.*/slots
PINS=/sys/kernel/debug/pinctrl/44e10800.pinmux/pins
export SLOTS
export PINS
echo BB-BONE-HSADC > $SLOTS
cat $SLOTS
