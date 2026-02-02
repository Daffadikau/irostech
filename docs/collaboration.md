# Collaboration Baseline

## Roles & Ownership
- **Tech lead**: prioritizes, reviews architecture, approves merges
- **Feature owners**: own components and keep docs updated
- **Ops/contact**: manages CI and environment

Update ownership in .github/CODEOWNERS.

## Roadmap
See docs/roadmap.md for Now/Next/Later planning.

## Branching & PRs
- Branch naming: `feature/*`, `fix/*`, `docs/*`
- PRs require at least 1 reviewer
- Link issues in PR description

## Conventions
- Python formatting: black (line length 100)
- Linting: ruff
- Commit messages: Conventional Commits

## CI
CI runs lint, format check, and compile check on every PR.

## Work Tracking
Use a shared board (GitHub Projects or Trello) with:
- Backlog → In Progress → Review → Done
- Clear acceptance criteria and Definition of Done

## Communication
- Daily async updates in a shared channel
- Weekly sync (15–30 min)
- Document decisions in docs/decisions.md

## Templates
- Issues: .github/ISSUE_TEMPLATE/
- PRs: .github/PULL_REQUEST_TEMPLATE.md
- Meeting notes: templates/meeting-notes.md

## Metrics
Track lead time, defects, and throughput in docs/metrics.md.
