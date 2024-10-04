![](./assets/readme-header.png)

An embeddable web client for federated comments using the Matrix network.

[![pipeline status](https://gitlab.com/cactus-comments/cactus-client/badges/main/pipeline.svg)](https://gitlab.com/cactus-comments/cactus-client/-/commits/main)
[![](https://img.shields.io/badge/chat-%23cactus%3Acactus.chat-informational)](https://matrix.to/#/%23cactus:cactus.chat)
[![](https://img.shields.io/badge/donate-via%20opencollective-orange)](https://opencollective.com/cactus-comments)


There are two components to Cactus Comments: 

- The embeddable web client (this repo)
- The server-side appservice ([found here](https://gitlab.com/cactus-comments/cactus-appservice))

This repository is only the web client.


# Demo

You can play with a live demo at [cactus.chat/demo](https://cactus.chat/demo/)


# Example Usage

Here is a minimal HTML page with the latest Cactus Comments release:

```html
<link rel="stylesheet" type="text/css" href="https://latest.cactus.chat/style.css" />
<script type="text/javascript" src="https://latest.cactus.chat/cactus.js"
        data-default-homeserver-url="https://matrix.cactus.chat:8448"
        data-server-name="cactus.chat"
        data-site-name="my-blog"
        data-comment-section-id="example-page">
</script>
```

This is a valid configuration for the client. You also need to use an appservice.
You can [host your own](https://cactus.chat/docs/server/self-host/), or [use the public one at cactus.chat](https://cactus.chat/docs/getting-started/quick-start/#register-your-site).

Check out the [Quick Start guide](https://cactus.chat/docs/getting-started/quick-start/) on our website for a more complete tutorial.


# Documentation

The complete documentation is available at our website, [cactus.chat](https://cactus.chat).
