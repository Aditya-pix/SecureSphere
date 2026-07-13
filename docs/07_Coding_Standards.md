# SecureSphere Coding Standards

## 1. Purpose

This document defines the coding, review, testing, and delivery standards for SecureSphere. Its purpose is to keep the enterprise-grade cybersecurity SaaS platform secure, maintainable, auditable, and consistent as it evolves.

These standards apply to backend, frontend, tests, automation, deployment-adjacent application configuration, and documentation changes. They complement the approved Project Vision, SRS, System Architecture, Database Design, Domain Model, API Design, and repository guidance.

## 2. Engineering Principles

- Build security by design: use secure defaults, least privilege, tenant isolation, validation at trust boundaries, and defense in depth.
- Preserve the approved modular architecture: presentation, transport, domain, persistence, and background-processing concerns remain separate.
- Keep business logic out of Django views, serializers, React components, and route handlers. Use focused domain and service layers where appropriate.
- Prefer composition over duplication. Extract shared, stable behavior into explicit reusable units; do not create abstractions that obscure a simple use case.
- Make changes small, focused, testable, and reviewable.
- Treat organization scope as mandatory for all tenant-owned data and operations.
- Make security-relevant actions auditable without logging secrets or unnecessary sensitive data.
- Prefer explicit behavior, meaningful names, and simple control flow over cleverness.
- Do not invent requirements, add dependencies, or introduce new technologies without approval.
- Update relevant documentation whenever behavior, configuration, APIs, architecture, or operations change.

## 3. Python Coding Standards

- Follow PEP 8 for formatting, imports, whitespace, line structure, and general readability.
- Use the project’s approved formatter, linter, and import-order tooling consistently once established; do not hand-format around tool output.
- Every public function, method, and class interface includes complete type hints for parameters and return values. Use precise domain types rather than broad untyped containers where practical.
- Internal functions also use type hints when they cross module boundaries, contain non-obvious data shapes, or contribute to security-sensitive behavior.
- Use docstrings for public modules, classes, and functions when purpose, contract, side effects, exceptions, security rules, or non-obvious constraints need explanation. Do not add docstrings that only repeat a function name.
- Keep functions focused on one responsibility. Split long or deeply nested logic into named helpers or domain services.
- Prefer immutable local values and explicit return values where they improve predictability.
- Avoid mutable default arguments, broad exception handling, hidden global state, dynamic attribute access, and implicit type coercion in business logic.
- Use standard library and framework facilities before introducing a dependency.
- Use UTC-aware datetime values for persisted or compared business times.

Example: a public service operation that changes a vulnerability’s owner should declare the UUID-based input identifiers and its precise result type, document authorization and lifecycle preconditions when non-obvious, and leave HTTP parsing to the view layer.

## 4. Django Standards

- Organize Django application modules by approved business domain: account security; organization, teams, and RBAC; assets; vulnerabilities; incidents; dashboards and risk; audit, notifications, and search; and security policies.
- Keep views and Django REST Framework view classes thin. They authenticate the request, invoke serializer or request validation, call the appropriate service or domain operation, and translate the result into the documented API response.
- Keep serializers focused on transport validation and representation. They must not become the primary location for cross-domain workflow logic or authorization decisions.
- Place domain rules, lifecycle transitions, authorization-aware business operations, and orchestration in focused service layers where appropriate.
- Use model-level constraints and validation to reinforce invariants, but do not rely on client-side or model-only validation for authorization-sensitive workflows.
- Scope every tenant-owned query by the authorized organization before retrieval, update, archival, relationship change, file access, search, or background processing.
- Use Django ORM parameterization and approved framework protections. Never construct database queries by interpolating untrusted input.
- Keep migrations focused, reviewed, reversible where practical, and compatible with safe production rollout. Do not edit applied migrations.
- Use Django transactions for multi-record state changes that must succeed or fail together, such as single-use recovery-code consumption, lifecycle transition plus history creation, or related assignment changes.
- Background tasks must invoke the same domain rules and organization-scope checks as interactive requests; queue execution is not a trust boundary bypass.
- Store uploaded evidence through approved MinIO or AWS S3 integration, never in the application container filesystem.

## 5. React Standards

- Use React and TypeScript for the approved browser-based presentation layer.
- Keep components focused on rendering, interaction, accessible behavior, and local presentation state.
- Keep business logic, authorization decisions, tenant-isolation enforcement, and lifecycle rules out of React components. The backend remains authoritative.
- Compose small components from well-defined props and explicit state rather than duplicating markup and interaction behavior across screens.
- Use reusable presentation hooks or utilities only when they represent stable shared UI behavior; avoid generic abstractions created for a single component.
- Keep data fetching, mutation state, loading state, empty state, error state, and success feedback explicit and accessible.
- Do not assume a hidden button or route guard provides authorization. Use the API response and permission-aware UI only as a usability aid.
- Render only safe, encoded text and approved rich content. Do not introduce unsafe HTML rendering for user-controlled values.
- Use Tailwind CSS consistently with established project patterns. Prefer reusable semantic component composition over repeated, unstructured utility collections.
- Ensure keyboard operation, focus management, labels, error messages, contrast, and status announcements meet the approved accessibility standard.

Example: an incident screen may conditionally display a close action when the user has an indicated permission, but the close request is valid only when the server confirms authorization and lifecycle conditions.

## 6. TypeScript Standards

- Enable and preserve strict TypeScript settings once established by the project.
- Avoid `any`. Use explicit interfaces, type aliases, discriminated unions, nullable types, and narrow runtime checks appropriate to the API contract.
- Type all public component props, exported functions, hooks, service clients, and event handlers.
- Represent API responses, error envelopes, pagination, filter values, and domain statuses with explicit types that match the approved API design.
- Treat all API data as untrusted at the client boundary; handle absent, nullable, unsupported, and error values safely.
- Prefer `unknown` for unvalidated external data and narrow it before use.
- Avoid non-null assertions unless an invariant is local, obvious, and enforced immediately beforehand.
- Do not duplicate backend authorization or lifecycle logic as a source of truth. Client types may model allowed states for presentation but cannot grant a transition.
- Use UUID values as opaque string identifiers; do not parse meaning from them or use array indexes as business identifiers.

## 7. Folder Structure Standards

The repository layout remains aligned with the approved monorepo structure:

| Directory | Standard |
| --- | --- |
| `backend/` | Django application code, backend tests, and backend configuration organized by approved domain and shared cross-cutting concerns. |
| `frontend/` | React, TypeScript, Tailwind CSS, frontend tests, and presentation-layer modules. |
| `docs/` | Approved product, architecture, design, operational, and decision documentation. |
| `infrastructure/` | Environment and deployment definitions; no application business logic. |
| `docker/` | Container-related definitions and supporting configuration. |
| `scripts/` | Focused automation and maintenance scripts with documented purpose and safe behavior. |
| `tests/` | Cross-cutting test suites and shared test resources when not owned by a backend or frontend module. |
| `.github/workflows/` | GitHub Actions workflow definitions only. |

Within backend and frontend directories, organize code by the approved domain modules and clear responsibilities. Shared utilities must be small, stable, and genuinely cross-domain. Avoid broad catch-all folders such as `common`, `utils`, or `helpers` unless their contents have a narrowly documented responsibility.

## 8. Naming Conventions

| Context | Convention |
| --- | --- |
| Python modules, functions, variables, attributes | `snake_case` |
| Python classes, exceptions, Django models, service types | `PascalCase` |
| Python constants | `UPPER_SNAKE_CASE` |
| TypeScript variables and functions | `camelCase` |
| React components, TypeScript interfaces, and type aliases | `PascalCase` |
| TypeScript constants | `UPPER_SNAKE_CASE` only for true immutable global constants; otherwise `camelCase` |
| API JSON fields and query parameters | `snake_case` |
| URI path resources | lowercase plural nouns with hyphens between words |
| Database logical entities | singular `PascalCase`; logical attributes use `snake_case` |
| UUID identifiers | `<entity>_id`, such as `organization_id` or `vulnerability_id` |
| Boolean fields | `is_`, `has_`, `can_`, or another unambiguous predicate prefix |
| Time fields | explicit UTC-aware lifecycle names such as `created_at`, `expires_at`, `acknowledged_at`, or `archived_at` |

Names should communicate business meaning. Prefer `remediation_target_at` over an ambiguous name such as `deadline`, and `owner_membership_id` over `user_id` when organization-scoped ownership is intended.

## 9. Logging Standards

- Use structured logging with consistent event names and contextual fields.
- Include safe operational context such as request correlation ID, organization ID where authorized and necessary, actor or membership ID where applicable, event type, resource type, resource ID, outcome, and error category.
- Log security-relevant and administrative actions through the approved audit mechanism; application logs do not replace audit logs.
- Use appropriate log levels: debug for local diagnostic detail, info for normal lifecycle events, warning for recoverable or suspicious conditions, and error for failed operations requiring attention.
- Never log passwords, access tokens, session credentials, TOTP secrets, recovery codes, verification or recovery tokens, raw authorization headers, secret configuration, or unnecessary sensitive customer data.
- Do not log complete request or response bodies by default. Redact or omit sensitive fields when diagnostic context is necessary.
- Use safe, stable event names such as `vulnerability_assigned`, `incident_closed`, `mfa_enrollment_verified`, or `session_revoked`.
- Ensure background workers use the same redaction, correlation, organization-scope, and error-logging standards as web application processes.

## 10. Error Handling Standards

- Validate early at each trust boundary and return or raise errors that preserve a clear separation between expected domain failures and unexpected system failures.
- Use explicit domain errors for authorization denial, tenant-scope mismatch, validation failure, invalid lifecycle transition, policy violation, conflict, not-found behavior, and rate limiting.
- Map expected domain errors to the approved API error envelope and status-code semantics.
- Provide generic client-facing error messages for authentication, recovery, authorization, and unexpected failures. Do not disclose account existence, protected resource existence, internal configuration, stack traces, or implementation details.
- Preserve safe correlation information for authorized support and operational investigation.
- Do not catch broad exceptions merely to continue execution or return success. Handle a known exception narrowly or allow it to reach the approved centralized error handling path.
- Use transactions and failure-safe ordering for operations that consume one-time security values, change lifecycle state, create history, or emit notification eligibility.
- React error states must be clear, actionable, and accessible, but must not display raw backend internals.

## 11. API Implementation Standards

- Implement the approved versioned REST design under `/api/v1/` and preserve backward-compatible behavior within the version.
- Use resource-oriented, plural, lowercase paths and UUID identifiers. Do not expose database table names, filesystem paths, or internal implementation names.
- Keep view handlers thin and delegate domain behavior to service layers where appropriate.
- Authenticate every protected request and enforce RBAC, policy checks, and tenant scope before reading or changing a resource.
- Validate request JSON, query parameters, UUIDs, timestamps, filters, sorting values, relationship IDs, file metadata, and lifecycle transitions.
- Use the approved response envelope, collection pagination envelope, and error response format consistently.
- Return only authorized fields and related-resource summaries. Avoid over-fetching or leaking relationship details through serialization.
- Apply documented pagination, filtering, sorting, and organization-scoped search behavior. Reject unsupported filters and sort fields rather than silently ignoring them.
- Support idempotency for designated create and sensitive action requests. Idempotency never bypasses authorization, validation, or tenant isolation.
- Apply rate limiting to authentication, recovery, MFA, session, trusted-device, search, and other sensitive endpoints.
- Use consistent UTC ISO 8601 timestamps and opaque UUID strings.
- Create required audit records for security-sensitive and administrative API actions.

## 12. Database Standards

- PostgreSQL is the durable relational system of record for SecureSphere business data. Redis is limited to approved caching and Celery queue coordination.
- Use UUID primary keys for durable entities and UUID foreign keys for relationships. Do not use sequential IDs as business identifiers.
- Every organization-owned entity carries or derives explicit organization scope. Queries, joins, related managers, and background work must enforce that scope.
- Use explicit foreign keys, uniqueness constraints, check constraints, and transactions to protect domain invariants.
- Represent many-to-many relationships with explicit junction concepts when membership, assignment, timestamps, or audit context matter.
- Apply the approved audit fields consistently: creation and update timestamps, actor context where meaningful, and archival fields where soft deletion applies.
- Use archival, deactivation, closure, revocation, expiration, or retention rather than hard deletion when the domain requires recovery, history, or auditability.
- Do not mutate append-only audit logs, remediation updates, policy revisions, risk-score snapshots, or other retained historical facts through ordinary workflows.
- Index organization scope, active lifecycle state, relationship foreign keys, authorization lookups, operational filtering, audit review, notifications, dashboards, risk views, and approved search paths.
- Use parameterized ORM access and approved framework protections; never interpolate untrusted values into database queries.
- Review migration impact, backfill needs, locks, indexing cost, data retention, rollback strategy, and tenant-isolation implications before release.

## 13. Security Coding Checklist

Before completing a security-relevant change, confirm the following:

- [ ] All external input is validated, normalized, and authorized server-side.
- [ ] Every tenant-owned read, write, relationship change, file operation, search path, cache use, and background task enforces organization scope.
- [ ] RBAC uses least privilege and denies by default.
- [ ] Authentication, recovery, MFA, sessions, and trusted-device changes follow the approved policy and re-authentication rules.
- [ ] Passwords, tokens, secrets, TOTP material, recovery codes, and unnecessary sensitive data are neither exposed nor logged.
- [ ] Parameterized data access and framework protections prevent injection.
- [ ] Browser-facing output is encoded and state-changing cookie-authenticated requests use anti-forgery protection.
- [ ] Rate limiting protects authentication, recovery, MFA, session, device, search, and sensitive write operations.
- [ ] Error responses are safe and do not reveal protected resource or account existence.
- [ ] Object-storage access is authorized through SecureSphere records; storage keys are not treated as access grants.
- [ ] Security-relevant and administrative changes create required audit records.
- [ ] Dependencies, containers, configuration, and deployment changes have been reviewed for security impact.
- [ ] Tests cover unauthorized, cross-organization, invalid-input, invalid-lifecycle, and sensitive-data-exposure paths.

These practices implement SecureSphere’s OWASP-aligned secure coding approach and must be applied proportionately to all changes.

## 14. Testing Standards

- Add or update tests for every changed behavior. Test expected behavior, failure behavior, authorization, validation, and relevant lifecycle transitions.
- Keep tests deterministic, isolated, readable, and independent of execution order.
- Use focused unit tests for domain rules and service-layer behavior.
- Use integration tests for Django persistence, tenant-scoped relationships, authorization boundaries, transactions, and API request-to-response behavior.
- Use frontend tests for component behavior, accessibility-relevant states, loading, empty, error, and permission-aware presentation behavior.
- Test API contracts for response envelopes, error formats, pagination, filters, sorting, search, versioning, rate-limit handling where testable, and field-level authorization.
- Test account-security workflows for non-enumeration, password policy, MFA, recovery-code single use, session revocation, trusted-device revocation, and re-authentication requirements.
- Test background tasks with the same organization-scope and domain-rule expectations as interactive workflows.
- Use representative UUIDs and isolated organization fixtures. Every multi-tenant test suite includes positive and negative cross-organization cases.
- Do not weaken, skip, or delete tests solely to make a change pass. If a requirement changes, update its tests and supporting documentation deliberately.
- Run the smallest relevant formatter, lint, type-check, and test suites during development, then run the required project checks before review.

## 15. Git Workflow

- Create a focused branch from the current integration branch using the approved branch naming strategy.
- Keep each branch and pull request scoped to one coherent objective.
- Keep commits small and logically coherent; avoid mixed refactors, formatting-only changes, dependency changes, and feature work in the same commit unless inseparable and explained.
- Rebase or merge the current integration branch as required by repository policy before opening a pull request.
- Do not force-push shared branches or rewrite another contributor’s work without explicit approval.
- Do not commit directly to protected branches.
- Preserve unrelated local changes and do not modify unrelated files.
- Resolve merge conflicts with attention to security rules, domain invariants, and test coverage; do not choose a conflict side mechanically.

## 16. Conventional Commit Messages

Use Conventional Commits:

```text
<type>(<optional scope>): <short imperative summary>
```

Allowed types include `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `build`, `ci`, `perf`, and `security`.

Rules:

- Use an imperative, specific summary with no trailing period.
- Use a scope when it improves clarity, such as `auth`, `rbac`, `assets`, `api`, `docs`, or `security`.
- Include a body when the change has a security impact, migration step, behavior change, or material architectural trade-off.
- Reference approved issue or work-item identifiers only when the repository workflow defines them.
- Do not disguise breaking changes, dependency changes, or security-impacting behavior as a generic `chore`.

Examples:

- `feat(vulnerabilities): add remediation ownership tracking`
- `fix(auth): revoke sessions after password reset`
- `security(search): enforce organization scope for results`
- `docs: document API error envelope`

## 17. Branch Naming Strategy

Use lowercase branch names with a category prefix and concise hyphen-separated description:

```text
<category>/<short-description>
```

| Category | Use |
| --- | --- |
| `feature/` | New approved capability. |
| `fix/` | Defect correction. |
| `security/` | Security control, vulnerability remediation, or hardening work. |
| `docs/` | Documentation-only change. |
| `test/` | Test-focused change. |
| `refactor/` | Behavior-preserving structural improvement. |
| `chore/` | Maintenance that does not fit another category. |
| `ci/` | GitHub Actions or delivery workflow change. |

Examples: `feature/incident-remediation-history`, `security/mfa-recovery-code-reuse`, and `docs/api-design`.

## 18. Pull Request Checklist

- [ ] The pull request has a clear, scoped purpose and does not modify unrelated files.
- [ ] The implementation follows the approved modular architecture and keeps business logic out of views and React components.
- [ ] Relevant service-layer, domain, API, integration, and frontend behavior is covered by tests as applicable.
- [ ] Relevant formatting, linting, type-checking, and test checks pass.
- [ ] Tenant isolation, RBAC, input validation, lifecycle rules, and error handling were considered.
- [ ] Security-sensitive values are not exposed, logged, or included in fixtures.
- [ ] Required audit events and notification behavior were considered for security-relevant changes.
- [ ] Database changes use UUIDs, preserve integrity, include needed indexes, and have safe migration considerations.
- [ ] API changes follow the approved versioning, URI, request, response, error, pagination, filter, sorting, and idempotency standards.
- [ ] Documentation is updated for behavior, configuration, API, architecture, data design, or operational changes.
- [ ] Commit messages follow Conventional Commits.
- [ ] Significant architectural decisions and trade-offs are explained in the pull request description.

## 19. Code Review Checklist

- [ ] The change implements an approved requirement and does not introduce unrelated scope.
- [ ] Names, boundaries, and control flow communicate the intended business behavior.
- [ ] Public Python and TypeScript interfaces are typed; public behavior is documented where needed.
- [ ] Business logic is located in the relevant domain or service layer, not embedded in views, serializers, route handlers, or React components.
- [ ] Reuse is achieved through appropriate composition rather than copied behavior or premature abstraction.
- [ ] Authorization is server-side, least-privilege, and organization-scoped for every relevant path.
- [ ] Validation protects untrusted input, relationships, state transitions, and sensitive operations.
- [ ] Errors are safe, consistent, and do not leak security-sensitive information.
- [ ] Logging and audit behavior provide sufficient traceability without recording secrets.
- [ ] Transactions, idempotency, concurrency, and retry behavior are appropriate for state-changing or one-time operations.
- [ ] Tests demonstrate both authorized success and meaningful failure or denial paths.
- [ ] The change preserves compatibility or documents any approved versioning and migration impact.

## 20. Documentation Standards

- Maintain documentation in `docs/` using clear, professional Markdown with descriptive file names and stable headings.
- Update the SRS when approved requirements, constraints, acceptance criteria, or out-of-scope boundaries change.
- Update architecture, database, domain, or API documentation when a change affects component boundaries, data relationships, business behavior, API contracts, security controls, or operational interfaces.
- Record significant architectural decisions, alternatives, constraints, and trade-offs in the appropriate documentation rather than leaving them implicit in code review history.
- Keep examples consistent with approved terminology, UUID identifiers, organization scope, and security rules.
- Avoid documenting secrets, credentials, internal endpoints, unapproved dependencies, or unsupported operational claims.
- Keep Mermaid diagrams and OpenAPI-style examples synchronized with the documented design when they are affected.
- Documentation-only changes follow the same accuracy, review, and commit standards as code changes.

## 21. Definition of Done (DoD)

A SecureSphere change is done only when all applicable conditions are satisfied:

- The change implements an approved, clearly understood requirement.
- The solution follows the approved modular architecture and domain model.
- Business logic is separated from views, serializers, React components, and other presentation or transport layers.
- Public interfaces are typed and non-obvious behavior is documented.
- Tenant isolation, RBAC, OWASP-aligned secure coding practices, validation, error handling, auditability, and sensitive-data handling are addressed.
- UUID identity, database integrity, lifecycle, migration, and indexing considerations are addressed for persistent-data changes.
- Relevant tests are added or updated and required quality checks pass.
- API changes comply with the approved API design and are backward-compatible within the supported version, or their approved versioning impact is documented.
- Documentation is updated wherever behavior, configuration, architecture, data design, API contract, security posture, or operations changed.
- The pull request is focused, reviewable, uses Conventional Commits, and explains significant architectural or security decisions.
- Required review feedback is resolved and no known critical security, correctness, or tenant-isolation issue remains unaddressed.
