** To skip all the dirty details of deployment and configuration, simply run `startup.sh` after configuring all the .env files for each dir **

Contents:
1. [Domain Name and Cert Management](#domain-name-and-cert-management)
1. [Nginx Reverse Proxy](#nginx-reverse-proxy-for-https)
1. [Nextcloud Install](#nextcloud)
1. [Vaultwarden Install](#vaultwarden)

# Domain Name and Cert Management

I used namecheap because they had the cheapest registry for a .com name I could find. Would recommend.

## DDClient - For Dynamic IP

https://www.namecheap.com/support/knowledgebase/article.aspx/583/11/how-do-i-configure-ddclient/

> DDClient runs as ddns (Dynamic DNS) client tool updating to namecheap.com as A+ Dynamic DNS Records.
> The following subdomains are currently updated:
>   - @
>   - www
>   - nextcloud

## letsencrypt - included in Proxy containers

Provides free SSL Certs

## Certbot -- not in use as it needs to run inside container or on bare metal

Will automatically update and manage certs on expiration

https://certbot.eff.org/lets-encrypt/ubuntufocal-apache

Automated tool to manage certs.

1. Update snapd to install 
  ```sh
   sudo snap install core; sudo snap refresh core
  ```
1. Install snap package
  ```sh
  sudo snap install --clasic certbot
  sudo ln -s /snap/bin/certbot /usr/bin/certbot
  ```
1. Get certs
  ```sh
  sudo certbot certonly --<server_type_(apache/nginx)>
  ```

# Nginx Reverse Proxy for HTTPS

1. Copy github repo to a new folder: https://github.com/linuxhandbook/tutorial-snippets/tree/main/Reverse_Proxy
>  Recommended: research how this proxy setup works further, not required for this install

https://github.com/gepd/docker-compose-letsencrypt-nginx-proxy-companion

> In short, start this docker-compose, then simply add the correct environment variables to your docker run command (or docker-compose/swarm/etc).
> Example apache server with TLS (exclude `LETSENCRYPT` for no security, only reverse proxy):

```sh
docker run -d -e VIRTUAL_HOST=your.domain.com \
              -e LETSENCRYPT_HOST=your.domain.com \
              -e LETSENCRYPT_EMAIL=your.email@your.domain.com \
              --network=webproxy \
              --name my_app \
              httpd:alpine 
```

1. Modify `env.example` to `.env` and change admin email address
1. Change `max_upload_size.conf` to match max supported file upload size
1. Create docker network named `net`

    ```sh
    docker network create net
    ```

1. start containers

    ```sh
    docker-compose up -d
    ```

> Test Endpoint now by going to `https://<device_ip_or_hostname>` in a browser
> In current instance: `https://sanctuary`

# Nextcloud

Resource: https://linuxhandbook.com/install-nextcloud-docker/

## Deploy Nextcloud with Postgresql

Note: this differs from the tutorial

1. Create a new `Nextcloud` directory and move into it
1. Create new docker-compose
1. Ceate a `Postgres` and `Nextcloud` service. `Nextcloud` should require the `Postgres` service name (i.e. `NCDatabase`)
1. Create a .env file specifying all of the required environment variables for both Postgres and 

***Networks explained***
> By default, docker compose will create a network for all services, unless a service is already part of a network.
> The `net` network created as part of the reverse-proxy service is used to communicate to the proxied services. The `common` network is used for non-proxied communications between nextcloud, the database, and any other apps running locally.

# Vaultwarden

https://registry.hub.docker.com/r/vaultwarden/server

Vaultwarden is an alternative Bitwarden server (written in Rust) which runs lighter (less memory, disk usage, containers) than the traditional Bitwarden server deployment, which is intended more for enterprise platforms.

See the wiki guide for setting environment variables, backup and hardening, and more recommendations and best practices. For a quick (and relatively secure start), simply reference the ENV variables listed in the docker-compose.yml file.

See also the [Nginx Reverse Proxy section](#nginx-reverse-proxy-for-https) above for setting up the Reverse Proxy with Nginx which makes secure, encrypted HTTPS traffic a breeze.
