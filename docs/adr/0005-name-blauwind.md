# ADR 0005 — Project name: Blauwind

- **Status:** Accepted
- **Decided:** 2026-09-18

## Context

The project began as **Blauer Zimt** — "blue cinnamon", Bluefin plus the Cinnamon
desktop. ADR 0002 replaced Cinnamon with Sway, and the name stopped describing
the project. Milestone 3 publishes the image under a registry name, a repository
name and an `os-release` identity; renaming before that is cheap, renaming after
it is not.

## Decision

The project is **Blauwind** — "blue wind": *blau* keeps the Bluefin lineage, and
wind is what makes things sway. In documents the name is written `Blauwind`; in
every technical identifier — repository, directory, image name, `os-release`
`VARIANT_ID`, file names — it is `blauwind`, lowercase, one word.

## Consequences

- Renamed 2026-09-18: the GitHub repository (`kevinnowak/blauwind`; GitHub
  redirects the old URL), the working directory, the image (`localhost/blauwind:44`,
  later `ghcr.io/kevinnowak/blauwind`), `os-release` (`NAME`, `PRETTY_NAME`,
  `VARIANT`, `VARIANT_ID=blauwind`), the dnf drop-in, and every living document
  (`CLAUDE.md`, `PLAN.md`, `README.md`, comments in the Containerfile and
  `system_files/`).
- ADRs 0001–0004 keep "Blauer Zimt" where they say it: they record decisions
  made under that name, and history is not rewritten.
- Nothing had been published under the old name; no external reference needs
  updating.
