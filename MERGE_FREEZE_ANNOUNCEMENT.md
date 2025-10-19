# Merge Freeze Announcement – Digest-Driven Integration Migration (Phase 0)

Effective immediately, we are freezing merges to `main` while we transition to digest-driven integration.

Scope:
- Integration repo: replace submodules/workspaces with GHCR image digests.
- Backend & Frontend repos: add publish workflows to GHCR with cosign + SBOM.

Expected duration: 1–2 business days.

Allowed exceptions:
- CI/doc-only changes that do not modify runtime behavior.

Contact: Platform Team.
