#!/usr/bin/python3
import datetime
import requests
import json

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

# url = 'https://{0}/JSSResource/accounts'.format(PROTECT_INSTANCE)
CLIENT_ID = ""
PASSWORD = ""

headers = {'accept': 'application/json'}


# Get the accounts from Jamf 
r = requests.get('https://{0}/JSSResource/accounts'.format(PROTECT_INSTANCE), headers=headers, auth=(CLIENT_ID,PASSWORD))
_response_dict = r.json()
_jamf_groups = _response_dict['accounts']['groups']

# Sort the list of groups and get each of their details
for group in _jamf_groups:
    # print(group)
    r = requests.get('https://{0}/JSSResource/accounts/groupid/{0}'.format(group['id']), headers=headers, auth=(CLIENT_ID,PASSWORD))
    _response_dict = r.json()
    _unit_name = _response_dict['group']['name']
    _users = []
    _user_list = _response_dict['group']['members']
    
    if len(_user_list) > 0:
        print("Admins in group: {}".format(_unit_name))
        for user in _user_list:
            _users.append(user["name"])
        print("\t{0}".format(_users))

    #
    # file_name = "/Users/rzm102/Desktop/JamfGroups/{0}.json".format(response_dict['group']['name'].replace('/','-'))
    # with open(file_name, 'w') as outfile:
    #     json.dump(response_dict, outfile)
