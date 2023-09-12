#!/usr/bin/python3
import datetime
import requests
import json, os
import configparser

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
 
url = 'https://{0}/JSSResource/accounts'.format(PROTECT_INSTANCE)

headers = {
    'accept': 'application/json',
}

r = requests.get(url, headers=headers, auth=(CLIENT_ID,PASSWORD))
# print(f"Status code: {r.status_code}")

#Store API response in a variable
response_dict = r.json()

#Process Results
# print(response_dict.keys())

repo_dicts = response_dict['accounts']['groups']

USER_LIST = {}

for group in repo_dicts:
    url = 'https://{1}/JSSResource/accounts/groupid/{0}'.format(group['id'],PROTECT_INSTANCE)
    r = requests.get(url, headers=headers, auth=(CLIENT_ID,PASSWORD))
    response_dict = r.json()
    # print("Group Name: {}".format(response_dict['group']['name']))
    for user in response_dict['group']['members']:
        # print(user["name"])
        try:
            USER_LIST[user["name"]].append(response_dict['group']['name'])
        except:
            USER_LIST[user["name"]] = [response_dict['group']['name']]

# print(USER_LIST)
for user in USER_LIST:
    print("################")
    print("{0}".format(user))
    print("\t{0}".format(", ".join(USER_LIST[user])))
    print("################")
file_name = "~/Desktop/JamfUserXGroup.txt"

save_text = "Jamf Users X Group {0}\n".format(datetime.datetime.now())

for user in USER_LIST:
    save_text += "################\n"
    save_text += "{0}: {1}\n".format(user, ", ".join(USER_LIST[user]))

with open(file_name, 'w') as outfile:
    json.dump(save_text, outfile)
