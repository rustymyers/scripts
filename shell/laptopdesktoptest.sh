#!/bin/bash

if sysctl -n hw.model | grep 'Book' ;then
	echo "Laptop"
else
	echo "Desktop"
fi