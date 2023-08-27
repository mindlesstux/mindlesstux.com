---
title: 'Setting up CloudFlared in docker'
date: '2022-01-27T20:48:53-05:00'
last_modified_at: '2022-01-27T20:48:53-05:00'
author: MindlessTux
layout: post
categories: [Cloudflare]
tags: [docker, cloudflare, cloudflared]
---

This is a follow up to my “[Docker and cloudflared](https://mindlesstux.com/2022/01/13/docker-and-cloudflared/)” post. I wanted to take it a step further. I wanted for the cloudflared to come up via docker-compose or as a stack in the swarm. Turns out it is not that hard to do so. Just need a bit more lifting to get there with a couple more steps. Read more to see how to.

<!--readmore-->

## Authenticate with cloudflare

```console
# docker run --rm -v /docker-store/cloudflared/.cloudflared:/home/nonroot/.cloudflared/ cloudflare/cloudflared:2022.1.0 tunnel login
Please open the following URL and log in with your Cloudflare account:

https://dash.cloudflare.com/argotunnel?callback=[CALLBACK_URL_CENSOR]

Leave cloudflared running to download the cert automatically.
You have successfully logged in.
If you wish to copy your credentials to a server, they have been saved to:
/home/nonroot/.cloudflared/cert.pem
```

## Check for the cert

```console
# cd /docker-store/cloudflared/.cloudflared
# ls -al
total 4
drwxrwxrwx. 2 root root 22 Jan 23 14:15 .
drwxr-xr-x. 3 root root 26 Jan 13 01:10 ..
-rw-------. 1 65532 65532 1934 Jan 23 14:15 cert.pem
```


## Create a new tunnel

```console 
# docker run --rm -v /docker-store/cloudflared/.cloudflared:/home/nonroot/.cloudflared/ cloudflare/cloudflared:2022.1.2 tunnel create docker-swarm
Tunnel credentials written to /home/nonroot/.cloudflared/fda6fab5-1d8c-477d-91f8-160537e230f7.json. cloudflared chose this file based on where your origin certificate was found. Keep this file secret. To revoke these credentials, delete the tunnel.

Created tunnel docker-swarm with id fda6fab5-1d8c-477d-91f8-160537e230f7
```


## Check to see the tunnels there are

```console
docker run --rm -v /docker-store/cloudflared/.cloudflared:/home/nonroot/.cloudflared/ cloudflare/cloudflared:2022.1.2 tunnel list
You can obtain more detailed information for each tunnel with `cloudflared tunnel info <name/uuid>`
ID                                   NAME           CREATED              CONNECTIONS  
fda6fab5-1d8c-477d-91f8-160537e230f7 docker-swarm   2022-01-23T19:23:23Z 2xATL, 2xIAD
```

## Verify that a tunnel json file was made

```console
# ls -al /docker-store/cloudflared/.cloudflared
total 12
drwxrwxrwx. 2 root root 92 Jan 23 14:23 .
drwxr-xr-x. 3 root root 26 Jan 13 01:10 ..
-rw-------. 1 65532 65532 1934 Jan 23 14:15 cert.pem
-rw-r--r--. 1 root root 1052 Jan 23 14:22 config.notyet
-rw-------. 1 65532 65532 186 Jan 23 14:23 fda6fab5-1d8c-477d-91f8-160537e230f7.json
```


## Create the config file
It always must end with the 404 per docs.


```console
# touch /docker-store/cloudflared/.cloudflared/config.yaml
# nano config.yaml
```

```yaml
tunnel: fda6fab5-1d8c-477d-91f8-160537e230f7
credentials-file: /home/nonroot/.cloudflared/fda6fab5-1d8c-477d-91f8-160537e230f7.json
logfile: /var/log/cloudflared.log

ingress:
  - hostname: whoami.mindlesstux.com
    service: http://whoami:7878
  - service: http_status:404
```

Register the DNS for the tunnel:

```console
# docker run --rm -v /docker-store/cloudflared/.cloudflared:/home/nonroot/.cloudflared/ cloudflare/cloudflared:2022.1.2 tunnel route dns docker-swarm whoami.mindlesstux.com
```

Create the yaml to launch it. Be it docker-compose or for a swarm, both are below. I am reusing the traefik\_bridge network to gain access to the containers I might want to publish to the world.

```console
touch /docker-store/cloudflared/docker-compose.yml
nano /docker-store/cloudflared/docker-compose.yml
```

```yaml
---
version: "2"
services:
  cloudflared:
    image: cloudflare/cloudflared:2022.1.2
    container_name: cloudflared
    environment:
      - TZ=America/New_York
    volumes:
      - /docker-store/cloudflared/.cloudflared:/home/nonroot/.cloudflared/
    restart: always
    command: tunnel run
    networks:
      - traefik_bridge
networks:
  traefik_bridge:
    external: true
```

```console
# docker-compose up -d
Creating cloudflared ... done
```

Or stack.yaml for a swarm:

```console
# touch /docker-store/cloudflared/stack.yaml
# nano /docker-store/cloudflared/stack.yaml
```

```yaml
---
version: '3'

services:
  cloudflared:
    image: "cloudflare/cloudflared:2022.1.0"
    volumes:
      - /docker-store/cloudflared/.cloudflared:/home/nonroot/.cloudflared/
    command: tunnel run
    deploy:
      placement:
        constraints: 
          - node.role==manager
    networks:
      - traefik_traefik_bridge

networks:
  traefik_traefik_bridge:
    external: true
```

```console
# docker stack deploy -c stack.yaml cloudflared
Creating service cloudflared_cloudflared
```

Then go browse your new page: [https://whoami.mindlesstux.com/](http://whoami.mindlesstux.com/) Note the IPs listed are not what your ISP provided, this is due to docker networking. To put that back in place will be another day. You can compare this same whoami container passing through traefik: [https://whoami.dacentec.mindlesstux.com/](http://whoami.dacentec.mindlesstux.com/)