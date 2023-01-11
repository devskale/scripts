import requests

# Set the API endpoint URL
url = 'https://amd2.mooo.com/api/tasks'

# Set the payload with the task details
payload = {'title': 'How to ... around', 'description': 'The more you .. around the more you find out'}

# Send the POST request
response = requests.post(url, json=payload)

# Print the response status code
print(response.status_code)

# Print the response content
print(response.json())

