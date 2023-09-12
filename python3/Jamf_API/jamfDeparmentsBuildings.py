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

def putURL(instance: str, url: str, user: str, password: str, data, raw=False) -> ET.Element:
    jssurl_ = 'https://{0}/JSSResource/{1}'.format(instance, url)
    r_ = requests.put(jssurl_, auth=(user,password), data=data)
    print(r_.content)
    return r_.content
    
def postURL(instance: str, url: str, user: str, password: str, data, raw=False) -> ET.Element:
    jssurl_ = 'https://{0}/JSSResource/{1}/id/0'.format(instance, url)
    print(jssurl_)
    print(data)
    r_ = requests.post(jssurl_, auth=(user,password), data=data)
    print(r_)
    return r_.content

def deleteURL(instance: str, url: str, user: str, password: str, dept_id) -> ET.Element:
    jssurl_ = 'https://{0}/JSSResource/{1}/id/{2}'.format(instance, url, dept_id)
    r_ = requests.delete(jssurl_, auth=(user,password))
    print(r_)
    return r_.content

def getAllDepartments() -> tuple:
    """Gets all Departments in Jamf to create a tuple of all computer IDs
    """
    # All computers
    root = getURL(PROTECT_INSTANCE,"departments", CLIENT_ID, PASSWORD)
    # New computer list
    dept_ids = []
    # Get each computer
    for child in root:
        # print(child.tag)
        if child.tag == "size":
            print("Total number of departments: {0}".format(child.text))
        elif child.tag == "department":
            # print("Computer: {0} ({1})".format(child[1].text,child[0].text))
            try:
                dept_ids.append([child[0].text,child[1].text])
            except:
                print("Failed to add computer id to array: {0}".format(child.tag))
                print(child.text)
                print(child[0].text)
    # Convert to tuple to process faster?
    return tuple(dept_ids)

def newDept(name) -> bool:
    """Creates a new department with name input"""
    data_ = {"name": name}
    data = "<department><name>{0}</name></department>".format(name)
    root = postURL(PROTECT_INSTANCE,"departments", CLIENT_ID, PASSWORD, data, raw=True)
    print(root)
    return True

def getAllBuildings() -> tuple:
    """Gets all buildings in Jamf to create a tuple of all computer IDs
    """
    # All computers
    root = getURL(PROTECT_INSTANCE,"buildings", CLIENT_ID, PASSWORD)
    # New computer list
    depts = []
    # Get each computer
    for child in root:
        # print(child.tag)
        if child.tag == "size":
            print("Total number of buildings: {0}".format(child.text))
        elif child.tag == "building":
            print("Building: {0} ({1})".format(child[1].text,child[0].text))
            try:
                dept_ids = child[0].text
                dept_name = child[1].text
                depts.append([dept_ids, dept_name])
            except:
                print("Failed to add buildling id to array: {0}".format(child.tag))
                print(child.text)
                print(child[0].text)
    # Convert to tuple to process faster?
    return tuple(depts)

def newBuild(name) -> bool:
    """Creates a new department with name input"""
    data_ = {"name": name}
    data = "<building><name>{0}</name></building>".format(name)
    root = postURL(PROTECT_INSTANCE,"buildings", CLIENT_ID, PASSWORD, data, raw=True)
    print(root)
    return True
    

print(getAllBuildings())
exit(0)


buildings = ["UP: Pattee", "UP: Paterno", "UP: Cato 1", "UP: Cato 2", "UP: SPLA", "UP: Davey Lab", "UP: Deike", "UP: Hammond", "UP: Wagner Annex", "UP: Thomas", "UP: Willard"]

# for i in range(82, 93):
#     print(i)
#     root = deleteURL(PROTECT_INSTANCE,"departments", CLIENT_ID, PASSWORD, i)
#     print(root)
for building in buildings:
    print("Adding buildig: '{0}'".format(building))
    if newBuild(building):
        print("Made new building!")

depts = ["L5 Access Services", "L5 Access Services Systems", "L5 Access Services CM", "L5 Access Services AX", "L5 Access Services Common Services", "L5 Access Services ILL", "L5 Acquisitions", "L5 Adaptive Services", "L5 Administration", "L5 Architecture Library", "L5 Business Library and Global News", "L5 Business Office", "L5 Cataloging", "L5 CBDR", "L5 Development", "L5 EMS Library", "L5 Engineering Library", "L5 Facilities", "L5 Gobal Engagement", "L5 Human Resources", "L5 Humanities AH", "L5 Humanities Education and CFB", "L5 Humanities SS", "L5 Life Sciences", "L5 LLS", "L5 LST", "L5 Assessment", "L5 MMC", "L5 MTSS", "L5 PaMS", "L5 Microforms", "L5 PCD", "L5 PRaM", "L5 Receiving", "L5 RePub", "L5 Maps", "L5 RM and IRC", "L5 Scholarly Communications", "L5 Special Collections"]


for dept in depts:
    print("Adding dept: '{0}'".format(dept))
    if newDept(dept):
        print("Made new dept!")


# Get all the computers as a tuple
dept_ids_tuple = getAllDepartments()

# Empty dict for counting each site's computers
site_counts = {}
# Check each ID for the computer Name and add it to the dictionary
for dept_id, dept_name in dept_ids_tuple:
    # print("Checking ID_: {0}".format(id_))
    print("Departments: {0} ({1})".format(dept_name,dept_id))

# writeJsonFile("jamfComputerCounts.json", site_counts)
