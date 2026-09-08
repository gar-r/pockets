# Pockets

Pick Pocket tracker WoW extension.

## Install

From a WoW install, the `_retail_` build of the game must be present:

```sh
make install
```

This copies the addon into the client's `Interface/AddOns/pockets` directory.

## Build a release zip

```sh
make release
```

Writes `dist/pockets_v<version>.zip`.
