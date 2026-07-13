# SecureSphere REST API Design

## 1. Purpose and Scope

This document defines the REST API design for SecureSphere Version 1.0. It is based on the approved Project Vision, Software Requirements Specification, System Architecture, Logical Database Design, and Domain Model. The API provides the authenticated, organization-scoped interface used by the SecureSphere web application and approved future integrations.

This is a design specification, not backend or frontend code. It defines resource behavior, request and response conventions, security expectations, and representative OpenAPI-style examples. All protected behavior remains subject to server-side authentication, RBAC authorization, tenant isolation, validation, audit logging, and applicable security policy.

## 2. API Design Principles

- **Resource-oriented:** APIs expose stable business resources and their relationships rather than user-interface actions.
- **Organization-scoped by default:** Tenant-owned resources are accessed in an explicit organization context and never cross tenant boundaries.
- **Server-side authority:** The API is the enforcement point for authentication, authorization, validation, policy, and tenant isolation.
- **Least privilege:** A response contains only the resources, fields, and actions the requester is authorized to access.
- **Consistent contracts:** Requests, responses, pagination, filtering, sorting, errors, and timestamps use uniform conventions.
- **Secure by default:** HTTPS, input validation, anti-forgery protection where applicable, rate limiting, safe errors, and auditability apply to sensitive operations.
- **Backward-compatible evolution:** Public behavior evolves through documented API versions and deprecation practices.
- **Traceable operations:** Defined security-relevant and administrative changes create audit records without exposing secrets or unnecessary sensitive data.
- **No implied automation:** The API manages approved SecureSphere records and workflows; it does not authorize autonomous changes in customer environments.

## 3. API Versioning Strategy

### 3.1 Versioned Base Path

SecureSphere uses a URI-major-version strategy:

```text
/api/v1/
```

Examples:

```text
/api/v1/organizations
/api/v1/organizations/{organization_id}/assets
```

The initial supported version is `v1`. A breaking change requires a new major path version. Additive, backward-compatible fields, endpoints, filter values, and optional capabilities may be introduced within `v1` when they do not change existing semantics.

### 3.2 Compatibility and Deprecation

- API versions are documented with supported resources, fields, and behaviors.
- A supported version remains available through its published deprecation period.
- Before retiring a version, SecureSphere publishes migration guidance and the retirement timeline.
- Deprecated fields or endpoints remain behaviorally compatible until their published retirement date.
- Clients must not depend on undocumented fields, response ordering, internal identifiers, or error text.

## 4. Authentication and Authorization

### 4.1 Authentication

All non-public endpoints require an authenticated session or approved token. Authentication is completed server-side through the approved account-security workflow, which may include local credential validation, verified email requirements, and TOTP MFA according to applicable security policy.

The API does not expose passwords, session credentials, verification tokens, recovery tokens, TOTP secrets, or recovery codes in responses. Sensitive account changes require re-authentication where specified by policy.

Representative authentication header for token-based access:

```http
Authorization: Bearer <approved-access-token>
```

When cookie-based authentication is used, state-changing requests must include the applicable anti-forgery protection. API consumers must use HTTPS in production.

### 4.2 Authorization and Tenant Scope

- Every protected request is authenticated before authorization is evaluated.
- Tenant-owned resources are accessed through an organization URI segment or a resource whose organization scope is already established server-side.
- The caller must hold an active membership in the target organization and the role permission required for the requested action.
- The API denies access when the organization scope, role permission, resource relationship, or policy condition is invalid.
- The API does not reveal whether an unauthorized record exists in another organization.
- Platform-level administration, where explicitly approved, is separate from ordinary tenant workflows and remains subject to dedicated authorization.

## 5. URI Naming Conventions

- Use lowercase, plural nouns: `/assets`, `/vulnerabilities`, `/security-policies`.
- Use hyphens between multiword resource names: `/audit-logs`, `/risk-score-configurations`.
- Use UUID resource identifiers in paths: `/assets/{asset_id}`.
- Nest a resource only to express a stable organization or parent relationship: `/organizations/{organization_id}/assets`.
- Use collection paths for list and create operations; use an item path for retrieve, update, archive, restore, or close operations.
- Use subresources for meaningful relationships: `/vulnerabilities/{vulnerability_id}/assets`.
- Use narrowly scoped action suffixes only when no resource-oriented update expresses the business operation clearly, such as `/active-session/terminate-all-other`.
- Do not expose database table names, implementation-layer names, or internal storage paths.

## 6. Request Standards

### 6.1 Headers

| Header | Requirement |
| --- | --- |
| `Authorization` | Required for token-authenticated protected endpoints. |
| `Content-Type: application/json` | Required for JSON request bodies. |
| `Accept: application/json` | Recommended for all API consumers. |
| `Idempotency-Key` | Required or recommended for designated create or sensitive action endpoints. |
| Anti-forgery header | Required for state-changing cookie-authenticated requests, according to the approved authentication mechanism. |

### 6.2 Request Body Rules

- JSON member names use `snake_case`.
- UUIDs are represented as strings.
- Timestamps use ISO 8601 in UTC, for example `2026-07-13T10:30:00Z`.
- `null` is used only where a field is explicitly nullable; absent fields mean “not supplied” for partial updates.
- `POST` creates a resource or initiates a constrained domain action.
- `PATCH` applies a partial update to mutable fields.
- `PUT` is not used unless a future endpoint explicitly defines complete replacement semantics.
- State-changing requests are validated before any persistent change is committed.
- Unknown or read-only request fields are rejected or ignored only when documented; clients must not rely on silent acceptance.

### 6.3 OpenAPI-Style Request Schema Example

```yaml
VulnerabilityCreateRequest:
  type: object
  required:
    - title
    - description
    - severity
    - vulnerability_status
  properties:
    title:
      type: string
    description:
      type: string
    severity:
      type: string
      description: Approved vulnerability severity value.
    vulnerability_status:
      type: string
      description: Approved lifecycle status value.
    affected_asset_ids:
      type: array
      items:
        type: string
        format: uuid
    owner_membership_id:
      type: string
      format: uuid
      nullable: true
    owner_team_id:
      type: string
      format: uuid
      nullable: true
    remediation_target_at:
      type: string
      format: date-time
      nullable: true
```

All referenced IDs must be valid and belong to the target organization. Assignment and lifecycle rules are enforced by the vulnerability domain.

## 7. Response Standards

### 7.1 Resource Response Envelope

Single-resource success responses use a consistent envelope:

```json
{
  "data": {
    "id": "6ef07e80-8a0e-44a4-a0e1-2f3d1c44e7be",
    "resource_type": "asset",
    "name": "Production API",
    "asset_status": "active",
    "created_at": "2026-07-13T10:30:00Z",
    "updated_at": "2026-07-13T10:30:00Z"
  }
}
```

Responses include only fields authorized for the caller. Sensitive values and protected operational details are omitted rather than masked unless a documented response field requires a safe representation.

### 7.2 Collection Response Envelope

```json
{
  "data": [
    {
      "id": "6ef07e80-8a0e-44a4-a0e1-2f3d1c44e7be",
      "resource_type": "asset",
      "name": "Production API",
      "asset_status": "active"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 25,
    "total_count": 1,
    "total_pages": 1
  }
}
```

### 7.3 Representation Rules

- All timestamps are UTC ISO 8601 strings.
- UUIDs are opaque strings.
- Enumerated values use documented lowercase `snake_case` values unless a resource explicitly defines otherwise.
- Relationship references use IDs and, where authorized and useful, a safe display summary.
- `resource_type` is included where it clarifies polymorphic or search results.
- Responses must not infer permissions from hidden UI behavior; any available action is enforced when called.

## 8. Error Response Format

All errors use a consistent envelope. Error messages are safe for clients and do not expose secrets, stack traces, tenant details, or whether inaccessible resources exist.

```json
{
  "error": {
    "code": "validation_failed",
    "message": "The request could not be processed.",
    "details": [
      {
        "field": "severity",
        "code": "invalid_choice",
        "message": "Select an approved severity value."
      }
    ],
    "request_id": "a4b59980-7bdb-4c81-b19c-e99a1da42b95"
  }
}
```

| Field | Meaning |
| --- | --- |
| `code` | Stable machine-readable error category. |
| `message` | Safe human-readable summary. |
| `details` | Optional field- or rule-level validation details appropriate for the caller. |
| `request_id` | Correlation identifier for authorized operational support. |

Representative error codes include `authentication_required`, `permission_denied`, `resource_not_found`, `validation_failed`, `conflict`, `rate_limited`, `idempotency_conflict`, and `policy_violation`.

## 9. HTTP Status Code Usage

| Status | Use |
| --- | --- |
| `200 OK` | Successful retrieve, list, search, partial update, acknowledgement, or supported action with a response body. |
| `201 Created` | Successful creation of a resource. Include the created resource and a `Location` header where applicable. |
| `202 Accepted` | Accepted asynchronous processing request when the approved workflow does not complete immediately. |
| `204 No Content` | Successful deletion only for resources whose approved lifecycle permits it, or a successful action with no response body. SecureSphere generally archives, deactivates, or revokes rather than hard-deletes. |
| `400 Bad Request` | Malformed JSON, invalid query syntax, or invalid request structure. |
| `401 Unauthorized` | Missing, expired, invalid, or otherwise unacceptable authentication. |
| `403 Forbidden` | Authenticated caller lacks permission or fails an applicable policy condition. |
| `404 Not Found` | Resource does not exist or is not disclosed to the caller. |
| `409 Conflict` | Conflict with current resource state, duplicate relationship, invalid lifecycle transition, or incompatible idempotency-key reuse. |
| `412 Precondition Failed` | A documented conditional request precondition fails, if conditional updates are introduced. |
| `422 Unprocessable Content` | Structurally valid request fails a domain validation or business-rule check. |
| `429 Too Many Requests` | Rate limit exceeded. Include `Retry-After` where applicable. |
| `500 Internal Server Error` | Unexpected server failure. Return only a generic safe message and request correlation ID. |
| `503 Service Unavailable` | Temporary service unavailability or dependency outage. |

## 10. Pagination

Collection endpoints use page-number pagination in Version 1.0:

```text
GET /api/v1/organizations/{organization_id}/assets?page=2&page_size=25
```

| Parameter | Rule |
| --- | --- |
| `page` | Optional positive integer. Default is `1`. |
| `page_size` | Optional positive integer. Default and maximum are documented by endpoint policy. Requests over the maximum are rejected or constrained according to documented behavior. |

The collection response includes `page`, `page_size`, `total_count`, and `total_pages`. Clients must provide a deterministic sort order when processing multiple pages. The server applies a stable default order when none is supplied.

## 11. Filtering

Filters use query parameters with explicit names and documented values. Unsupported filters and malformed values return a validation error rather than being ignored.

Examples:

```text
GET /api/v1/organizations/{organization_id}/assets?asset_status=active&owner_membership_id={membership_id}
GET /api/v1/organizations/{organization_id}/vulnerabilities?severity=critical&vulnerability_status=active_remediation
GET /api/v1/organizations/{organization_id}/incidents?incident_status=active_response&response_team_id={team_id}
GET /api/v1/organizations/{organization_id}/audit-logs?event_type=incident_closed&occurred_after=2026-07-01T00:00:00Z
```

Common filter rules:

- Use exact-match parameters for IDs, status, severity, type, and ownership.
- Use `*_after` and `*_before` for validated UTC time ranges.
- Use documented comma-separated values only where an endpoint explicitly permits multiple values.
- The server applies organization scope and authorization before evaluating results.
- Filters do not make hidden resource fields searchable or reveal cross-tenant data.

## 12. Sorting

Collection endpoints accept a `sort` parameter containing one approved field. Prefix a field with `-` for descending order.

```text
GET /api/v1/organizations/{organization_id}/vulnerabilities?sort=-remediation_target_at
GET /api/v1/organizations/{organization_id}/audit-logs?sort=-occurred_at
```

Each endpoint documents its sortable fields. Typical approved fields include `created_at`, `updated_at`, severity, status, remediation target time, and occurrence time. The server always applies a stable UUID tie-breaker when primary sort values are equal. Arbitrary field or expression sorting is not supported.

## 13. Search

Enterprise search provides authorized, organization-scoped discovery across approved asset, vulnerability, incident, user, team, and audit-log records.

```text
GET /api/v1/organizations/{organization_id}/search?q=production&type=asset,vulnerability&page=1&page_size=25
```

| Parameter | Rule |
| --- | --- |
| `q` | Required non-empty, normalized search query within configured length limits. |
| `type` | Optional comma-separated list from approved searchable resource types. |
| `page`, `page_size` | Standard pagination parameters. |
| `sort` | Optional approved result sort where supported. |

Search returns only result types, fields, and navigation references authorized for the requesting membership. It is not a cross-tenant search service, a full-text evidence index, a natural-language search function, or a platform-administrator discovery mechanism in Version 1.0.

## 14. Rate Limiting

Rate limiting protects availability and security-sensitive workflows. Limits are applied by endpoint category, authenticated principal where available, and additional safe request context as approved by security policy. Exact thresholds are operational policy values and are not hard-coded into this design.

| Endpoint Category | Rate-Limiting Requirement |
| --- | --- |
| Authentication, email verification, password recovery, and MFA verification | Strict protection against brute force, enumeration, and abuse. |
| Session, trusted-device, recovery-code, and password changes | Strict protection due to account-security impact. |
| General authenticated reads and lists | Limits sufficient to protect service availability while supporting normal use. |
| Search and audit-log queries | Limits appropriate to their potential query cost and sensitive information value. |
| Create and update operations | Limits appropriate to protect data integrity and prevent abusive writes. |

When limited, the API returns `429 Too Many Requests`, a safe error envelope, and `Retry-After` where applicable. Rate-limit responses do not disclose internal thresholds or tenant details.

## 15. Idempotency

Clients use `Idempotency-Key` for designated create and sensitive action requests, particularly where retries could duplicate a security record, notification-triggering action, session change, MFA operation, or recovery action.

```http
Idempotency-Key: 9f0ca45d-91b6-47e8-89e5-12f74c76d3ee
```

Idempotency behavior:

- The key is scoped to the authenticated principal, request method, target operation, and organization context where applicable.
- Repeating the same request with the same key and materially identical payload returns the original successful result while the key remains valid.
- Reusing a key with a materially different request returns `409 Conflict` with `idempotency_conflict`.
- The server retains keys and outcomes for an approved, documented period.
- Idempotency does not bypass authorization, validation, tenant isolation, or lifecycle rules.

`PATCH` operations are naturally retryable only when their documented semantics and concurrency expectations permit it; sensitive action endpoints should still support idempotency where retries are likely.

## 16. Endpoint Catalog

All paths below are relative to `/api/v1`. `{organization_id}` is a UUID for the active tenant scope. The catalog defines the intended resource surface; actual field-level visibility and action availability remain permission-controlled.

### 16.1 Authentication and Account Security

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/auth/login` | Initiate authentication with approved credentials. |
| `POST` | `/auth/mfa/verify` | Complete a required TOTP or recovery-code MFA challenge. |
| `POST` | `/auth/logout` | Terminate the current authenticated session. |
| `POST` | `/auth/password-recovery` | Initiate non-enumerating account recovery. |
| `POST` | `/auth/password-recovery/confirm` | Complete password recovery using an approved recovery response. |
| `POST` | `/auth/email-verification` | Request email verification for the authenticated or eligible account workflow. |
| `POST` | `/auth/email-verification/confirm` | Confirm an email-verification response. |
| `GET` | `/auth/mfa` | Retrieve authorized MFA enrollment status without exposing secret material. |
| `POST` | `/auth/mfa/enroll` | Begin TOTP enrollment. |
| `POST` | `/auth/mfa/confirm` | Verify and activate a pending TOTP enrollment. |
| `POST` | `/auth/mfa/disable` | Disable active MFA after required re-authentication and policy checks. |
| `POST` | `/auth/recovery-codes/regenerate` | Regenerate recovery codes after required verification. |
| `GET` | `/auth/sessions` | List the caller’s active sessions. |
| `DELETE` | `/auth/sessions/{session_id}` | Revoke one of the caller’s active sessions. |
| `POST` | `/auth/sessions/terminate-all-other` | Revoke all other active sessions for the caller. |
| `GET` | `/auth/devices` | List the caller’s recognized and trusted devices. |
| `DELETE` | `/auth/devices/{device_id}` | Revoke a caller-owned trusted device. |
| `PATCH` | `/auth/password` | Change a local password subject to policy and re-authentication. |

### 16.2 Organizations and Memberships

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/organizations` | List organizations available to the authenticated user. |
| `POST` | `/organizations` | Create an organization when authorized by approved onboarding policy. |
| `GET` | `/organizations/{organization_id}` | Retrieve an authorized organization profile. |
| `PATCH` | `/organizations/{organization_id}` | Update organization profile information. |
| `GET` | `/organizations/{organization_id}/memberships` | List authorized organization memberships. |
| `POST` | `/organizations/{organization_id}/memberships` | Invite or create an organization membership through the approved workflow. |
| `GET` | `/organizations/{organization_id}/memberships/{membership_id}` | Retrieve an authorized membership. |
| `PATCH` | `/organizations/{organization_id}/memberships/{membership_id}` | Update membership lifecycle or approved profile context. |
| `POST` | `/organizations/{organization_id}/memberships/{membership_id}/deactivate` | Deactivate membership and apply required access consequences. |
| `POST` | `/organizations/{organization_id}/memberships/{membership_id}/reactivate` | Reactivate membership when authorized. |

### 16.3 Users

`User` is a globally authenticated account, while organization visibility is represented through memberships. Version 1.0 exposes user records only in authorized organization context and never exposes protected account-security material.

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/organizations/{organization_id}/users` | List users represented by authorized memberships. |
| `GET` | `/organizations/{organization_id}/users/{user_id}` | Retrieve authorized user summary and membership context. |
| `PATCH` | `/users/me` | Update the caller’s permitted account profile fields. |
| `GET` | `/users/me` | Retrieve the caller’s safe account summary. |

### 16.4 Teams

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/organizations/{organization_id}/teams` | List teams. |
| `POST` | `/organizations/{organization_id}/teams` | Create a team. |
| `GET` | `/organizations/{organization_id}/teams/{team_id}` | Retrieve a team. |
| `PATCH` | `/organizations/{organization_id}/teams/{team_id}` | Update team details. |
| `POST` | `/organizations/{organization_id}/teams/{team_id}/archive` | Archive a team. |
| `POST` | `/organizations/{organization_id}/teams/{team_id}/restore` | Restore an archived team when authorized. |
| `GET` | `/organizations/{organization_id}/teams/{team_id}/members` | List team memberships. |
| `POST` | `/organizations/{organization_id}/teams/{team_id}/members` | Add an active organization membership to a team. |
| `DELETE` | `/organizations/{organization_id}/teams/{team_id}/members/{membership_id}` | Remove a member from a team. |

### 16.5 RBAC

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/permissions` | List approved permission definitions available to the caller. |
| `GET` | `/organizations/{organization_id}/roles` | List authorized organization roles. |
| `POST` | `/organizations/{organization_id}/roles` | Create an organization role. |
| `GET` | `/organizations/{organization_id}/roles/{role_id}` | Retrieve a role and authorized permission grants. |
| `PATCH` | `/organizations/{organization_id}/roles/{role_id}` | Update a role’s allowed mutable details. |
| `POST` | `/organizations/{organization_id}/roles/{role_id}/archive` | Archive a role. |
| `PUT` | `/organizations/{organization_id}/roles/{role_id}/permissions` | Replace the role’s permission grants as one documented relationship update. |
| `GET` | `/organizations/{organization_id}/memberships/{membership_id}/roles` | List roles assigned to a membership. |
| `PUT` | `/organizations/{organization_id}/memberships/{membership_id}/roles` | Replace membership role assignments as one documented relationship update. |

### 16.6 Assets

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/organizations/{organization_id}/assets` | List authorized assets with filtering, sorting, and pagination. |
| `POST` | `/organizations/{organization_id}/assets` | Create an asset. |
| `GET` | `/organizations/{organization_id}/assets/{asset_id}` | Retrieve an asset. |
| `PATCH` | `/organizations/{organization_id}/assets/{asset_id}` | Update mutable asset fields. |
| `POST` | `/organizations/{organization_id}/assets/{asset_id}/archive` | Archive an asset. |
| `POST` | `/organizations/{organization_id}/assets/{asset_id}/restore` | Restore an archived asset. |
| `GET` | `/organizations/{organization_id}/assets/{asset_id}/vulnerabilities` | List authorized associated vulnerabilities. |
| `GET` | `/organizations/{organization_id}/assets/{asset_id}/incidents` | List authorized associated incidents. |

### 16.7 Vulnerabilities

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/organizations/{organization_id}/vulnerabilities` | List authorized vulnerabilities with filtering, sorting, and pagination. |
| `POST` | `/organizations/{organization_id}/vulnerabilities` | Create a vulnerability. |
| `GET` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}` | Retrieve a vulnerability. |
| `PATCH` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}` | Update mutable vulnerability fields, including approved assignment and target changes. |
| `POST` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}/close` | Close a vulnerability when lifecycle rules are met. |
| `POST` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}/reopen` | Reopen a vulnerability with an authorized reason. |
| `POST` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}/archive` | Archive a vulnerability. |
| `POST` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}/restore` | Restore an archived vulnerability. |
| `GET` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}/assets` | List affected assets. |
| `PUT` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}/assets` | Replace authorized affected-asset relationships. |
| `GET` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}/remediation-updates` | List remediation history. |
| `POST` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}/remediation-updates` | Record a remediation update. |
| `GET` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}/evidence` | List authorized evidence metadata. |
| `POST` | `/organizations/{organization_id}/vulnerabilities/{vulnerability_id}/evidence` | Attach approved evidence through the documented upload workflow. |

### 16.8 Incidents

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/organizations/{organization_id}/incidents` | List authorized incidents with filtering, sorting, and pagination. |
| `POST` | `/organizations/{organization_id}/incidents` | Create an incident. |
| `GET` | `/organizations/{organization_id}/incidents/{incident_id}` | Retrieve an incident. |
| `PATCH` | `/organizations/{organization_id}/incidents/{incident_id}` | Update mutable incident fields. |
| `POST` | `/organizations/{organization_id}/incidents/{incident_id}/contain` | Record an authorized containment transition and action. |
| `POST` | `/organizations/{organization_id}/incidents/{incident_id}/resolve` | Record resolution summary and resolution transition. |
| `POST` | `/organizations/{organization_id}/incidents/{incident_id}/close` | Close an incident when lifecycle rules are met. |
| `POST` | `/organizations/{organization_id}/incidents/{incident_id}/reopen` | Reopen an incident with an authorized reason. |
| `GET` | `/organizations/{organization_id}/incidents/{incident_id}/assets` | List affected assets. |
| `PUT` | `/organizations/{organization_id}/incidents/{incident_id}/assets` | Replace authorized affected-asset relationships. |
| `GET` | `/organizations/{organization_id}/incidents/{incident_id}/vulnerabilities` | List related vulnerabilities. |
| `PUT` | `/organizations/{organization_id}/incidents/{incident_id}/vulnerabilities` | Replace authorized vulnerability relationships. |
| `GET` | `/organizations/{organization_id}/incidents/{incident_id}/remediation-updates` | List incident activity and remediation history. |
| `POST` | `/organizations/{organization_id}/incidents/{incident_id}/remediation-updates` | Record an incident remediation update. |
| `GET` | `/organizations/{organization_id}/incidents/{incident_id}/evidence` | List authorized evidence metadata. |
| `POST` | `/organizations/{organization_id}/incidents/{incident_id}/evidence` | Attach approved evidence through the documented upload workflow. |

### 16.9 Notifications

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/organizations/{organization_id}/notifications` | List notifications for the caller’s membership. |
| `GET` | `/organizations/{organization_id}/notifications/{notification_id}` | Retrieve one caller-owned notification. |
| `POST` | `/organizations/{organization_id}/notifications/{notification_id}/acknowledge` | Acknowledge a notification. |

### 16.10 Audit Logs

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/organizations/{organization_id}/audit-logs` | Search and filter authorized audit records. |
| `GET` | `/organizations/{organization_id}/audit-logs/{audit_log_id}` | Retrieve one authorized audit record. |

Audit logs are append-only; Version 1.0 exposes no ordinary create, update, archive, or delete endpoint for them.

### 16.11 Dashboard and Risk Scoring

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/organizations/{organization_id}/dashboard` | Retrieve the caller’s authorized dashboard summary and configured widgets. |
| `GET` | `/organizations/{organization_id}/dashboard/configuration` | Retrieve the caller’s dashboard configuration. |
| `PATCH` | `/organizations/{organization_id}/dashboard/configuration` | Update permitted dashboard layout and widget configuration. |
| `GET` | `/organizations/{organization_id}/risk-score` | Retrieve the current authorized organizational risk score and contributor context. |
| `GET` | `/organizations/{organization_id}/risk-scores` | List retained risk-score snapshots. |
| `GET` | `/organizations/{organization_id}/risk-score-configurations` | List authorized risk-score configurations. |
| `POST` | `/organizations/{organization_id}/risk-score-configurations` | Create an authorized configuration. |
| `PATCH` | `/organizations/{organization_id}/risk-score-configurations/{configuration_id}` | Update configuration before or through approved activation workflow. |
| `POST` | `/organizations/{organization_id}/risk-score-configurations/{configuration_id}/activate` | Activate a configuration when authorized. |

### 16.12 Security Policies

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/organizations/{organization_id}/security-policies` | List authorized organization security policies. |
| `POST` | `/organizations/{organization_id}/security-policies` | Create a security policy. |
| `GET` | `/organizations/{organization_id}/security-policies/{policy_id}` | Retrieve a policy and authorized current content. |
| `PATCH` | `/organizations/{organization_id}/security-policies/{policy_id}` | Update mutable policy content and create required revision history. |
| `POST` | `/organizations/{organization_id}/security-policies/{policy_id}/activate` | Activate a policy. |
| `POST` | `/organizations/{organization_id}/security-policies/{policy_id}/deactivate` | Deactivate a policy. |
| `POST` | `/organizations/{organization_id}/security-policies/{policy_id}/archive` | Archive a policy. |
| `GET` | `/organizations/{organization_id}/security-policies/{policy_id}/revisions` | List authorized policy revisions. |

### 16.13 Enterprise Search

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/organizations/{organization_id}/search` | Search authorized assets, vulnerabilities, incidents, users, teams, and audit-log records. |

## 17. Example Requests and Responses

### 17.1 Create a Vulnerability

```http
POST /api/v1/organizations/7c044c5d-0b12-47b9-bec1-840849fd805d/vulnerabilities HTTP/1.1
Authorization: Bearer <approved-access-token>
Content-Type: application/json
Accept: application/json
Idempotency-Key: 4f06e7b5-6f8e-431c-ac49-49ad517d9ab4

{
  "title": "Unsupported component on production API",
  "description": "A production asset uses a component requiring remediation.",
  "severity": "high",
  "vulnerability_status": "active_remediation",
  "affected_asset_ids": [
    "6ef07e80-8a0e-44a4-a0e1-2f3d1c44e7be"
  ],
  "owner_team_id": "5f58d3e3-c6d5-4547-a1fe-fbda22cf564f",
  "remediation_target_at": "2026-07-31T17:00:00Z"
}
```

```http
HTTP/1.1 201 Created
Location: /api/v1/organizations/7c044c5d-0b12-47b9-bec1-840849fd805d/vulnerabilities/90d2cd1e-0c6e-4648-b1c3-a4c555cfcce9
Content-Type: application/json

{
  "data": {
    "id": "90d2cd1e-0c6e-4648-b1c3-a4c555cfcce9",
    "resource_type": "vulnerability",
    "title": "Unsupported component on production API",
    "severity": "high",
    "vulnerability_status": "active_remediation",
    "affected_asset_ids": [
      "6ef07e80-8a0e-44a4-a0e1-2f3d1c44e7be"
    ],
    "owner_team_id": "5f58d3e3-c6d5-4547-a1fe-fbda22cf564f",
    "remediation_target_at": "2026-07-31T17:00:00Z",
    "created_at": "2026-07-13T10:30:00Z",
    "updated_at": "2026-07-13T10:30:00Z"
  }
}
```

### 17.2 List Filtered Vulnerabilities

```http
GET /api/v1/organizations/7c044c5d-0b12-47b9-bec1-840849fd805d/vulnerabilities?severity=high&vulnerability_status=active_remediation&sort=-remediation_target_at&page=1&page_size=25 HTTP/1.1
Authorization: Bearer <approved-access-token>
Accept: application/json
```

```json
{
  "data": [
    {
      "id": "90d2cd1e-0c6e-4648-b1c3-a4c555cfcce9",
      "resource_type": "vulnerability",
      "title": "Unsupported component on production API",
      "severity": "high",
      "vulnerability_status": "active_remediation",
      "remediation_target_at": "2026-07-31T17:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 25,
    "total_count": 1,
    "total_pages": 1
  }
}
```

### 17.3 Acknowledge a Notification

```http
POST /api/v1/organizations/7c044c5d-0b12-47b9-bec1-840849fd805d/notifications/f41995d5-d1b5-45b5-aa19-a8dfce1167f5/acknowledge HTTP/1.1
Authorization: Bearer <approved-access-token>
Idempotency-Key: e4bf6fd8-6de7-4321-b2d3-84513da728f8
Accept: application/json
```

```json
{
  "data": {
    "id": "f41995d5-d1b5-45b5-aa19-a8dfce1167f5",
    "resource_type": "notification",
    "notification_type": "vulnerability_assigned",
    "acknowledged_at": "2026-07-13T11:00:00Z"
  }
}
```

### 17.4 Validation Failure

```http
HTTP/1.1 422 Unprocessable Content
Content-Type: application/json

{
  "error": {
    "code": "validation_failed",
    "message": "The request could not be processed.",
    "details": [
      {
        "field": "affected_asset_ids[0]",
        "code": "organization_scope_mismatch",
        "message": "The referenced asset is not available in this organization."
      }
    ],
    "request_id": "c11ed1fc-c3c3-4c90-95b2-09a8fb20f98f"
  }
}
```

### 17.5 Organization-Scoped Search

```http
GET /api/v1/organizations/7c044c5d-0b12-47b9-bec1-840849fd805d/search?q=production&type=asset,vulnerability&page=1&page_size=10 HTTP/1.1
Authorization: Bearer <approved-access-token>
Accept: application/json
```

```json
{
  "data": [
    {
      "id": "6ef07e80-8a0e-44a4-a0e1-2f3d1c44e7be",
      "resource_type": "asset",
      "title": "Production API",
      "navigation_path": "/assets/6ef07e80-8a0e-44a4-a0e1-2f3d1c44e7be"
    },
    {
      "id": "90d2cd1e-0c6e-4648-b1c3-a4c555cfcce9",
      "resource_type": "vulnerability",
      "title": "Unsupported component on production API",
      "navigation_path": "/vulnerabilities/90d2cd1e-0c6e-4648-b1c3-a4c555cfcce9"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 10,
    "total_count": 2,
    "total_pages": 1
  }
}
```

## 18. API Security Best Practices

- Require HTTPS for production API traffic and protect all non-public endpoints with authentication.
- Enforce RBAC, policy checks, and tenant scope server-side on every request, object relationship, search result, object-storage operation, and background task initiated by the API.
- Treat every request value as untrusted; validate structure, type, format, size, ownership, lifecycle compatibility, and authorization before use.
- Use parameterized data access and framework protections against injection vulnerabilities.
- Apply anti-forgery protection to state-changing cookie-authenticated requests.
- Apply output encoding and appropriate security headers to mitigate browser-based attacks.
- Rate-limit authentication, recovery, MFA, session, trusted-device, search, and other sensitive endpoints.
- Require re-authentication for sensitive account-security actions such as MFA changes, recovery-code regeneration, session revocation where required, and trusted-device changes.
- Return generic authentication and recovery errors that do not disclose account existence, protected resource existence, internal configuration, or implementation details.
- Do not expose or log passwords, tokens, secrets, TOTP material, recovery codes, or unnecessary sensitive customer data.
- Use protected or digest-only representations for sensitive security values and invalidate recovery codes, revoked devices, and revoked sessions immediately.
- Restrict file and evidence access through backend authorization; object-storage keys are not access grants.
- Record required audit events for authentication, access-management, security-record, MFA, recovery-code, password, session, trusted-device, security-policy, and risk-score configuration changes.
- Keep API versions documented, preserve supported-version compatibility, and publish deprecation guidance before retirement.
- Test unauthorized, cross-organization, invalid-lifecycle, malformed-input, rate-limit, and sensitive-data-exposure paths alongside successful API behavior.
