# Script to check radmind status of Mac
echo "#########################################################################"
echo "####    Checking fsdiff and lapply logs. Last lines should match.    ####"
echo "#########################################################################"
echo -ne "fsdiff Last Modification Date: \c" 
ls -l /Library/PSUlog/fsdiff.output | awk '{print $6" "$7" "$8}'
echo -ne "lapply Last Modification Date: \c" 
ls -l /Library/PSUlog/lapply.output | awk '{print $6" "$7" "$8}'
tail -1 /Library/PSUlog/fsdiff.output /Library/PSUlog/lapply.output

echo "#########################################################################"
echo "####    If there are any errors, the line below should be the error  ####"
echo "#########################################################################"
LAST_LINE=`tail -1 /Library/PSUlog/lapply.output| awk '{print $1}'|tr -d ':'`
grep -i -A 1 "$LAST_LINE" /Library/PSUlog/fsdiff.output | tail -1

echo "#########################################################################"
echo "####    Checking ktcheck log for any errors. Sucessful is good.      ####"
echo "#########################################################################"
echo -ne "Last Modification Date: \c" 
ls -l /Library/PSUlog/ktcheck.output | awk '{print $6" "$7" "$8}'
tail /Library/PSUlog/ktcheck.output

read -p "Hit Return to Exit"
