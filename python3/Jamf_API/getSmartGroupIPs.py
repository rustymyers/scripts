#!/usr/local/bin/python3
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

 
url = 'https://{0}/JSSResource/computergroups'.format(PROTECT_INSTANCE)

headers = {
    'accept': 'application/json',
}

r = requests.get(url, headers=headers, auth=(CLIENT_ID,PASSWORD))
# print(f"Status code: {r.status_code}")

#Store API response in a variable
response_dict = r.json()

#Process Results
# print(response_dict.keys())

repo_dicts = response_dict['computer_groups']
# print(f"Length of groups is: {len(repo_dicts)}")

for group in repo_dicts:
    # print(group)
    if group['is_smart'] == True:
        url = 'https://{1}/JSSResource/computergroups/id/{0}'.format(group['id'],PROTECT_INSTANCE)
        r = requests.get(url, headers=headers, auth=(CLIENT_ID,PASSWORD))
        response_dict = r.json()
        # print(response_dict['computer_group']['criteria'])
        critera_json = response_dict['computer_group']['criteria']
        for critera in critera_json:
            if "IP Address" in critera['name']:
                print("Found IP Address in {0}".format(response_dict['computer_group']['name']))
        
    # for user in response_dict['group']['members']:
    #     # print(user["name"])
    #     user_list_.append(user["name"])
    # print("{0},{1}".format(response_dict['group']['name'], ', '.join(user_list_)))
    # file_name = "/Users/rzm102/Desktop/JamfGroups/{0}.json".format(response_dict['group']['name'].replace('/','-'))
    # with open(file_name, 'w') as outfile:
    #     json.dump(response_dict, outfile)
