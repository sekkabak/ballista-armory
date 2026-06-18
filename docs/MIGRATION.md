# Porting the old repo + uploading new tooling

Your current `ballista-armory` is a flat pile of binaries committed straight
into git. The new model keeps **git tiny** and pushes heavy files to **GitHub
Releases**. Here is how to move over, and the day-to-day workflow for adding
tools.

## The rule of thumb

| what it is                                  | where it goes                 | url scheme   |
|---------------------------------------------|-------------------------------|--------------|
| compiled binary / .exe / BOF / wordlist     | GitHub **Release asset**      | `release://` |
| small text script you wrote/curated         | committed in `packages/...`   | `raw://`     |
| file that already has a stable upstream URL  | not stored at all             | `https://`   |

## Step 1 - map your existing files

From your current repo root:

| old file            | new package                       | how                          |
|---------------------|-----------------------------------|------------------------------|
| `chisel`,`chisel.exe`| `packages/pivoting/chisel`        | release asset (`binaries`)   |
| `tun2socks`         | `packages/pivoting/tun2socks`     | release asset (`binaries`)   |
| `nc64.exe`          | `packages/utils/netcat`           | release asset (`binaries`)   |
| `mimikatz/`         | `packages/credentials/mimikatz`   | release asset (zip the dir)  |
| `rusthound-ce`      | `packages/ad/rusthound-ce`        | release asset (`binaries`)   |
| `printerbug.py`     | `packages/scripts/printerbug`     | commit, `raw://`             |
| `serve.py`          | `packages/scripts/serve`          | commit, `raw://`             |
| `setup-scripts/*`   | `packages/scripts/<name>`         | commit, `raw://`             |

(The first few already have manifests in this scaffold - just upload the real
binaries.)

## Step 2 - upload the binaries as release assets

Do this once from a checkout that still has the old binaries:

```bash
# one release "bucket" per asset family; tag names are arbitrary
scripts/publish.sh binaries  ./chisel ./chisel.exe ./tun2socks ./nc64.exe ./rusthound-ce
# zip multi-file tools first
zip -r mimikatz_trunk.zip mimikatz/ && scripts/publish.sh binaries ./mimikatz_trunk.zip
```

`publish.sh` prints the exact `release://binaries/<file>` lines - paste them
into each `package.yaml`.

## Step 3 - move scripts into packages, delete binaries from git

```bash
mkdir -p packages/scripts/serve
git mv serve.py packages/scripts/serve/serve.py     # keep, served via raw://
git mv printerbug.py packages/scripts/printerbug/printerbug.py

# remove the heavy stuff from the working tree (now lives in Releases)
git rm chisel chisel.exe tun2socks nc64.exe rusthound-ce
git rm -r mimikatz
```

The committed binaries are still in your git **history**, bloating clones. To
actually slim the repo, purge them from history once (rewrites history - force
push, coordinate if anyone else has a clone):

```bash
pipx install git-filter-repo   # or: pip install git-filter-repo
git filter-repo --invert-paths \
  --path chisel --path chisel.exe --path tun2socks --path nc64.exe \
  --path rusthound-ce --path mimikatz --path nc64.exe
git push --force origin main
```

## Step 4 - write/aim the manifests, rebuild, push

```bash
scripts/new-tool.sh utils netcat        # scaffold a new one
$EDITOR packages/utils/netcat/package.yaml
python3 scripts/build-index.py          # refresh index.json locally
git add packages index.json && git commit -m "port netcat" && git push
```

The GitHub Action rebuilds `index.json` on push too, so even if you forget step
3's local rebuild, the published index stays correct.

## Adding NEW tooling later (the steady-state loop)

```bash
scripts/new-tool.sh <category> <name>           # 1. scaffold
scripts/publish.sh <tag> ./yourbinary           # 2. upload heavy file(s)
$EDITOR packages/<category>/<name>/package.yaml  # 3. paste the release:// url
python3 scripts/build-index.py                   # 4. (optional) local index
git add -A && git commit -m "add <name>" && git push   # 5. ship
```

Users pick it up with `armory update && armory install <name>`. No reinstall of
the manager, no re-cloning the vault.

## Don't commit `store/`

`store/` is where the manager downloads tools at runtime; it's already in
`.gitignore`. Never commit it - that would re-create the "huge repo" problem.
