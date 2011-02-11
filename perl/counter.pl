#!/usr/local/bin/perl
# A simple text-based hit counter
# Doug Steinwand - dzs@iname.com
# http://www.abiglime.com/webmaster

# useage:
#  hitcounter.pl page_name
#   -- this option increments the hit count for the specified page
# or
#  hitcounter.pl -summary
#   -- creates a html table summarizing hits from all pages
#

# location and name for the log file
$LOGFILE="/home/dzs/1104/count.txt";

# read the parameter
$param=shift @ARGV;

if (lc $param eq "-summary") {
    display_summary();
} elsif (length $param) {
    print increase_hit($param);
} else {
    print "Usage: hitcounter.pl pagename\n";
}

exit 0;

# displays a summary of all the pages
sub display_summary {
    open F, $LOGFILE or my_die("Can't open $LOGFILE: $!\n");
    print "<h2>Summary</h2><table border=1>";
    while (<F>) {
	($page,$count)=split(/\s+/);
	print "<tr><td>$page</td><td>".(int $count)."</td></tr>\n";
    }
    close F;
    print "</table><i>Generated ",
	(scalar localtime(time)),"</i><br>";
}

# increments the hit count for the given page
sub increase_hit {
    my ($whichpage)=shift;

    # local variables
    my ($count,$pos);

    # open or create the file
    open F, "+<$LOGFILE"
	or open F, ">$LOGFILE" 
	    or my_die("Can't create $LOGFILE: $!\n");
    # lock the file
    flock F, 2;

    $count=0; $pos=0;
    # find the page name
    while(<F>) {
	($page,$count)=split(/\s+/);	
	last if ($whichpage eq $page);
	$pos=tell F;
	$count=0;
    }
    # increment the count
    $count++;

    # rewind to start of the line
    seek F, $pos, 0;

    # write the data
    printf F "%s %9.9d\n", $whichpage, $count;
    close F;

    # return the count without leading 0's
    return int($count);
}
	    
sub my_die {
    print "<br>Error: @_<br>";
    exit 1;
}