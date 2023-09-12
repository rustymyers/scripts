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
            ex: "policies"
            ex: "policies/id/##"
        and returns an ET.element of the result
    """
    jssurl_ = 'https://{0}/JSSResource/{1}'.format(instance, url)
    r_ = requests.get(jssurl_, auth=(user,password))
    return ET.fromstring(r_.content)

def getPoliciesByID(computer_id: str) -> str:
    """getPoliciesByID takes a policy ID as string and returns Site Name string
    """
    # print("Checking policy ID: {0}".format(policy_id))
    found_record = False
    try_attempts = 10
    root = ""
    while found_record == False:
        if try_attempts > 1:
            # Attempt greater than 10
            try_attempts = try_attempts - 1
        else:
            print("\t10 attempts, Can't get policy text! skipping...")
            return "DELETED"
        try:
            root = getURL(PROTECT_INSTANCE,"policies/id/{0}".format(id_), CLIENT_ID, PASSWORD)

            found_record = True
        except:
            print("\tCan't get policy text! Try, try, again...")
    return root

# exit(0)
def getAllPolicies() -> tuple:
    """Gets all comptuers in Jamf to create a tuple of all policy IDs
    """
    # All policies
    root = getURL(PROTECT_INSTANCE,"policies", CLIENT_ID, PASSWORD)
    # New policy list
    policy_ids = []
    # Get each policy
    for child in root:
        # print(child.tag)
        if child.tag == "size":
            print("Total number of policies: {0}".format(child.text))
        elif child.tag == "policy":
            print("policies: {0} ({1})".format(child[1].text,child[0].text))
            try:
                policy_ids.append(child[0].text)
            except:
                print("Failed to add policy id to array: {0}".format(child.tag))
                print(child.text)
                print(child[0].text)
    # Convert to tuple to process faster?
    return tuple(policy_ids)

# Get all the policies as a tuple
policies_ids_tuple = getAllPolicies()

# Check each ID for the policy Name and add it to the dictionary
for id_ in policies_ids_tuple:
    print("Checking ID_: {0}".format(id_))
    policy = getPoliciesByID(id_)
    textPolicy = ET.tostring(policy, encoding='unicode', method='xml')
    if "besagent" in textPolicy.lower():
        print(textPolicy)
        print(policy[0][0].text)
        print(policy.find('packages'))
        exit(0)

# writeJsonFile("jamfPolicies.json", site_counts)
