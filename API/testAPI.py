import requests

response = requests.get('https://amd2.mooo.com/api/tasks')

if response.status_code == 200:
    print(response.json())
else:
    print('Error:', response.status_code)
