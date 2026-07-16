# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows semantic-style release notes even if Git tags are still lightweight.

## [Unreleased]

### Added

- observability baseline with correlation IDs, sanitized AI logs, Prometheus business metrics and Grafana dashboard
- Sentry-ready backend and Flutter integrations activated only when a DSN is provided
- operational docs: architecture, runbook, API and database references

### Changed

- Spring Boot upgraded to `3.3.13`
- backend Java target aligned to `21`
- Docker runtime and local compose flow hardened for production-readiness work

### Fixed

- historical Flyway migration gap documentation aligned with the actual `V1` to `V9` chain

### Security

- CV ownership is enforced before every CV-backed AI call and private DOCX export

## [1.0.0] - 2026-07-13

### Added

- Flutter application for CV creation, editing, AI assistance and exports
- Spring Boot API with auth, CV management, imports, uploads and notifications
- Docker local stack with PostgreSQL and Adminer

### Security

- secret scanning workflow with Gitleaks
- stricter startup validation for critical backend secrets
