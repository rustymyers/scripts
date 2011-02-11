#!/usr/bin/perl
#
#   mailer.pl-- A simple program to mail form data to an email address
#
#   Written in 1997 by James Marshall, james@jmarshall.com
#   For the latest, see http://www.jmarshall.com/easy/cgi/
#

# IMPORTANT: MAKE SURE THESE TWO VALUES ARE SET CORRECTLY FOR YOU!
$mailprog= "/usr/sbin/sendmail" ;
$recipient= "rzm931@sunset.southhills.edu" ;      # make sure to \ escape the @

# Get the CGI input variables
%in= &getcgivars ;

# Open the mailing process
open(MAIL, "|$mailprog $recipient")
    || &HTMLdie("Couldn't send the mail (couldn't run $mailprog).") ;

# Print the header information
$ENV{'HTTP_REFERER'} || ($ENV{'HTTP_REFERER'}= "your Web site") ;
print MAIL "Subject: Teacher Course Sign Up\n\n",
           "The following data was entered at $ENV{'HTTP_REFERER'}:\n\n" ;


# Find length of longest field name, for formatting; include space for colon
$maxlength= 0 ;
foreach (keys %in) {
    $maxlength= length if length > $maxlength ;
}
$maxlength++ ;

# Print each CGI variable received by the script, one per line.
# This just prints the fields in alphabetical order.  To define your own
#   order, use something like
#     foreach ('firstname', 'lastname', 'phone', 'address1', ... ) {
foreach (sort keys %in) {

    # If a field has newlines, it's probably a block of text; indent it.
    if ($in{$_}=~ /\n/) {
        $in{$_}= "\n" . $in{$_} ;
        $in{$_}=~ s/\n/\n    /g ;
        $in{$_}.= "\n" ;
    }

    # comma-separate multiple selections
    $in{$_}=~ s/\0/, /g ;

    # Print fields, aligning columns neatly
    printf MAIL "%-${maxlength}s  %s\n", "$_:", $in{$_} ;
}


# Close the process and mail the data
close(MAIL) ;


# Print an HTML response to the user
print <<EOF ;
Content-type: text/html

<html>
<body>
<h3>Your data has been sent.</h3>
</body>
</html>
EOF

exit ;


#-------------- start of &getcgivars() module, copied in -------------

# Read all CGI vars into an associative array.
# If multiple input fields have the same name, they are concatenated into
#   one array element and delimited with the \0 character (which fails if
#   the input has any \0 characters, very unlikely but conceivably possible).
# Currently only supports Content-Type of application/x-www-form-urlencoded.
sub getcgivars {
    local($in, %in) ;
    local($name, $value) ;


    # First, read entire string of CGI vars into $in
    if ( ($ENV{'REQUEST_METHOD'} eq 'GET') ||
         ($ENV{'REQUEST_METHOD'} eq 'HEAD') ) {
        $in= $ENV{'QUERY_STRING'} ;

    } elsif ($ENV{'REQUEST_METHOD'} eq 'POST') {
        if ($ENV{'CONTENT_TYPE'}=~ m#^application/x-www-form-urlencoded$#i) {
            length($ENV{'CONTENT_LENGTH'})
                || &HTMLdie("No Content-Length sent with the POST request.") ;
            read(STDIN, $in, $ENV{'CONTENT_LENGTH'}) ;

        } else { 
            &HTMLdie("Unsupported Content-Type: $ENV{'CONTENT_TYPE'}") ;
        }

    } else {
        &HTMLdie("Script was called with unsupported REQUEST_METHOD.") ;
    }
    
    # Resolve and unencode name/value pairs into %in
    foreach (split(/[&;]/, $in)) {
        s/\+/ /g ;
        ($name, $value)= split('=', $_, 2) ;
        $name=~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge ;
        $value=~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge ;
        $in{$name}.= "\0" if defined($in{$name}) ;  # concatenate multiple vars
        $in{$name}.= $value ;
    }

    return %in ;

}


# Die, outputting HTML error page
# If no $title, use a default title
sub HTMLdie {
    local($msg,$title)= @_ ;
    $title= "CGI Error" if $title eq '' ;
    print <<EOF ;
Content-type: text/html

<html>
<head>
<title>$title</title>
</head>
<body>
<h1>$title</h1>
<h3>$msg</h3>
</body>
</html>
EOF

    exit ;
}

#-------------- end of &getcgivars() module --------------------------
