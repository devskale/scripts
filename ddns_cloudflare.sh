DNS_ZONE='<Zone.DNS>'
DNS_RECORD='<your DNS record ID here>'
AUTH_KEY='<your CloudFlare API token here>'
EMAIL_ADDRESS='<jwamind@gmail.com>'
DNS_RECORD_NAME="\"<burgenland2021.org>\""
CURRENT_IP_ADDRESS="\"$(curl -s ip.me)\""
CURRENT_DNS_VALUE=$(curl -sX GET "https://api.cloudflare.com/client/v4/zones/${DNS_ZONE}/dns_records/${DNS_RECORD}" -H "Content-Type:application/json" -H "X-Auth-Key:${AUTH_KEY}" -H "X-Auth-Email:${EMAIL_ADDRESS}" | jq '.result["content"]')

if [ ${CURRENT_DNS_VALUE} != ${CURRENT_IP_ADDRESS} ]; then
    curl -sX PUT "https://api.cloudflare.com/client/v4/zones/${DNS_ZONE}/dns_records/${DNS_RECORD}" -H "X-Auth-Email:${EMAIL_ADDRESS}" -H "X-Auth-Key:${AUTH_KEY}" -H "Content-Type:application/json" --data '{"type":"A","name":'${DNS_RECORD_NAME}',"content":'${CURRENT_IP_ADDRESS}'}' > /dev/null
fi
