#!/bin/bash

# Check if the Raspberry Pi is connected to the Internet
if ! ping -c 1 -W 3 google.com > /dev/null; then
    echo "WLAN is down, trying to reconnect..."
    # Restart the WLAN interface
    sudo ifdown wlan0
    sleep 5
    sudo ifup wlan0
fi
