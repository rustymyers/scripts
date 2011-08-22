#!/usr/bin/python

# Example from:
# http://krypted.com/mac-os-x/interpreting-python/

# Print first argument passed to script

import sys

def helloem():
	print 'Ello ', sys.argv[1]

helloem()