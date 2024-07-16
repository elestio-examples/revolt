#set env vars
set -o allexport; source .env; set +o allexport;

#wait until the server is ready
echo "Waiting for software to be ready ..."
sleep 30s;

if [ -e "./initialized" ]; then
    echo "Already initialized, skipping..."
else
    sed -i 's@proxy_set_header Authorization \$http_authorization;@proxy_set_header Authorization \$http_authorization;\n    proxy_set_header Connection \$http_connection;@g' /opt/elestio/nginx/conf.d/${DOMAIN}.conf
    docker exec elestio-nginx nginx -s reload;

    sleep 30s;
    curl ${REVOLT_PUBLIC_URL}/auth/account/create \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'pragma: no-cache' \
  -H 'priority: u=1, i' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36' \
  --data-raw '{"email":"'${ADMIN_EMAIL}'","password":"'${ADMIN_PASSWORD}'"}'
    
    touch "./initialized"
fi
