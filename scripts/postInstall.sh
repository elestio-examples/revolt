#set env vars
set -o allexport; source .env; set +o allexport;

#wait until the server is ready
echo "Waiting for software to be ready ..."
sleep 30s;

if [ -e "./initialized" ]; then
    echo "Already initialized, skipping..."
else
    sed -i 's@proxy_set_header Authorization \$http_authorization;@proxy_set_header Authorization \$http_authorization;\n    proxy_set_header Connection \$http_connection;@g' /opt/elestio/nginx/conf.d/${DOMAIN}.conf
    touch "./initialized"
fi

docker exec elestio-nginx nginx -s reload;