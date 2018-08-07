#!/usr/bin/python
# python script that extract an icon from an OSX file and save it at jpeg
# https://superuser.com/questions/133784/manipulate-mac-os-x-file-icons-from-automator-or-command-line
# https://apple.stackexchange.com/questions/6901/how-can-i-change-a-file-or-folder-icon-using-the-terminal/198714
from AppKit import *
import sys, Cocoa

if len(sys.argv) == 2:
    print "One argument"
    for path in sys.argv[1:]:
        print path
        NSBitmapImageRep.imageRepWithData_(NSWorkspace.sharedWorkspace().iconForFile_(path).TIFFRepresentation()).representationUsingType_properties_(NSJPEGFileType, None).writeToFile_atomically_(path+".jpg", None)
    
elif len(sys.argv) == 3:
    print "Two argument"
    NSWorkspace.sharedWorkspace().setIcon_forFile_options_(Cocoa.NSImage.alloc().initWithContentsOfFile_(sys.argv[1].decode('utf-8')), sys.argv[2].decode('utf-8'), 0) or sys.exit("Unable to set file icon")
    
else:
    print "Get Icon with path to file"
    print "Set Icon with path to icon, path to file"
