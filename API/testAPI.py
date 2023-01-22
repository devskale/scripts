import requests

response = requests.get('http://localhost:5000/tasks/2')
#response = requests.get('https://burgenland2021.org:5000/tasks/2')
#response = requests.get('https://woodmastr.gotdns.ch:5000/tasks/2')

if response.status_code == 200:
    print(response.json())
else:
    print('Error:', response.status_code)
