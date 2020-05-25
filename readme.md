# Readme

Deploy Hasura on a Droplet using bash script: run `./generate-env.sh` and it will generate a `setup.env`.
Ensure that your ip address is filled in correctly because it is used as an ip filter in the Caddyfile.
Make sure to read the source of `setup.sh` to see if it does what you want, also see links to documentation.

```bash
$ ./generate-env.sh
export USERNAME=hasura
export ADMIN_SECRET=oV3p3MV4IOtj1RQnYs6itGxYou_pCOYR7iV06TTjqMoIFzbZ-89M2QerfDqiGcci
export JWT_SECRET_KEY=HNA_cKioR1XIWqxwfMrwIc9uKB5grvOOjcxBc1TJ7UJuyChJ-g7HBR49BVlbf_OF
export DB_PASSWORD=UaN7p-MPfS03hmmNGmAd3pXMuwyXnxmrL3m_QuLVeFvJJQtYohtx_lebgRHOCFiz
export HOME_IP=0.0.0.0
```

Create a Ubuntu 20.04 (LTS) Droplet and assign its ip value to an environment variable:

```bash
$ export DROPLET_IP=0.0.0.0
$ cat setup.env setup.sh | ssh -T root@$DROPLET_IP
```

This will install Caddy v2, PostgreSQL 12, Docker and Hasura onto your VPS.

## Assets

You can copy your website assets into `/var/www/html` using rsync.
File deletions can also be synced by adding the `--delete` argument:

```bash
$ rsync -avz ./public/ hasura@$DROPLET_IP:/var/www/html/
```

## Domain

You can assign the droplet ip address to a domain that you own.
Once that is working you can update the `:80` at the top of the `/etc/caddy/Caddyfile` to be your domain name.
This will allow [Lets Encrypt](https://letsencrypt.org/) to generate a certificate to enable https.

## SSH

Use `ssh hasura$DROPLET_IP` to gain access and `psql` will give you access to the database.

## Disclaimer

Use at own risk.

## Links

- [Install PostgreSQL](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-20-04)
- [Install Caddy v2](https://caddyserver.com/docs/download#debian-ubuntu-raspbian)
- [Install Docker](https://docs.docker.com/engine/install/ubuntu/)
- [Install Hasura](https://hasura.io/docs/1.0/graphql/manual/deployment/docker/index.html#deployment-docker)

- [Hasura Docs](https://hasura.io/docs/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/current/index.html)
- [Caddy Docs](https://caddyserver.com/docs/)
- [Ubuntu Docs](https://ubuntu.com/server/docs)
- [Docker Docs](https://docs.docker.com/)

- [Digitial Ocean Tutorials](https://www.digitalocean.com/community/tutorials).
- [Hasura Tutorials](https://hasura.io/docs/1.0/graphql/manual/guides/index.html).
