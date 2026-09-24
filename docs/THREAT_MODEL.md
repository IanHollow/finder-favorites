# Threat model

Finder Favorites reads a declarative JSON configuration and macOS sidebar state, then makes additive changes through `LSSharedFileList`. It writes a private crash-recovery journal and uses a per-user lock. Configured paths and sidebar entries are untrusted inputs; other local processes may change the sidebar concurrently.

The trust boundaries are JSON parsing, filesystem paths and symlinks, the Finder API, and journal recovery. A malformed configuration must not delete unmanaged entries. Concurrent writes or a crash must not corrupt sidebar state or cause recovery to replay an unsafe operation. The tool rejects root execution and does not mount network volumes or prompt during path resolution.

Security review should inspect canonical path checks, lock and journal permissions, recovery idempotence, rollback after partial writes, and concurrent Finder modifications. Tests use an in-memory backend; live Finder behavior requires a manual macOS test before a release.
