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

def writeJsonFile(file_name: str, save_text: str) -> None:
    with open(file_name, 'w') as outfile:
        json.dump(save_text, outfile, sort_keys=True, indent=2)
    
def getURL(instance: str, url: str, user: str, password: str) -> ET.Element:
    """getURL takes path after JSSResource as url: 
            ex: "compupters"
            ex: "computers/id/##"
        and returns an ET.element of the result
    """
    jssurl_ = 'https://{0}/JSSResource/{1}'.format(instance, url)
    r_ = requests.get(jssurl_, auth=(user,password))
    return ET.fromstring(r_.content)

def getComputerSite(computer_id: str) -> str:
    """getComputerSite takes a computer ID as string and returns Site Name string
    """
    # print("Checking Computer ID: {0}".format(computer_id))
    found_record = False
    try_attempts = 10
    while found_record == False:
        if try_attempts > 1:
            # Attempt greater than 10
            try_attempts = try_attempts - 1
        else:
            print("\t10 attempts, Can't get computer text! skipping...")
            return "DELETED"
        try:
            root = getURL(PROTECT_INSTANCE,"computers/id/{0}".format(id_), CLIENT_ID, PASSWORD)
            computer_name_ = root[0][1].text
            found_record = True
        except:
            print("\tCan't get computer text! Try, try, again...")
    site_name = root.findall("./general/site")[0][1].text
    return site_name

# exit(0)
def getAllComputers() -> tuple:
    """Gets all comptuers in Jamf to create a tuple of all computer IDs
    """
    # All computers
    root = getURL(PROTECT_INSTANCE,"computers", CLIENT_ID, PASSWORD)
    # New computer list
    computer_ids = []
    # Get each computer
    for child in root:
        # print(child.tag)
        if child.tag == "size":
            print("Total number of computers: {0}".format(child.text))
        elif child.tag == "computer":
            # print("Computer: {0} ({1})".format(child[1].text,child[0].text))
            try:
                computer_ids.append(child[0].text)
            except:
                print("Failed to add computer id to array: {0}".format(child.tag))
                print(child.text)
                print(child[0].text)
    # Convert to tuple to process faster?
    return tuple(computer_ids)

# Get all the computers as a tuple
computer_ids_tuple = getAllComputers()

# Empty dict for counting each site's computers
site_counts = {}
# Check each ID for the computer Name and add it to the dictionary
for id_ in computer_ids_tuple:
    # print("Checking ID_: {0}".format(id_))
    site_name = getComputerSite(id_)
    if site_name == "":
        print("\t{0}".format("No Site Found!"))
    else:
        # print("\tSite Name: {0}".format(site_name))
        try:
            if site_counts[site_name] > 0:
                # print("\t{0}".format("Found Site"))
                site_counts[site_name] += 1
        except:
            # print("\t{0}".format("Making Site"))
            site_counts[site_name] = 1

print("Added all site counts:")
print(site_counts)
writeJsonFile("jamfComputerCounts.json", site_counts)
