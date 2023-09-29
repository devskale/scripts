import requests

response = requests.get('http://amd2.mooo.com/api/tasks/2')

if response.status_code == 200:
    print(response.json())
else:
    print('Error:', response.status_code)
