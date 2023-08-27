---
title: 'Cloudflare tunnels and Cockpit'
date: '2022-01-16T21:54:23-05:00'
last_modified_at: '2022-01-16T21:54:23-05:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://ryan.lovelett.me/posts/letsencrypt-cockpit/'
    - 'https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/configuration-file/ingress'
    - 'https://cockpit-project.org/guide/latest/https.html#https-certificates'
    - 'https://cockpit-project.org/guide/latest/cockpit.conf.5'
categories: [Cloudflare]
tags: [cloudflare]
---

I have been continuing to play with Cloudflare tunnels and teams and wanted to put cockpit on a tunnel. I found out it is not as straightforward as one would think. I found a small web of things to do and an undocumented disability/bug in Cloudflare tunnels. It is not as simple as throwing it into the configuration and expecting it to work. No, you have to configure cockpit, tweak the tunnel and have a URL of a certain (loose) format. I am not certain I needed to get a LetsEncrypt cert for it so I am skipping that in this write-up. If anyone does find that it is needed, drop me a message and I will add it at a later date. For quick and dirty setup read after the break.

<!--readmore-->

I found I had to create***/etc/cockpit/cockpit.conf*** and put the following into it.

```
[WebService]
Origins = https://routervm-cockpit-lan.mindlesstux.com wss://routervm-cockpit-lan.mindlesstux.com https://10.147.17.10:9090 wss://10.147.17.10:9090
ProtocolHeader = X-Forwarded-Proto
AllowUnencrypted = true

[Session]
Banner = /etc/issue
IdleTimeout = 10

```

Of this file the critical lines are 1-4. Here is a quick bullet list of what/why:

- \[WebService\] 
    - Section header
- Origins = … 
    - This is a list of domains/ips that cockpit will function from.
- ProtocolHeader = … 
    - CloudFlare is basically reverse proxying to cockpit, per docs needed.
- AllowUnencrypted = … 
    - May not be needed but untested. Basically allows non https and the way we would be using would only be unencrpyted locally on the host.

Now the **/etc/cloudflared/config.yml** is nothing specical at this time.

```yaml
# Name of the tunnel you want to run
tunnel: routervm-site2
credentials-file: /etc/cloudflared/.json

# Serves the metrics server under /metrics and the readiness server under /ready
metrics: 0.0.0.0:2000

# Autoupdates applied in a k8s pod will be lost when the pod is removed or restarted, so
# autoupdate doesn't make sense in Kubernetes. However, outside of Kubernetes, we strongly
# recommend using autoupdate.
no-autoupdate: false

# The `ingress` block tells cloudflared which local service to route incoming
# requests to. For more about ingress rules, see
# https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/ingress
#
# Remember, these rules route traffic from cloudflared to a local service. To route traffic
# from the internet to cloudflared, run `cloudflared tunnel route dns  `.
# E.g. `cloudflared tunnel route dns example-tunnel tunnel.example.com`.
ingress:
  # The first rule proxies traffic to the httpbin sample Service defined in app.yaml
  - hostname: routervm-cockpit-lan.mindlesstux.com
    service: https://routervm-cockpit.lan.mindlesstux.com:9090
  # This rule matches any traffic which didn't match a previous rule, and responds with HTTP 404.
  - service: http_status:404

```

Here is the key thing, I wasted several hours trying to use routervm-cockpit.lan.mindlesstux.com. I kept getting SSL/TLS problems from Cloudflare and I went through so many configuration tweaks and I feared I may have missed a documented use only subdomains and not sub-subdomains. The answer is to keep it one level of subdomain and not two. I had to settle for routervm-cockpit-lan.mindlesstux.com. Once I made that change the SSL/TLS problems from cloudflare went away and it just worked.