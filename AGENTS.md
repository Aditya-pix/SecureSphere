# SecureSphere Agent Guide

## 1. Project Overview

SecureSphere is an enterprise-grade cybersecurity SaaS platform. The repository is designed for security-first software engineering, with clear separation between client applications, server-side services, infrastructure, automation, and documentation.

## 2. Technology Stack

- Backend: Python, Django, and Django REST Framework
- Frontend: React and TypeScript
- Data stores: PostgreSQL and Redis
- Containers: Docker
- Continuous integration and delivery: GitHub Actions

## 3. Repository Structure

```text
backend/                Server-side services and APIs
frontend/               Client-facing web application
docs/                   Architecture, product, and operational documentation
infrastructure/         Environment and deployment configuration
docker/                 Container-related definitions and configuration
scripts/                Automation and maintenance scripts
tests/                  Cross-cutting automated tests and test resources
.github/workflows/      GitHub Actions workflow definitions
```

Keep components within their intended directory. Avoid coupling application code to deployment, automation, or documentation concerns.

## 4. Coding Standards

- Write clear, maintainable, idiomatic code for the relevant language and framework.
- Use consistent formatting, naming, typing, and linting conventions established by the project.
- Keep functions, modules, and components focused on a single responsibility.
- Separate business logic from presentation and transport layers.
- Prefer explicit, testable behavior over implicit side effects.
- Avoid duplication; extract shared behavior only when it improves clarity and reuse.
- Add comments only where they explain intent, trade-offs, or non-obvious behavior.

## 5. Security-First Development Principles

- Follow OWASP secure coding practices and apply least privilege by default.
- Treat all external input as untrusted; validate, normalize, and authorize it at appropriate boundaries.
- Enforce authentication and authorization server-side for every protected action.
- Never hard-code, commit, log, or expose secrets, credentials, tokens, or sensitive customer data.
- Use parameterized queries and framework protections to prevent injection vulnerabilities.
- Protect sensitive data in transit and at rest; minimize collection and retention.
- Use secure defaults, fail safely, and avoid disclosing implementation details in errors.
- Review dependencies and configuration changes for security impact before adoption.

## 6. Documentation Requirements

- Update relevant documentation whenever behavior, configuration, APIs, architecture, or operational procedures change.
- Document public APIs, configuration values, security considerations, and required deployment steps.
- Record significant architectural decisions and their rationale in `docs/`.
- Keep documentation accurate, concise, and aligned with the implementation.

## 7. Testing Requirements

- Add or update tests for changed behavior, including both expected and failure paths.
- Cover authorization, validation, and security-sensitive behavior with focused tests.
- Keep tests deterministic, isolated, and readable.
- Run relevant formatting, linting, type-checking, and test suites before submitting changes.
- Do not weaken, skip, or delete tests merely to make a change pass.

## 8. Git Workflow

- Create focused branches from the current integration branch using descriptive names, such as `feature/audit-events` or `fix/session-timeout`.
- Keep commits small and logically coherent.
- Rebase or merge the current integration branch as required by repository policy before opening a pull request.
- Do not force-push shared branches or rewrite others' work without explicit approval.
- Use pull requests for review; do not commit directly to protected branches.

## 9. Conventional Commit Message Rules

Use Conventional Commits:

```text
<type>(<optional scope>): <short imperative summary>
```

Allowed types include `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `build`, `ci`, `perf`, and `security`.

Examples:

```text
feat(auth): add organization-aware login
fix(api): reject expired access tokens
docs: document local development setup
security(session): rotate refresh tokens on use
```

Use a concise imperative summary, keep it specific, and include a body when context, migration steps, or security impact needs explanation.

## 10. Pull Request Checklist

- [ ] The change has a clear, scoped purpose and does not modify unrelated files.
- [ ] Relevant tests were added or updated and pass.
- [ ] Relevant formatting, linting, and type checks pass.
- [ ] Security implications, authorization, input validation, and error handling were considered.
- [ ] No secrets, credentials, or sensitive data are included.
- [ ] Documentation is updated where behavior, configuration, APIs, or architecture changed.
- [ ] Significant architectural decisions and trade-offs are explained.
- [ ] Commit messages follow Conventional Commits.

## 11. Rules for AI Agents

- Never invent requirements; implement only what is specified or clearly established in the repository.
- Never modify unrelated files.
- Prefer small, reviewable changes.
- Ask for clarification when requirements are ambiguous or when a choice would materially alter behavior or architecture.
- Do not add, remove, or upgrade dependencies without approval.
- Follow OWASP secure coding practices.
- Keep business logic separate from presentation.
- Write clean, maintainable code.
- Update documentation when code changes.
- Explain significant architectural decisions, including alternatives and trade-offs when relevant.
- Preserve existing user changes and repository conventions.
- Verify changes with the smallest relevant checks before reporting completion.
