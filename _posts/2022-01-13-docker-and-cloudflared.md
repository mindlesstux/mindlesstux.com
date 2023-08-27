---
title: 'Docker and cloudflared'
date: '2022-01-13T01:53:02-05:00'
last_modified_at: '2022-01-13T01:53:02-05:00'
author: MindlessTux
layout: post
categories: [Cloudflare]
tags: [docker, cloudflare, cloudflared, tutorial]
---

Some time ago [Cloudflare opened up tunneling traffic](https://blog.cloudflare.com/tunnel-for-everyone/) from origin servers to theirs negating the need for nat punches or breaking out the credit card. This is great for say home use or someone behind a cg-nat that wants to self-host. Not so good for solving gaming issues. I found that you can run their software fairly easily on most systems but I have had one nagging thing that I wanted to try. I finally sat down and figured some of it out. I wanted to run the [docker container of cloudflared.](https://hub.docker.com/r/cloudflare/cloudflared) My problem has been that there has been kinda poor documentation on the how to get it going. Not saying it does not exist, it’s just not obvious on the steps. Today I will demystify some of this below:

<!--readmore-->
## Prep System

```console
$ env |grep SHELL
SHELL=/usr/local/bin/bash
PYENV_SHELL=bash
```

I tend to store anything on the host and use a host volume. So this is what I personally do to prep containers.

```bash
mkdir -p /docker-store/cloudflared/.cloudflared
chmod 777 /docker-store/cloudflared/
chmod 777 /docker-store/cloudflared/.cloudflared/
```

## Run the container once to login

```bash
$ docker run -v /docker-store/cloudflared/.cloudflared:/home/nonroot/.cloudflared/ cloudflare/cloudflared:2022.1.0 tunnel login

Unable to find image 'cloudflare/cloudflared:2022.1.0' locally
2022.1.0: Pulling from cloudflare/cloudflared
ab2f6dae3b54: Pull complete 
9411f38bb959: Pull complete 
73f947fb88ed: Pull complete 
Digest: sha256:465510d168a589e0a81cd146d5173a212e945cb824838885ae5f0d9be09a23fb
Status: Downloaded newer image for cloudflare/cloudflared:2022.1.0
Please open the following URL and log in with your Cloudflare account:

https://dash.cloudflare.com/argotunnel?callback=HAHAH_YOU_THINK_I_WOULD_NOT_EDIT_THIS

Leave cloudflared running to download the cert automatically.
You have successfully logged in.
If you wish to copy your credentials to a server, they have been saved to:
/home/nonroot/.cloudflared/cert.pem

```

## Launch the tunnel

```bash
# docker run --name cloudflare-argo -v /docker-store/cloudflared/.cloudflared:/etc/cloudflared cloudflare/cloudflared:2022.1.0 tunnel --no-autoupdate --name mtg-asdf --hostname mtg-asdf-argo.mindlesstux.com --url http://172.16.10.235:80 
Tunnel credentials written to /etc/cloudflared/238b98cc-e7a7-495d-95eb-a407bf671cbc.json. cloudflared chose this file based on where your origin certificate was found. Keep this file secret. To revoke these credentials, delete the tunnel.

Created tunnel mtg-asdf with id 238b98cc-e7a7-495d-95eb-a407bf671cbc
2022-01-13T06:32:18Z INF Added CNAME mtg-asdf-argo.mindlesstux.com which will route to this tunnel
2022-01-13T06:32:18Z INF Cannot determine default configuration path. No file [config.yml config.yaml] in [~/.cloudflared ~/.cloudflare-warp ~/cloudflare-warp /etc/cloudflared /usr/local/etc/cloudflared]
2022-01-13T06:32:18Z INF Version 2022.1.0
2022-01-13T06:32:18Z INF GOOS: linux, GOVersion: go1.17.1, GoArch: amd64
2022-01-13T06:32:18Z INF Settings: map[hostname:mtg-asdf-argo.mindlesstux.com n:mtg-asdf name:mtg-asdf no-autoupdate:true url:http://172.16.10.235:80]
2022-01-13T06:32:18Z INF Generated Connector ID: 22d415d3-881d-450f-851e-4151560e41a6
2022-01-13T06:32:18Z INF Initial protocol http2
2022-01-13T06:32:18Z INF Starting metrics server on 127.0.0.1:37073/metrics
2022-01-13T06:32:18Z ERR Register tunnel error from server side error="Unauthorized: Record for tunnel not found" connIndex=0
2022-01-13T06:32:18Z INF Retrying connection in up to 2s seconds connIndex=0
2022-01-13T06:32:19Z ERR Register tunnel error from server side error="Unauthorized: Record for tunnel not found" connIndex=0
2022-01-13T06:32:19Z INF Retrying connection in up to 4s seconds connIndex=0
2022-01-13T06:32:20Z ERR Register tunnel error from server side error="Unauthorized: Record for tunnel not found" connIndex=0
2022-01-13T06:32:20Z INF Retrying connection in up to 8s seconds connIndex=0
2022-01-13T06:32:22Z INF Connection 3451e9ef-de76-4973-9403-8eaca9e46e24 registered connIndex=0 location=ATL
2022-01-13T06:32:23Z INF Connection 941e9654-a6eb-4c2c-80e3-d3c94039e0dd registered connIndex=1 location=IAD
2022-01-13T06:32:24Z INF Connection 9e7faa6b-808e-4c60-9e37-6da797889bd0 registered connIndex=2 location=ATL
2022-01-13T06:32:25Z INF Connection 85d2302f-f803-40c9-91ae-3a507ec8ce49 registered connIndex=3 location=IAD

```

## Test the new url

Test to make sure it works by browsing the hostname supplied to cloudflared.