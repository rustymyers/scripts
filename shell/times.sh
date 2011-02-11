#!/bin/bash

#Time Zone Setup
systemsetup -settimezone America/New_York

#Set to use Network Time Server clock.psu.edu
systemsetup -setusingnetworktime on
systemsetup -setnetworktimeserver clock.psu.edu

#Update NTP
sudo ntpdate -bvs clock.psu.edu
exit 0