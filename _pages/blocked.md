---
title: CloudFlare Blocking
layout: page-nosidebar
permalink: /cloudflare-blocking
---

# WAF Rules

## Block Sensitive
This is to drop everything to a few sub-domains unless it is from the united states.
```
(http.host in 
{
    "bitwarden.mindlesstux.com"
    "guacamole.mindlesstux.com"
    "adminer.mindlesstux.com"
    "adminer.dacentec.mindlesstux.com"
    "andromeda-cockpit-lan.mindlesstux.com"
    "hastebin.mindlesstux.com"
    "home-assistant.mindlesstux.com"
    "nodered.dacentec.mindlesstux.com"
    "phpmyadmin.mindlesstux.com"
    "r420-cockpit-dacentec.mindlesstux.com"
    "r420-ssh-dacentec.mindlesstux.com"
    "routervm-cockpit-lan.mindlesstux.com"
    "sshwifty-dec.mindlesstux.com"
    "synology1.mindlesstux.com"
    "synology2.mindlesstux.com"
    " portainer.mindlesstux.com"
    " ombi.mindlesstux.com"
    }
and not ip.geoip.country in {"US"})
```

## Allow Matrix
Allows all traffic for Matrix
```
(http.request.uri.path contains "/.well-known/matrix/") 
or (http.request.uri.path contains "/_matrix/") 
or (http.host eq "matrix.mindlesstux.com")
```

## Allow Mastodon
Allows all traffic for Mastodon

```
(http.host eq "mastodon.mindlesstux.com")
```

## JS Challenge
This is to drop country and ASN traffic that I find have been causing problems.

```
(ip.geoip.country in {"CN" "IR" "IQ" "RU" "T1" "VN"}) or 
(ip.geoip.asnum in {13238 395954 9009 8100 207651 212238 203020 36352 201011 30542 201011 64249 15969 13737 60068 33576})
```

If source is from one of the following counties or from the Tor network the traffic will be challenged.
- China
- Iran
- Iraq
- Russian Federation
- Vietnam

If source is from one of the follwoing ASNs traffice will be challenged.  Reason for being blanket challened is bot traffic and content spam that is out of control.

| ASN                                   | ASName                        | OrgName            |
| :---                                  | :---                          | :---               |
| [13238](https://bgp.he.net/AS13238)   | YANDEX                        | YANDEX LLC |
| [395954](https://bgp.he.net/AS395954) | LEASEWEB-USA-LAX              | Leaseweb USA, Inc. |
| [9009](https://bgp.he.net/AS9009)     | M247                          | M247 Europe SRL |
| [8100](https://bgp.he.net/AS8100)     | ASN-QUADRANET-GLOBAL          | QuadraNet Enterprises LLC |
| [207651](https://bgp.he.net/AS207651) | VDSINA-NL                     | Hosting technology LTD |
| [212238](https://bgp.he.net/AS212238) | CDNEXT                        | Datacamp Limited |
| [203020](https://bgp.he.net/AS203020) | HostRoyale                    | HostRoyale Technologies Pvt Ltd |
| [36352](https://bgp.he.net/AS36352)   | AS-COLOCROSSING               | ColoCrossing |
| [201011](https://bgp.he.net/AS201011) | CORE-BACKBONE                 | Core-Backbone GmbH |
| [30542](https://bgp.he.net/AS30542)   | MOVI-R-TECH-SOLUTIONS         | MOVI-R |
| [201011](https://bgp.he.net/AS201011) | CORE-BACKBONE                 | Core-Backbone GmbH |
| [64249](https://bgp.he.net/AS64249)   | ENDOFFICE                     | Charles River Operation |
| [15969](https://bgp.he.net/AS15969)   | Systemia-AS                   | Systemia.pl Sp. z o.o. |
| [13737](https://bgp.he.net/AS13737)   | AS-INCX                       | INCX Global, LLC |
| [60068](https://bgp.he.net/AS60068)   | CDN77                         | Datacamp Limited |
| [33576](https://bgp.he.net/AS33576)   | DIG001                        | Digicel Jamaica |