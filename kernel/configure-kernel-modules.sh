#!/bin/sh
set -e -o pipefail

# Enable kernel modules for hardware sensors
echo drivetemp | sudo tee /etc/modules-load.d/drivetemp.conf
echo nct6683 | sudo tee /etc/modules-load.d/nct6683.conf
echo "options nct6683 force=1" | sudo tee /etc/modprobe.d/nct6683.conf

# Blacklist some drivers
echo "blacklist hid_logitech_hidpp" | sudo tee /etc/modprobe.d/hid_logitech_hidpp-blacklist.conf
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/nouveau-blacklist.conf
echo "blacklist nova_core" | sudo tee /etc/modprobe.d/nova_core-blacklist.conf
