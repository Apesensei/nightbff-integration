# Team Protocol: Integration Repo

Follow backend docs for ports and stack ownership.

- Integration backend: 3000, DB: 5435, Metro: 8081
- Start stack:
  - `docker compose up -d` (if compose file provided in this repo)
  - Or use backend integration compose if this repo references images only

Health checks:

- Backend: http://localhost:3000/health

When in doubt:

- See backend repo README Quickstart
- Use PR template checklist
