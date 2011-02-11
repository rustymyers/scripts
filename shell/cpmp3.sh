#! /bin/bash
##
#Copy files from Moodle Folder to 
#QTSS folder.
##

##
#Add Date to Log File before new Logs
#Then Echo if the program worked
##

date 1>>/var/log/cron/piccle.out 
echo $?

##
#Copy all the .mp3's in the Moodle Upload Dir to QTSS Public Streaming Dir
#Output a Log of copied/uncopied files then echo if the program worked
##

cp -vnR /Library/WebServer/mddata/*/MP3/*mp3 /Library/QuickTimeStreaming/MP3/ 
			2>>/var/log/cron/piccle.err 1>>/var/log/cron/piccle.out
echo $?
