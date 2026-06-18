# Manifest format

Every tool is a directory under `packages/<category>/<tool>/` containing a
single `package.yaml`. The category in the path is informational; the index
generator reads the `category:` field.

## package.yaml fields

| field        | required | meaning                                                        |
|--------------|----------|----------------------------------------------------------------|
| name         | yes      | unique tool id (used in `armory install <name>`)               |
| category     | yes      | grouping for `armory list <category>`                          |
| version      | no       | free-form version string                                       |
| description  | yes      | one line shown in search/list                                  |
| tags         | no       | list of keywords used by `armory search`                       |
| homepage     | no       | upstream URL                                                   |
| size_note    | no       | human note shown before installing heavy tools                 |
| files        | yes      | list of files to fetch (see below)                             |
| c2           | no       | C2 import hints (see below)                                    |

## file entries

```yaml
files:
  - dest: chisel              # filename written into the tool's install dir
    os: linux                 # linux | windows | any  (filters what gets fetched)
    arch: amd64               # optional, informational
    exec: true                # chmod +x after download
    unpack: tar.gz            # optional: tar.gz | zip | gz -> auto-extract
    url: release://binaries/chisel_1.10.1_linux_amd64
```

### url schemes

| scheme        | resolves to                                                                 |
|---------------|-----------------------------------------------------------------------------|
| `release://T/F` | `https://github.com/<owner>/<repo>/releases/download/T/F` (heavy assets)   |
| `raw://path`    | `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/path` (scripts) |
| `https://...`   | fetched verbatim (pull straight from upstream, no re-hosting)              |

The split is the whole point: **git stays tiny** (manifests + small scripts),
**heavy binaries/wordlists ride on GitHub Releases**, and the client only ever
downloads the exact files for the tools it asks for.

## c2 hints (optional)

```yaml
c2:
  sliver:
    type: alias            # alias | extension | armory
    dir: ~/.sliver-client/aliases
    note: "unzip into the aliases dir, then 'aliases load'"
  adaptix:
    type: bof
    note: "load via the BOF pack in the Adaptix client"
```

`armory import sliver <tool>` / `armory import adaptix <tool>` copies the
installed files into the named dir and prints the note.

## bundles

`bundles/<name>.yaml` groups tools so you grab a themed set at once:

```yaml
name: ad-pack
description: Active Directory attack essentials.
tools: [rubeus, certify, printerbug, mimikatz]
```

`armory bundle ad-pack` installs every tool listed.
