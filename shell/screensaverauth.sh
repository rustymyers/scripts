#!/bin/bash

# Allow local admins to auth screen saver
perl -i~backup -pe s/"account    required       pam_group.so no_warn group=admin,wheel fail_safe"/"account    sufficient     pam_group.so no_warn group=admin,wheel fail_safe"/g /etc/pam.d/screensaver