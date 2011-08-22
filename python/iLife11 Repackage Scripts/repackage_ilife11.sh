#!/bin/bash


SRCVOL="$1"
if [ ! -d "$SRCVOL" ]; then
    echo "Usage: "`basename "$0"`" /Volumes/iLife\\ \\'11\\ Install\\ DVD"
    exit 1
fi

PKGSRC="${SRCVOL%/}/Installer/Packages"
PKGNAME=`date +"iLife11-%Y%m%d.pkg"`


echo "* Checking media"

if [ ! -f "$PKGSRC/iLife.pkg" ]; then
    echo "'$SRCVOL' is not an iLife '11 installer DVD"
    exit 1
fi


echo "* Expanding iLife base package"

rm -rf iLife_pkg
pkgutil --expand "$PKGSRC/iLife.pkg" iLife_pkg
if [ $? -ne 0 ]; then
    echo "Package expansion failed!"
    exit 1
fi


echo "* Modifying Distribution"

./flatten_dist.py iLife_pkg/Distribution
if [ $? -ne 0 ]; then
    echo "Distribution modification failed!"
    exit 1
fi


echo "* Expanding sub-packages"

for pkg in "$PKGSRC"/*.pkg; do
    pkgname=`basename "$pkg"`
    if [ "$pkgname" != iLife.pkg ]; then
        echo "Expanding $pkgname..."
        pkgutil --expand "$pkg" "iLife_pkg/$pkgname"
        if [ $? -ne 0 ]; then
            echo "Package expansion failed!"
            exit 1
        fi
    fi
done


echo "* Flattening packge"

pkgutil --flatten iLife_pkg "$PKGNAME"
if [ $? -ne 0 ]; then
    echo "Flattening failed!"
    exit 1
fi

open -R "$PKGNAME"
rm -rf iLife_pkg


echo "* Done"
