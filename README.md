# finder-favorites

[![OpenSSF Baseline: not assessed](https://img.shields.io/badge/OpenSSF%20Baseline-not%20assessed-lightgrey)](https://baseline.openssf.org/)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/IanHollow/finder-favorites/badge)](https://scorecard.dev/viewer/?uri=github.com/IanHollow/finder-favorites)
[![OpenSSF Best Practices: not enrolled](https://img.shields.io/badge/OpenSSF%20Best%20Practices-not%20enrolled-lightgrey)](https://www.bestpractices.dev/)

`finder-favorites` keeps selected folders in the macOS Finder Favorites sidebar
from a JSON configuration. It works with Home Manager or as a standalone command.

## Install

On Apple silicon with macOS 14 or newer and Nix:

```console
nix profile install github:IanHollow/finder-favorites
```

The package is also available from
[`nixpkgs-personal`](https://github.com/nix-forge/nixpkgs-personal).
The [source releases](https://github.com/IanHollow/finder-favorites/releases)
contain versioned source archives, not a prebuilt executable.

## Quick start

Save the configuration below as `favorites.json`, replacing the example path
with a folder on your Mac. Preview changes before applying them:

```console
finder-favorites plan --config favorites.json
finder-favorites apply --config favorites.json
```

`apply` adds configured favorites without removing entries you manage in Finder.
Use `finder-favorites recover` if an interrupted write leaves a pending journal.

## Configuration format

```json
{
  "schemaVersion": 1,
  "placement": "bottom",
  "entries": [
    {
      "id": "downloads",
      "label": "Downloads",
      "path": "/Users/example/Downloads",
      "onMissing": "error"
    }
  ]
}
```

`onMissing` accepts `error`, `skip`, or `createDirectory`. Configuration is
limited to 1 MiB and 256 entries. IDs and canonical paths must be unique;
labels may repeat.

## How it works

Apple does not provide a supported API for programmatically managing Finder
Favorites. This tool uses the deprecated `LSSharedFileList` API because it is
the only native interface still shipped with current macOS SDKs. That API is
isolated in a small C adapter so the configuration, planning, transaction, and
recovery code remain independently testable.

## Safety model

- Additive only. Unmanaged favorites are never deleted.
- Identity is based on canonical paths and persistent sidebar item IDs, not
  mutable labels.
- A per-user lock prevents concurrent tool runs.
- Every write uses a private crash-recovery journal.
- Failures trigger rollback, and successful writes are verified from a fresh
  snapshot.
- Network volumes are never mounted and resolution never prompts the user.
- Running as root or through `sudo` is rejected.
- Tests use an in-memory backend and never touch the live Finder sidebar.

Finder itself can still change the sidebar concurrently. If that happens,
rerun `apply`. If a process is terminated during a write, run `recover` before
the next apply.

## Commands

```text
finder-favorites list [--json]
finder-favorites export
finder-favorites plan --config FILE [--json]
finder-favorites check --config FILE [--json]
finder-favorites apply --config FILE [--dry-run] [--json]
finder-favorites recover [--state-directory DIR]
finder-favorites doctor [--json]
```

`check` exits with status 1 when drift exists and 0 when the configuration is
already satisfied. Errors use status 2.

## Compatibility

The package targets macOS 14 or newer and is built for Apple silicon. The
backend is verified by automated bridge tests at build time and should be
treated as compatibility-sensitive because Apple may remove the deprecated API
in a future macOS release. `doctor` reports the active backend and architecture.

## Development quality gate

From this repository on macOS, run the quality suite with:

```console
Scripts/check-quality.sh
```

Use `nix develop` to supply the quality tools. `swift test` runs the Swift
package tests with Xcode alone. The suite checks Swift and C formatting,
SwiftLint, strict Swift 5 and Swift 6
compiler modes, complete concurrency checking, Periphery, Clang's full warning
set, clang-tidy, the Clang Static Analyzer, Nix, Bash, YAML, JSON, Markdown,
spelling, XCTest, Address Sanitizer, and Thread Sanitizer. Each compiler and
sanitizer lane has an isolated scratch directory. Set
`FINDER_FAVORITES_RUN_SANITIZERS=0` only for a quicker local iteration.

The shipping Nix compiler is Swift 5.10. Swift 6.2 strict memory-safety mode is
documented as a forward audit rather than a gate because its required `unsafe`
source annotations cannot be parsed by Swift 5.10. The C boundary remains
covered by explicit nullability, strict Clang diagnostics, two static analyzers,
and runtime sanitizers for every non-live code path.

## Nix packaging

`package.nix` is the current package recipe.
[`nixpkgs-personal`](https://github.com/nix-forge/nixpkgs-personal) fetches a
pinned revision of this repository and calls that recipe.

The repository flake supplies the pinned quality tools. On a supported Mac,
run `nix develop --command bash Scripts/check-quality.sh` and
`nix flake check` before submitting a change. CI runs both commands.

## Project health

Security and release expectations are documented in [SECURITY.md](SECURITY.md),
[SUPPORT.md](SUPPORT.md), and [security and release process](docs/security-and-releases.md).
Releases provide checksums and provenance for the source archives. The first
release is `v0.1.0`. The gray OpenSSF badges above indicate that this project
has not been enrolled or assessed by the Best Practices service; they do not
claim a Baseline level or a passing Best Practices status. SLSA claims, if any,
apply only to verified release archives, not to Nix builds or the repository.
