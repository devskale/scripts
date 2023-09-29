import requests
import json

post_url = "https://amd2.mooo.com/api/tasks"
#get_url = "https://amd2.mooo.com/api/tasks/"

data = {
    "title": "Learn Python",
    "description": "Learn the basics of Python programming",
    "done": False
}

headers = {
    'Content-Type': 'application/json'
}

# Test POST endpoint
postresponse = requests.post(post_url, data=json.dumps(data), headers=headers)

if postresponse.status_code == 201:
    book = postresponse.json()['task']
    print("Success: Book added successfully. Book data:", book)
else:
    print("Error: Failed to add book. Status code:", postresponse.status_code)

task_id = postresponse.json()['task']['id']

# Test GET endpoint
get_url = f"https://amd2.mooo.com/api/tasks/{task_id}"
getresponse = requests.get(get_url)

if getresponse.status_code == 200:
    book = getresponse.json()['task']
    print("Success: Book retrieved successfully. Book data:", book)
else:
    print("Error: Failed to retrieve book. Status code:", getresponse.status_code)
