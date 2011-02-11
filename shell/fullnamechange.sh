#!/bin/bash
# Set full name of ETC admin account to lower case. This fixes a feature of DeployStudio
sudo dscl . -create /Users/etcadmin RealName "admin"