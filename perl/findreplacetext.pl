#!/usr/bin/perl
# 7.0.1

# my $app_root= '/Applications/Zimbra Desktop';
# my $Preferences = '$app_root/macos/prism/Prism.app/Contents/Resources/defaults/preferences/preferences.js';



use strict;
use warnings;

my $filename = 'prefs.js';

{
   local @ARGV = ($filename);
   local $^I = '.bac';
   while( <> ){
		if( s{pref\("app.update.url", "https://www.zimbra.com/aus/zdesktop2/update.php\?chn=release&ver=7.0.1&bid=10791&bos=macos"\)\;}{pref\("app.update.url", "http://desktopupdates.ucs.psu.edu/macos_intel/zdesktop_7_0_1_b10791_macos_intel.xml"\)\\;}g ) {
         print;
      }
      else {
         print;
      }
   }
}


{
   local @ARGV = ($filename);
   local $^I = '.bac1';
   while( <> ){
		if( s{pref\("app.update.url.manual", "http://www.zimbra.com/products/desktop.html"\)\;}{pref\("app.update.url.manual", "http://kb.its.psu.edu/article/1650"\)\;}g ) {
         print;
      }
      else {
         print;
      }
   }
}

