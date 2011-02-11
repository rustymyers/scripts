#!/bin/sh
# allow any user to set dvd region code
"$3"/usr/libexec/PlistBuddy -c "Set :rights:system.device.dvd.setregion.initial:class allow" "$3"/etc/authorization