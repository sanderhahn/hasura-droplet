#!/bin/bash
function secret {
    python3 -c 'import secrets; print(secrets.token_urlsafe(48))'
}

cat <<-EOF | tee ./setup.env
export USERNAME=hasura
export ADMIN_SECRET=`secret`
export JWT_SECRET_KEY=`secret`
export DB_PASSWORD=`secret`
export HOME_IP=`wget -qO - icanhazip.com`
EOF
