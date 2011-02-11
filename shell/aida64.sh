#!/bin/bash

for i 
do

#tr -cd ' \ r ' $i $i

filename=$i
div=$(grep "\(Finder:\)" $filename | awk '{print $2}' )
div1=$(grep "\(System [V-v]ersion\)"  $filename | tr "." " " | awk '{print $9}' | tr "\c" " ")

if [ "$div" > "9*" ]
then

	## OS 9.x ##
	
	compip1=$(grep "\(IP address:\)" $filename | awk '{print $3}' )
	compname1=$(nslookup "$compip1" 128.118.25.3 2>&1 | grep Name | awk '{print $2}' )
	ipadd1=$(grep "\(IP address:\)" $filename | awk '{print $3}' | sed -e s/.$//g )
	macadd1=$(grep "\(Hardware Address:\)" $filename | awk '{print $3}' | sed -e s/.$//g )
	compmod1=$(grep "\(Model name:\)" $filename | awk '{print $3,$4,$5}' | sed -e s/.$//g | tr "\r" " ")
	ossys1=$(grep "\(System:\)" $filename | awk '{print $2}' | sed -e s/.$//g )
	mem1=$(grep "\(Built-in memory:\)" $filename | awk '{print $3,$4}' | sed -e s/.$//g )
	proc1=$(grep "\(Machine speed:\)" $filename | awk '{print $3,$4}' | sed -e s/.$//g )
	biosrev1=$(grep "\(Boot ROM version:\)" $filename | awk '{print $4}' | sed -e s/.$//g )


	echo -e "$filename ; $compname1 ; $ipadd1 ; $macadd1 ; $compmod1 ; $ossys1 ; $mem1 ; $proc1 ; $biosrev1 ;"
	
	
elif [ "$div1" = "2" ]
then

	## OS X 10.2##
	
	compip=$(grep "\(IP   \)" $filename | awk '{print $4}' )
	compname=$(nslookup "$compip" 128.118.25.3 2>&1 | grep Name | awk '{print $2}' )
	ipadd=$(grep "\(IP   \)" $filename | awk '{print $4}')
	macadd=$(grep "\(Ethernet address\)" $filename | awk '{print $5}' | tr "\n" " ")
	compmod=$(grep "\(Machine model\)" $filename | awk '{print $5}')
	ossys=$(grep "\(System version\)" $filename | awk '{print $5,$6,$7,$8,$9}')
	mem=$(grep "\(DIMM[0-29]/J[0-29]\)" $filename | tr "
	" " " )
	hdd=$(grep "\(Disk Size\)" $filename | awk '{print $5,$6}' | sed -e s/.$//g | tr "\n" " ")
	proc=$(grep "\(Machine speed\)" $filename | awk '{print $5,$6}' )
	biosrev=$(grep "\(Boot ROM info\)" $filename | awk '{print $6}' )
	
	##The Users Information for OS X Only##
	#userid=$(grep "\(User name\)" $filename | awk '{print $7}' | tr "( )" " " )
	#usercat=$(finger "$userid"@psu.edu ) 

	echo -e "$filename ; $compname ; $ipadd ; $macadd ; $compmod ; $ossys ; $mem ; $proc ; $biosrev ; $hdd "
	#$usercat
	

elif [ "$div1" = "3" ]
then

	## OS X 10.3##

	compip=$(grep "\(IP Address:\)" $filename | awk '{print $3}' | tr "\\" " ")
	compname=$(nslookup "$compip" 128.118.25.3 2>&1 | grep Name | awk '{print $2}' )
	ipadd=$(grep "\(IP Address:\)" $filename | awk '{print $3}' | tr "\\" " ")
	macadd=$(grep "\(Ethernet Address:\)" $filename | awk '{print $3}' | tr "\\" " ")
	compmod=$(grep "\(Machine Model:\)" $filename | awk '{print $5,$6,$7}')
	ossys=$(grep "\(System Version:\)" $filename | awk '{print $5,$6,$7,$8,$9}')
	mem=$(grep "\(Size:\)" $filename | awk '{print $4,$5}' | tr "
	" " " )
	hdd=$(grep "\(Capacity:\)" $filename | awk '{print $4,$5}' | tr "
	" " " )
	proc=$(grep "\(CPU Speed:\)" $filename | awk '{print $3,$4}' )
	biosrev=$(grep "\(Boot ROM Version:\)" $filename | awk '{print $4}' )
	
	##The Users Information for OS X Only##
	#userid=$(grep "\(User Name:\)" $filename | awk '{print $3}' | tr "( )" " " )
	#usercat=$(finger "$userid"@psu.edu ) 

	echo -e "$filename ; $compname ; $ipadd; $macadd ; $compmod ; $ossys ; $mem ; $proc ; $biosrev ; $hdd " 
	#$usercat


else

echo "$filename: No Version Found"


fi
done

##
# Written By Russell Myers with help from Bill Burns, Paul Mazza III, and Cindy.
##
