# Hacking

Thank you for being interested in Cactus Comments!
Contributions are very welcome!
This document is here to help you get started hacking on the web client.


## Getting Started

You can install dependencies using npm by running:

```sh
$ npm install
```

The web client is written in [Elm](https://elm-lang.org/), so you'll need the elm compiler.
Other useful tools include `elm-format`, `elm-test`, `elm-coverage`, and `elm-analyse`.

If you're using [Nix](https://nixos.org), you can use the `shell.nix` file to get the tools you need.
Run `nix-shell` to enter the environment.


## Running Locally

The `examples/dev.html` file is small example page, which runs the code you have in `src/`.
You can serve it by running:

```sh
$ npm run dev
```

By default, Parcel will serve it on all interfaces, meaning you can access it on `localhost:8080` on the same device or on your local network on `DEVICE_IP:8080`.

It uses the public [matrix.cactus.chat](https://matrix.cactus.chat:8448) homeserver and
[appservice](https://gitlab.com/cactus-comments/cactus-appservice).


## Running Tests

To just run the tests:

```sh
$ elm-test
```

To run the tests and generate a code coverage report:

```sh
$ elm-coverage
```


## Building

To build minified JS and CSS files, you can run:

```sh
$ npm run build
```

The client is built using [parcel](https://parceljs.org/).
To build the client and stylesheet with parcel directly:

```sh
$ parcel build ./src/cactus.js ./src/style.css
```


## Code Style

Code is formatted according to the [Elm style guide](https://elm-lang.org/docs/style-guide).
You can use the `elm-format` tool to format files automatically.

Please format your files using `elm-format`, when you make a merge request ✨

If you use vim, I highly recommend the [elm-vim](https://github.com/ElmCast/elm-vim) plugin.
