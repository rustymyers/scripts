#!/bin/sh

#-----------------------------------------------------------------------------
# growl - Send the a message to Mac OS X Growl <http://growl.info> via a
#         Unix shell script.  
#
#         And if this is a Linux or Windows_NT box, use ssh to forward the
#         growl notice to my Mac OS X workstation (taking advantage of
#         previously exchanged ssh so no additional authentication is
#         needed).
#
#         This script should be somewhere in your PATH.  I like to use
#         $HOME/bin for personal scripts, and /usr/local/bin for system
#         wide scripts, with appropriate entries added to PATH.  The script
#         needs to be executable:
#
#             chmod +x $HOME/bin/growl
#
#         The basics for the Growl Applescript came from the Growl
#         documentation at:
#             <http://growl.info/documentation/applescript-support.php>
#-----------------------------------------------------------------------------
# Bob Harris - 2-Jun-2007
#-----------------------------------------------------------------------------


#--- usage -------------------------------------------------------------------
usage()
{
    echo 1>&2 ""
    echo 1>&2 "Usage:  growl [options] \"message to display\"" 
    echo 1>&2 ""
    echo 1>&2 "        -sticky     - Stays on screen until dismissed [Default]."
    echo 1>&2 "        -nosticky   - Goes away after several seconds."
    echo 1>&2 "        -priority n - Priority -2,-1,0,1,2 [Default: 0]"
    echo 1>&2 "        -verylow    - priority [-2]"
    echo 1>&2 "        -moderate   - priority [-1]"
    echo 1>&2 "        -normal     - priority  [0] [Default]"
    echo 1>&2 "        -high       - priority  [1]"
    echo 1>&2 "        -emergency  - priority  [2]"
    echo 1>&2 ""
    echo 1>&2 "    Interesting environment variables:"
    echo 1>&2 "        G_TITLE            - Used as the Growl message title."
    echo 1>&2 "        G_APPLICATION_NAME - Used by Growl to manage a set of"
    echo 1>&2 "                             G_WITH_NAME message configurations."
    echo 1>&2 "                             See System Preferences -> Growl"
    echo 1>&2 "        G_ALL_NAMES        - Used to specify 'ALL' the possible"
    echo 1>&2 "                             G_WITH_NAME values this"
    echo 1>&2 "                             G_APPLICATION_NAME will ever use."
    echo 1>&2 "                             Specify something like:"
    echo 1>&2 "                             G_ALL_NAMES='\"class1\",\"class2\"'"
    echo 1>&2 "                             export G_ALL_NAMES"
    echo 1>&2 "        G_WITH_NAME        - Used by Growl to associate a"
    echo 1>&2 "                             message with a set of Growl"
    echo 1>&2 "                             notification settings, such as"
    echo 1>&2 "                             message style and colors associated"
    echo 1>&2 "                             with different priorities.  See"
    echo 1>&2 "                             System preferences -> Growl"
    echo 1>&2 "                             Specify something like:"
    echo 1>&2 "                             G_WITH_NAME='class2'"
    echo 1>&2 "                             export G_WITH_NAME"
    echo 1>&2 "                             If G_WITH_NAME is not in"
    echo 1>&2 "                             G_ALL_NAMES, nothing will be"
    echo 1>&2 "                             displayed"
    echo 1>&2 "        G_APPLICATION_ICON - Display this application's icon in"
    echo 1>&2 "                             the Growl message (default is"
    echo 1>&2 "                             Terminal.app, as this is a shell"
    echo 1>&2 "                             script generated Growl notice)."
    echo 1>&2 ""
    exit 1
}


#--- defaults ----------------------------------------------------------------
defaults()
{
#
# These 2 variables are used when this script notices that it is on a Linux
# or Windows_NT system, then this script uses ssh to forward the request to
# my Mac OS X workstation.  This assumes that ssh keys have been exchanged
# between the systems so that no passwords are needed.  If you don't know
# what this means, then do a Google search for something like 
# "ssh nopassword key" and you should turn up a number of guides for
# configuring ssh.
#
G_REMOTE="${G_REMOTE:-juggle-mac.us.oracle.com}" # assumes ssh exchanged keys
G_REMOTE_GROWL="${G_REMOTE_GROWL:-bin/growl}"    # growl script remote location

#
# G_APPLICATION_NAME is the name Growl will use in the Growl System
# Preferences to provide defaults for Display, and to collect each of your
# notification classes (See G_ALL_NAMES below).
#
G_APPLICATION_NAME="${G_APPLICATION_NAME:-Shell Script Growl Message}"
#
# G_ALL_NAMES contains a list of all the notification classes to be
# associated with the G_APPLICATION_NAME.  Each notification class can have
# its own default Display, Priority, and Stickness settings in the Growl
# System Preferences.
#
G_ALL_NAMES="${G_ALL_NAMES:-\"Shell Script Growl Message\",\"Growl Message\"}"
#
# The default notification class this message should use, must be in the
# G_ALL_NAMES list above.
#
G_WITH_NAME="${G_WITH_NAME:-Shell Script Growl Message}" # default notification
#
G_TITLE="${G_TITLE:-TSM Check}"         # default title
G_APPLICATION_ICON="${G_APPLICATION_ICON:-01 MakeDMG.app}" # default icon to use
G_STICKY="${G_STICKY:-yes}"                      # default sticky setting
G_PRIORITY="${G_PRIORITY:-0}"                    # default priority (normal)
}


#--- growl -------------------------------------------------------------------
# notify v : Post a notification to be displayed via Growl
#   notify
#     with name string          : name of the notification to display
#     title string              : title of the notification to display
#     description string        : full text of the notification to display
#     application name string   : name of the application posting the
#                                 notification.
#     [image from location location_reference] 
#                               : Location of the image file to use for this
#                                 notification. Accepts aliases, paths and
#                                 file:/// URLs.
#     [icon of file location_reference] 
#                               : Location of the file whose icon should be
#                                 used as the image for this notification.
#                                 Accepts aliases, paths and file:/// URLs.
#                                 e.g. 'file:///Applications'.
#     [icon of application string] 
#                               : Name of the application whose icon should
#                                 be used for this notification.  For
#                                 example, 'Mail.app'.
#     [image Image]             : TIFF Image to be used for the
#                                 notification.
#     [pictImage Picture]       : PICT Image to be used for the
#                                 notification.
#     [sticky boolean]          : whether or not the notification displayed
#                                 should time out. Defaults to 'no'.
#     [priority integer]        : The priority of the notification, from -2
#                                 (low) to 0 (normal) to 2 (emergency).
# 
growl()
{
 typeset description="$*"

 osascript <<EOD
  -- From <http://growl.info/documentation/applescript-support.php>
  --
  tell application "GrowlHelperApp"
     -- Make a list of all the notification types that this script will ever send:
     set the allNotificationsList to {${G_ALL_NAMES}}

     -- Make a list of the notifications that will be enabled by default.      
     -- Those not enabled by default can be enabled later in the 'Applications'
     -- tab of the growl prefpane.
     set the enabledNotificationsList to {"${G_WITH_NAME}"}

     -- Register our script with growl.  You can optionally (as here) set a
     -- default icon for this script's notifications.
     register as application "${G_APPLICATION_NAME}" all notifications allNotificationsList default notifications enabledNotificationsList icon of application "${G_APPLICATION_ICON}"
             
     -- Send a Notification...
     notify with name "${G_WITH_NAME}" title "${G_TITLE}" description "${description}" application name "${G_APPLICATION_NAME}" sticky ${G_STICKY} priority ${G_PRIORITY}

  end tell
EOD
}


#--- main --------------------------------------------------------------------
#{
    if [[ $# = 0 ]]; then
        #
        # No arguments, so give the usage message.
        #
        usage
        exit 1
    fi
    while [[ "X$1" = X-* ]]
    do
        if [[ "X$1" = X-nos* ]]; then
            G_STICKY=no
        elif [[ "X$1" = X-s* ]]; then
            G_STICKY=yes
        elif [[ "X$1" = X-p* ]]; then
            G_PRIORITY="$2"
            G_TITLE="${G_TITLE:-Priority $2}"
            OPTIONS="$OPTIONS $1"
            shift
        elif [[ "X$1" = X-v* ]]; then
            G_PRIORITY="-2"
            G_TITLE="${G_TITLE:-Very Low Priority}"
        elif [[ "X$1" = X-m* ]]; then
            G_PRIORITY="-1"
            G_TITLE="${G_TITLE:-Moderate Priority}"
        elif [[ "X$1" = X-n* ]]; then
            G_PRIORITY="0"
            G_TITLE="${G_TITLE:-Normal Priority}"
        elif [[ "X$1" = X-h* ]]; then
            G_PRIORITY="1"
            G_TITLE="${G_TITLE:-High Priority}"
        elif [[ "X$1" = X-e* ]]; then
            G_PRIORITY="2"
            G_TITLE="${G_TITLE:-Emergency Priority}"
        else
            break;
        fi
        OPTIONS="$OPTIONS $1"
        shift
    done

    #
    # If any of the option variables have not been set yet, then apply the
    # default values now.
    #
    defaults

    UNAME=$(uname)
    if [[ "$UNAME" = Darwin ]]; then
        #
        # I'm assuming this is one of my systems where I have Growl
        # installed.
        #
        growl "$*"
    elif [[ "$UNAME" = *Linux* || "$UNAME" = *Windows_NT* ]]; then
        #
        # Must be one of the development systems I work on, so lets ship
        # this request to my Mac OS X workstation.
        #
        ssh ${G_REMOTE} ${G_REMOTE_GROWL} $OPTIONS "$*"
    else
        #
        # I don't know what this is, so I'll just try to Growl anyway.  It
        # will most likely fail (no osascript would be my guess), but what
        # do I have to loose at this point!
        #
        growl "$*"
    fi
#}
