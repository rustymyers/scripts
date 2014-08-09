#!/usr/bin/perl -w
my $spaceRemaining = qx(/bin/df -k | /usr/bin/grep "/"\$ | /usr/bin/awk '{print \$4}');
print $spaceRemaining;
