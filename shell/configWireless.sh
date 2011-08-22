#!/bin/sh

# Enable the wireless method you need and add the correct variables as needed. The wireless network name should not contain spaces.


# Enter your wireless network name to set the network name you want to connect to. Note: Wireless network name cannot contain spaces.
SSID=

# Set the INDEX variable to the index number you’d like it to be assigned to (leave it as 0 if you do not know what index number to use.)
INDEX=0

# Set the SECURITY variable to the security type of the wireless network (NONE, WEP, WPA, WPA2, WPAE or WPA2E)
# Setting it to NONE means that it's an open network with no encryption.
SECURITY=

# If you've set the SECURITY variable to something other than NONE, set the password here. For example, if you
# are using WPA encryption with a password of "thedrisin", set the PASSWORD variable to thedrisin
PASSWORD=

sudo networksetup -addpreferredwirelessnetworkatindex AirPort $SSID $INDEX $SECURITY $PASSWORD