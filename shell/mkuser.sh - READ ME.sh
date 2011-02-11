I'm back!
Thanks for your update Bertrand! I took what you did and added it, plus a little dash of checking userID's too! Here is the new script. So far, I have tested it very successfully. Email me if you have any problems running it or any questions I might be able to help with...rustymyers@gmail.com

I also added the ability to run it from single user mode, should you need to use it there. I bet there is an easier way to check if your in singleuser mode, but I decided just to ask.
I added the dsexport command to check existing userID's in the script so you don't have to exit. It also cleans its self afterwards.
I tried to make most of the checks functions.
There is no need to create the user home folder in this script because the system creates it when you log into the account. 
You don't see the user account in the login window if you use a list style, unless restarting. Change it to the username and password style to type it in and log in without restart. Once you log in the first time, you can change it back to list style, or you can just restart.
Some caveats to this script. It does not create a computer name, you will have to do that in Sharing prefrences. It does not set up auto-login like the setup assistant does. It does not give the user account a picture like setup assistant does.

I will be pushing it out to all my new computers to make user account creation easier, and so I don't have to go through the setup assistant every time I get a new computer. Hope this helps someone else!

If you want to use this in single user mode on a brand new machine, you must also mount the usb drive to copy it. To do so, follow these directions:

Create the mount point: 
mkdir /Volumes/Foo
Determine what disk to mount, probably /dev/disk1s1 
ls /dev/disk*
Mount usb drive /dev/disk1s1 to /Volumes/Foo. the hfs setting is only if your usb drive is formated for HFS, if it is fat32, change it to msdos
mount -t hfs /dev/disk1s1 /Volumes/Foo