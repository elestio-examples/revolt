#set env vars
set -o allexport; source .env; set +o allexport;

#!/bin/bash

if [ -e "./initialization" ]; then
    echo "Already initialized, skipping..."
else
    openssl ecparam -name prime256v1 -genkey -noout -out vapid_private.pem
    openssl ec -in vapid_private.pem -pubout -out vapid_public.pem
    PRIVATE_KEY=$(openssl ec -in vapid_private.pem -text -noout | grep -A 3 'priv:' | tail -n +2 | tr -d '\n[:space:]:')
    PUBLIC_KEY=$(openssl ec -in vapid_private.pem -pubout -outform DER | tail -c 65 | openssl base64 -A)
    rm vapid_private.pem vapid_public.pem

    cat /opt/elestio/startPostfix.sh > post.txt
    filename="./post.txt"

    SMTP_LOGIN=""
    SMTP_PASSWORD=""

    # Read the file line by line
    while IFS= read -r line; do
    # Extract the values after the flags (-e)
    values=$(echo "$line" | grep -o '\-e [^ ]*' | sed 's/-e //')

    # Loop through each value and store in respective variables
    while IFS= read -r value; do
        if [[ $value == RELAYHOST_USERNAME=* ]]; then
        SMTP_LOGIN=${value#*=}
        elif [[ $value == RELAYHOST_PASSWORD=* ]]; then
        SMTP_PASSWORD=${value#*=}
        fi
    done <<< "$values"

    done < "$filename"

    rm post.txt

    cat << EOT >> ./.env

    REVOLT_SMTP_HOST=tuesday.mxrouting.net
    REVOLT_SMTP_USERNAME=${SMTP_LOGIN}
    REVOLT_SMTP_PASSWORD=${SMTP_PASSWORD}
    REVOLT_SMTP_FROM="Revolt <${SMTP_LOGIN}>"
    REVOLT_VAPID_PRIVATE_KEY=${PRIVATE_KEY}
    REVOLT_VAPID_PUBLIC_KEY=${PUBLIC_KEY}
    
EOT

    cat << EOT >> ./Revolt.toml
    [database]
    mongodb = "mongodb://database"
    redis = "redis://redis/"

    [hosts]
    app = "${REVOLT_APP_URL}"
    api = "${REVOLT_PUBLIC_URL}"
    events = "${REVOLT_EXTERNAL_WS_URL}"
    autumn = "${AUTUMN_PUBLIC_URL}"
    january = "${JANUARY_PUBLIC_URL}"
    voso_legacy = ""
    voso_legacy_ws = ""

    [api]

    [api.registration]
    invite_only = false

    [api.smtp]
    host = "${REVOLT_SMTP_HOST}"
    username = "${REVOLT_SMTP_USERNAME}"
    password = "${REVOLT_SMTP_PASSWORD}"
    from_address = "${REVOLT_SMTP_FROM}"

    [api.vapid]
    private_key = "${REVOLT_VAPID_PRIVATE_KEY}"
    public_key = "${REVOLT_VAPID_PUBLIC_KEY}"

    [api.fcm]
    api_key = ""

    [api.apn]
    pkcs8 = ""
    key_id = ""
    team_id = ""

    [api.security]
    authifier_shield_key = ""
    voso_legacy_token = ""
    trust_cloudflare = false

    [api.security.captcha]
    hcaptcha_key = ""
    hcaptcha_sitekey = ""

    [api.workers]
    max_concurrent_connections = 50

    [features]
    webhooks_enabled = false

    [features.limits]

    [features.limits.global]
    group_size = 100
    message_embeds = 5
    message_replies = 5
    message_reactions = 20
    server_emoji = 100
    server_roles = 200
    server_channels = 200

    new_user_days = 3

    [features.limits.new_user]
    outgoing_friend_requests = 5

    bots = 2
    message_length = 2000
    message_attachments = 5
    servers = 100

    attachment_size = 20000000
    avatar_size = 4000000
    background_size = 6000000
    icon_size = 2500000
    banner_size = 6000000
    emoji_size = 500000

    [features.limits.default]
    outgoing_friend_requests = 10

    bots = 5
    message_length = 2000
    message_attachments = 5
    servers = 100

    attachment_size = 20000000
    avatar_size = 4000000
    background_size = 6000000
    icon_size = 2500000
    banner_size = 6000000
    emoji_size = 500000

    [sentry]
    api = ""
    events = ""
EOT
    touch "./initialization"
fi