#!/usr/bin/python3
import datetime
import requests
import json, os
import configparser
from xml.etree import ElementTree as ET

CONFIG_FILE_LOCATIONS = ['jamfapi.cfg',os.path.expanduser('~/jamfapi.cfg'),'/etc/jamfapi.cfg']
CONFIG_FILE = ''
# Parse Config File
CONFPARSER = configparser.ConfigParser()
for config_path in CONFIG_FILE_LOCATIONS:
    if os.path.exists(config_path):
        print("Found Config: {0}".format(config_path))
        CONFIG_FILE = config_path

if CONFIG_FILE == "":
    config_ = configparser.ConfigParser()
    config_['jss'] = {}
    config_['jss']['username'] = "username"
    config_['jss']['password'] = "password"
    config_['jss']['server'] = "server"
    print(config_)
    with open('jamfapi.cfg', 'w') as configfile:
        config_.write(configfile)
    print("Config File Created. Please edit jamfapi.cfg and run again.")
    
    print("No Config File found!")
    exit(0)

# Read local directory, user home, then /etc/ for besapi.conf
CONFPARSER.read(CONFIG_FILE)

# If file exists
# Get config
CLIENT_ID = CONFPARSER.get('jss', 'username')
PASSWORD = CONFPARSER.get('jss', 'password')
PROTECT_INSTANCE = CONFPARSER.get('jss', 'server')

url = 'https://{0}/JSSResource/mobiledevices'.format(PROTECT_INSTANCE)

r = requests.get(url, auth=(CLIENT_ID,PASSWORD))
# print(f"Status code: {r.status_code}")
# All computers
root = ET.fromstring(r.content)

# New computer list
computer_ids = []

# Get each computer
for child in root:
    # print(child.tag)
    if child.tag == "size":
        print("Size of mobiledevices: {0}".format(child.text))
    elif child.tag == "computer":
        print("mobiledevices: {0} ({1})".format(child[1].text,child[0].text))
        computer_ids.append(child[0].text)

site_counts = {}

for id_ in computer_ids:
    url = 'https://{0}/JSSResource/mobiledevices/id/{1}'.format(PROTECT_INSTANCE,id_)
    r = requests.get(url, auth=(CLIENT_ID,PASSWORD))
    root = ET.fromstring(r.content)
    computer_name_ = root[0][1].text
    #'/computer/general/site/name.text()
    site_name = root.findall("./general/site")[0][1].text
    if site_name == "":
        print("No Site found!")
    else:
        # print(site_name)
        try:
            if site_counts[site_name] > 0:
                # print("Found site")
                site_counts[site_name] += 1
        except:
            # print("Making Site")
            site_counts[site_name] = 1

print(site_counts)
    
