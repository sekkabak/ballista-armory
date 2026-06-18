# ballista-armory

> a set of tools, to be here, and not to download it over and over again...

A **portable** pentest / CTF vault with its own tiny package manager. The whole
thing is self-contained in one folder - manifests, manager, index, and every
tool you download all live inside it. Drop the folder on a USB stick or a new
box and it just works.

## Quick start

```bash
# bootstrap: fetches the vault folder, then symlinks the manager into PATH
curl -sSL cbak.pl/armory | bash

armory search kerberos               # find things
armory install chisel ligolo-ng      # grab only what you need (into the vault)
armory bundle ad-pack                # or a themed set at once
armory root                          # where the self-contained vault lives
```

## Portable by design

Everything stays inside the vault folder:

```
ballista-armory/            <- the one portable folder
  bin/armory                  the manager (resolves this folder via its own path)
  index.json                  committed; read locally, no fetch needed offline
  armory.yaml                 owner/repo/release URLs
  install.sh                  symlink-only local installer
  bootstrap.sh                what cbak.pl/armory serves
  packages/<cat>/<tool>/package.yaml
  bundles/<name>.yaml
  store/                      downloaded tools land HERE (gitignored)
    .bin/                     relative symlinks to executables -> add to PATH
```

- The manager finds its own folder by resolving its real path, **even through
  the PATH symlink**, so `ARMORY_ROOT` is always the vault.
- Downloaded tools and the install log (`store/`) live **inside** the folder.
- Executable symlinks under `store/.bin` are **relative**, so moving the whole
  folder keeps every tool runnable with no re-install.

Move the folder anywhere; the only thing to refresh is the external PATH
symlink - just re-run `install.sh` once after a move.

## How the bootstrap / install split works

| step | file | does |
|------|------|------|
| `cbak.pl/armory` | `bootstrap.sh` | clone (or tarball-download) the vault folder, then run its `install.sh` |
| local install | `install.sh` | **only** symlinks `bin/armory` into `~/.local/bin` - no downloads |

So the heavy "fetch the software" happens once in the bootstrap; `install.sh`
itself is trivial and re-runnable.

```bash
# install into a custom location:
ARMORY_DIR=/opt/armory  curl -sSL cbak.pl/armory | bash
# link into a different bin dir:
./install.sh /usr/local/bin
```

## Why it's not just `git clone` of everything

git stays tiny; heavy assets ride on GitHub Releases:

| layer | lives in | size |
|-------|----------|------|
| manifests, manager, scripts, the search index | **git** (the vault folder) | a few hundred KB |
| binaries, compiled BOFs, wordlists (SecLists, ...) | **GitHub Releases assets** | as big as you like |

`armory install <tool>` reads the local `index.json` and `curl`s only that
tool's release assets into `store/`. You never pull tools you don't ask for.
Needs only `bash`, `curl`, `jq` (and optionally `gum` + `fzf` for the TUI).

## Adding a tool

1. `mkdir -p packages/<category>/<tool>` and write `package.yaml`
   (see `docs/MANIFEST.md`).
2. Upload the binary as a **Release asset**; point the file's `url:` at
   `release://<tag>/<file>`. Small scripts can be committed and referenced with
   `raw://<path>`; upstream files can use a plain `https://`.
3. Push. The GitHub Action rebuilds `index.json`. Users get it on `armory update`.

## Hosting cbak.pl/armory

Serve `bootstrap.sh` at that path. Easiest is a Cloudflare Worker / Pages
redirect (302) to
`https://raw.githubusercontent.com/sekkabak/ballista-armory/main/bootstrap.sh`,
or nginx:
`location = /armory { return 302 https://raw.githubusercontent.com/sekkabak/ballista-armory/main/bootstrap.sh; }`

## Manager commands

```
armory search [q]      fuzzy search (interactive with fzf)
armory list [cat]      browse categories / tools
armory info <tool>     details + files
armory install <t...>  fetch tools into the vault  [--os all|linux|windows]
armory bundle [name]   install a group / list bundles
armory import <c2> <t> copy files into sliver/adaptix dirs
armory installed       what's local
armory rm <tool>       remove
armory update          git pull the vault (or refresh index.json)
armory root | path     print the vault folder / the bin dir for PATH
```
