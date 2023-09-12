#!/usr/bin/python3
import datetime
import requests
import json

PROTECT_INSTANCE = ""
CLIENT_ID = ""
PASSWORD = ""
# Enter your MDMSERVER
url = 'https://${MDMSERVER}/JSSResource/accounts'

headers = {
    'accept': 'application/json',
}

r = requests.get(url, headers=headers, auth=(CLIENT_ID,PASSWORD))
print(f"Status code: {r.status_code}")

#Store API response in a variable
response_dict = r.json()

#Process Results
print(response_dict.keys())

repo_dicts = response_dict['accounts']['groups']
print(f"Length of groups is: {len(repo_dicts)}")

run_count = 0

for group in response_dict['accounts']['groups']:
    run_count += 1
    url = 'https://{0}/JSSResource/accounts/groupid/{1}'.format(url, group['id'])
    r = requests.get(url, headers=headers, auth=(CLIENT_ID,PASSWORD))
    response_dict = r.json()
    file_name = "/Users/rzm102/Desktop/JamfGroups/{0}.json".format(response_dict['group']['name'].replace('/','-'))
    # Find accounts without VPP permissions
    if "Create Volume Purchasing Administrator Accounts" not in response_dict['group']['privileges']['jss_objects']:
        print(group['name'])
        print("\tNeeds VPP Permissions")
        # new_permissions = ["Create Volume Purchasing Administrator Accounts", "Read Volume Purchasing Administrator Accounts", "Update Volume Purchasing Administrator Accounts", "Delete Volume Purchasing Administrator Accounts"]
        # for perm in new_permissions:
        #     response_dict['group']['privileges']['jss_objects'].append(perm)
    # print(response_dict['group']['privileges']['jss_objects'])
    
    #submit to the JSS API
    # r = requests.put(url, data=response_dict, auth=(CLIENT_ID,PASSWORD))
    # print(r)
    # #
    # # with open(file_name, 'w') as outfile:
    # #     json.dump(response_dict, outfile)
    # if run_count > 2:
    #     exit(0)
    # else:
    #     run_count += 1
    #
