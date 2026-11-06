# cyfrin-course-researcher-security-audit

Security audit resolutions for the [Cyfrin security researcher course](https://updraft.cyfrin.io/).

Each folder in this repository holds one audited project: the original codebase, the added proof-of-concept tests, and the full audit report under its `audit/` directory.

## Projects

| # | Project | Status | Report |
|---|---------|--------|--------|
| 1 | [PasswordStore](./3-passwordstore-audit) | ✅ Completed | [PasswordStore-report.md](./3-passwordstore-audit/audit/PasswordStore-report.md) |

## Structure

Every project folder follows the same layout:

- `src/` — the original contracts under audit
- `test/` — the original tests plus the proof-of-concept tests from the audit
- `audit/` — the audit report and status files
- `foundry.toml`, `Makefile`, `lib/` — Foundry project configuration and dependencies

## Requirements

- [Foundry](https://getfoundry.sh/)

```bash
git clone --recursive https://github.com/Santidele22/cyfrin-course-researcher-security-audit.git
cd cyfrin-course-researcher-security-audit/<project-folder>
make install
forge test
```
