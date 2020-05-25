set -e

apt-get update
apt-get upgrade -y

# Install Firewall only allow http/https/ssh

ufw allow http
ufw allow https
ufw allow ssh
ufw --force enable

# Install PostgreSQL
# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-20-04

apt-get install -y postgresql postgresql-contrib

# Install Caddy v2
# https://caddyserver.com/docs/download#debian-ubuntu-raspbian

if ! [ -e /etc/apt/sources.list.d/caddy-fury.list ]; then
    echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" | sudo tee -a /etc/apt/sources.list.d/caddy-fury.list
fi
sudo apt update
sudo apt install -y caddy

# Install Docker
# https://docs.docker.com/engine/install/ubuntu/

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Create Non-root user

adduser --disabled-password --gecos "" $USERNAME || true

# Enable ssh login

cp -r /root/.ssh /home/$USERNAME
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

# Run Docker as a non-root user

usermod -aG docker $USERNAME

# Enable passwordless sudo for user

usermod -aG sudo $USERNAME

function append_line { # filename line
    grep -qxF "$2" "$1" || echo "$2" >>"$1"
}

append_line /etc/sudoers "$USERNAME ALL=(ALL) NOPASSWD:ALL"

# Create database

sudo -u postgres -i createuser $USERNAME || true
sudo -u postgres -i createdb $USERNAME --owner=$USERNAME || true

sudo -u postgres -i psql $USERNAME postgres -c "ALTER ROLE $USERNAME WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres -i psql $USERNAME postgres -c "CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA pg_catalog;"

# Install Hasura
# https://hasura.io/docs/1.0/graphql/manual/deployment/docker/index.html#deployment-docker

# TODO: i am not sure if its better to use Docker network=host or the default bridge

# export DOCKER_INTERNAL_IP=`ip route | grep docker0 | awk '{print $9}'`
# append_line /etc/postgresql/12/main/pg_hba.conf "host all all $DOCKER_INTERNAL_IP/32 md5"
# append_line /etc/postgresql/12/main/postgresql.conf "listen_addresses = '*'"
# service postgresql restart

# https://hasura.io/docs/1.0/graphql/manual/deployment/graphql-engine-flags/reference.html
cat <<-EOF | sudo tee /home/$USERNAME/hasura.env
HASURA_GRAPHQL_DATABASE_URL=postgres://$USERNAME:$DB_PASSWORD@127.0.0.1/hasura
HASURA_GRAPHQL_ENABLE_CONSOLE=true
HASURA_GRAPHQL_ADMIN_SECRET=$ADMIN_SECRET
HASURA_GRAPHQL_JWT_SECRET={"type":"HS256","key":"$JWT_SECRET_KEY"}
HASURA_GRAPHQL_UNAUTHORIZED_ROLE=anonymous
HASURA_GRAPHQL_DISABLE_CORS=true
HASURA_GRAPHQL_ENABLED_APIS=metadata,graphql,pgdump
EOF
chown $USERNAME:$USERNAME /home/$USERNAME/hasura.env
chmod go-rw /home/$USERNAME/hasura.env

# https://docs.docker.com/config/pruning/#prune-everything
sudo -u hasura -i \
    docker run -d \
    --network=host \
    --name hasura \
    --user nobody \
    --env-file /home/hasura/hasura.env \
    --restart=always \
    hasura/graphql-engine:v1.2.1

# Setup Caddy

mkdir -p /var/www/html
cat <<-EOF | sudo tee /var/www/html/index.html
<!-- intentionally blank page -->
EOF
chown -R hasura:hasura /var/www/html

# https://caddyserver.com/docs/
# https://hasura.io/docs/1.0/graphql/manual/api-reference/index.html
cat <<-EOF | sudo tee /etc/caddy/Caddyfile
:80
file_server /* {
    root /var/www/html
}
@admin {
    remote_ip $HOME_IP
    path /console*
    path /v1/query
    path /v1alpha1/pg_dump
    path /v1alpha1/config
    path /v1/graphql/explain
}
reverse_proxy @admin localhost:8080
@public {
    path /healthz
    path /v1/graphql
    path /v1alpha1/graphql
    path /v1/version
}
reverse_proxy @public localhost:8080
EOF

systemctl reload caddy
