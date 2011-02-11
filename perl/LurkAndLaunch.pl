#!/usr/bin/perl

########################################################
my $SUAPP                                 = "Software Update\.app";
my $APP_IS_RUNNING              = 0;
########################################################

open(PSOUT, "/bin/ps -awwx |");
while( <PSOUT> ) {
	if( /$SUAPP/ ) {
		$APP_IS_RUNNING = 1;
	}
}
close(PSOUT);

if ( !$APP_IS_RUNNING ) 
{
	unless($ENV{'COMMAND_LINE_INSTALL'}) {
		lurkAndLaunch( 'launchExpr' => "open '/Applications/Utilities/Power Mac G5 System Firmware Updater.app'" );
	}
}
else
{
	our $RESOURCES	= $ARGV[0]."/Contents/Resources";
	our $TARGET		= $ARGV[2];
	our $HOME		= $ENV{'HOME'};
	our $USER		= $ENV{'USER'};
	our $APP		= "/Applications/Utilities/Power Mac G5 System Firmware Updater.app";


	#Only do this if we are installing to the boot volume
	if ($TARGET eq "/")
	{
		#And we're authenticated as root
		if ($< == 0)
		{
			#Go through each item in the startup app array, and find if $APP is in the list already
			my $found = 0;
			my $i = 0;
			while (! $found)
			{
				my $invocation	=	qq{"$RESOURCES/PlistBuddy" } .
									qq{"-c" "print AutoLaunchedApplicationDictionary:$i:Path" } .
									qq{"$HOME/Library/Preferences/loginwindow.plist"};
			
				my $path = `$invocation`;
				my $errorCode = $? >> 8;

				if ($errorCode != 0)
				{
					last;
				}

				chomp $path;
				
				# PlistBuddy returns "Does Not Exist" when we hit the end of the array
				if ($path =~ "Does Not Exist")
				{
					last;
				}
				
				if ($path eq $APP)
				{
					$found = 1;
				}
							
				$i ++;
			}
			
			# If $APP is not already there, add it!
			if (!$found)
			{
				my $invocation = qq{"$RESOURCES/PlistBuddy" } .
					qq{"-c" "add AutoLaunchedApplicationDictionary array" } .
					qq{"-c" "add AutoLaunchedApplicationDictionary:0 dict" } .
					qq{"-c" "cd AutoLaunchedApplicationDictionary:0" } .
					qq{"-c" "add Path string '$APP'" } .
					qq{"-c" "add Hide bool false" } .
					qq{"-c" "add InstallerAdded bool true" } .
					qq{"$HOME/Library/Preferences/loginwindow.plist" };
					
				my $path = `/usr/bin/mktemp -d /private/tmp/install.XXXXXXXX`;
				chomp($path);
				my $ALWIscript = ($path . "/ALWI");

				sysopen(SCRIPT, $ALWIscript, 0x0001 | 0x0200 | 0x0800) or exit 0;
				print SCRIPT "#!/bin/sh\n\n";
				print SCRIPT "$invocation\n\n";
				close SCRIPT;
				
				`/bin/chmod +rx "$path"`;
				`/bin/chmod +rx "$ALWIscript"`;
				`/usr/bin/su -m "$USER" -c "$ALWIscript"`;
				system("/bin/rm", "-rf", "$path");
			}
		}
	}
}

exit 0;

sub lurkAndLaunch {
	use Fcntl;
	my %args = @_;
	my $result = 0;

	# make sure we have 	
	if($args{'launchExpr'}) {
		# Make sure the installer is running at this point
		`/usr/bin/killall -s -m Installer >/dev/null 2>&1`;

		if($? == 0) {
			my $path = `/usr/bin/mktemp -d /private/tmp/install.XXXXXXXX`;
			chomp($path);
			my $lurkScript = ($path . "/lurker");

			if($? == 0) {

				if(sysopen(LURKER, $lurkScript, O_WRONLY | O_EXCL | O_CREAT)) {

					my $scriptData = (
                                                "#!/usr/bin/perl\n" .
                                                "while(0 == system(\"/usr/bin/killall -s -m Installer >/dev/null 2>&1\")) {\n" .
                                                " sleep(2);\n" .
                                                "} \n" .
                                                "system(\"$args{'launchExpr'}\");\n" .
                                                "unlink(\"\$0\");\n"
						);

					print(LURKER $scriptData);

					close(LURKER);

					chmod(oct(500), $lurkScript);

					if(0 == system("$lurkScript >/dev/null 2>&1 &")) {

						$result = 1;;
					}

				} else {

					print(STDERR "error opening temporary file!");
				}
			}
		}
	} 

	return($result);
}
