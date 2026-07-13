# SecureSphere Domain Model

## 1. Purpose and Scope

This document defines the business domain model for SecureSphere Version 1.0. It derives from the approved Software Requirements Specification, System Architecture, and Logical Database Design. It describes the platform’s business concepts, rules, lifecycle behavior, authorization expectations, and meaningful business events.

The model is intentionally independent of code, APIs, and database schema. A domain event in this document is a meaningful business fact that may drive audit recording, in-application notification, dashboard refresh, or approved background processing; it does not prescribe a new messaging technology or external integration.

## 2. Domain-Wide Rules

- **Organization scope:** Security operations, governance, dashboards, notifications, and search are scoped to one organization. A user acts in an organization through an active organization membership.
- **Server-side authority:** Authentication, authorization, tenant isolation, validation, and business rules are enforced server-side. Presentation behavior never grants a permission.
- **Least privilege:** Access is denied unless an active membership has a role with the required permission for the action and organization.
- **Auditability:** Defined security-relevant and administrative actions create restricted, time-ordered audit records. Historical facts are retained where the approved design requires them.
- **Lifecycle over destruction:** Records with operational, security, or audit value are deactivated, closed, archived, revoked, expired, or retained rather than silently removed.
- **UTC and traceability:** Persisted business times are UTC. Material changes identify the relevant actor where one exists.
- **Sensitive-data minimization:** Credentials, tokens, secrets, recovery codes, and unnecessary customer data are not exposed in ordinary views, events, or logs.

## 3. Domain Map

| Domain | Primary Business Concepts |
| --- | --- |
| Account Security | User account, email verification, password policy and recovery, TOTP MFA, recovery codes, device, active session |
| Organization, Teams, and RBAC | Organization, organization membership, team, role, permission, role assignment |
| Asset Management | Asset, business context, technical metadata, ownership |
| Vulnerability Management | Vulnerability, affected asset, assignment, remediation target, remediation update, evidence |
| Incident Management | Incident, affected asset, related vulnerability, response team, timeline, containment, resolution |
| Dashboards and Risk Scoring | Dashboard configuration, dashboard widget, organizational risk score, risk-score configuration |
| Security Policy Management | Security policy, policy revision, applicable scope, configured values |
| Audit, Notifications, and Search | Audit event, in-application notification, authorized organization-scoped search |

## 4. Account Security Domain

### Purpose

Provide a secure account lifecycle for authenticated users, including local credential use where approved, email verification, recovery, TOTP MFA, single-use recovery codes, device recognition, trusted-device control, and active-session management.

### Responsibilities

- Authenticate a user only after approved credential validation.
- Require email verification and MFA when required by applicable policy.
- Apply the configured password policy to password creation, reset, and change workflows.
- Allow secure account recovery without disclosing whether an account exists.
- Allow users to enroll, verify, replace, and disable TOTP MFA subject to re-authentication and policy.
- Generate recovery codes after MFA enrollment and make each code usable only once.
- Present users with their active sessions and trusted devices and allow authorized revocation.

### Business Rules

- A user account is global; organization access is granted separately through active organization memberships.
- An account must be active before it can authenticate.
- Successful authentication creates an authenticated session or token only after all required account-security checks pass.
- A user must verify email ownership before using the account-recovery and MFA-reset actions defined by policy, except for a documented authorized administrative recovery process.
- A recovery request must return a non-enumerating response regardless of whether the supplied account identifier exists.
- TOTP enrollment is not complete until the authenticator is verified.
- Recovery codes are issued as a defined set, are shown only at generation time, and are invalid immediately after use.
- A trusted device is a user-associated device that has not been revoked and is within the approved trust duration; it is not a substitute for server-side authorization.
- Security-relevant credential changes or account deactivation invalidate sessions according to approved policy.

### Lifecycle

1. An account is created or becomes available through an approved organization-user workflow.
2. The user verifies email ownership when required.
3. The user authenticates with approved credentials and completes required MFA.
4. The system records session and device activity.
5. The user may enroll or manage MFA, review sessions and devices, change credentials, or initiate recovery.
6. The account may be deactivated; active sessions become invalid under policy while historic audit records remain retained.

### State Transitions

| Concept | Valid Transitions |
| --- | --- |
| User account | active → deactivated; deactivated → active only through authorized administration |
| Email verification | pending → verified; pending → expired; expired → pending through a new request |
| MFA authenticator | enrollment pending → active; active → disabled; disabled → enrollment pending through new enrollment |
| Recovery code | available → used; available → revoked; used and revoked are terminal |
| Device | recognized → trusted; recognized or trusted → revoked; revoked is not trusted |
| Active session | active → expired; active → revoked; expired and revoked are not valid for authentication |
| Recovery request | pending → used; pending → expired; used and expired are terminal |

### Validation Rules

- Account identifiers and email addresses are normalized and validated under approved account policy.
- Local passwords must meet approved length, complexity, reuse, and compromise-screening requirements where supported.
- Password values, session credentials, verification tokens, recovery tokens, TOTP secrets, and recovery codes are never persisted or logged in plaintext.
- A TOTP response must be validated against an active or pending authenticator within the applicable time window.
- A recovery code must match an available protected value and must be marked used atomically with successful use.
- Session, device, verification, and recovery records must have valid time boundaries; expired or revoked records cannot be reactivated by ordinary use.

### Permission Rules

- A user may view and manage only their own MFA settings, recovery codes, active sessions, and trusted devices, subject to re-authentication requirements.
- A user may terminate their own individual session or all other active sessions.
- An authorized administrative recovery process is restricted to the designated administrator role and must be audited.
- Platform or organization administrators do not gain access to plaintext account secrets, credentials, recovery codes, or TOTP secrets.

### Relationships

- A user may have many email-verification attempts, password-history entries, recovery requests, devices, active sessions, and MFA enrollment records.
- One active MFA authenticator has zero or many recovery codes.
- A device may be associated with zero or many active sessions.
- A user may have memberships in multiple organizations; account security remains user-scoped while business actions are organization-scoped.

### Events Generated

- Email verification requested, completed, or expired.
- Authentication succeeded, failed, or was denied by account state or MFA policy.
- MFA enrollment started, verified, disabled, or replaced.
- Recovery codes generated, regenerated, used, or revoked.
- Password changed, reset, or recovery requested and completed.
- Device recognized, trusted, or revoked.
- Session created, expired, revoked, or terminated by the user.
- Account activated or deactivated.

### Constraints

- Version 1.0 supports TOTP MFA and recovery codes only; hardware security keys and passkeys are out of scope.
- Session duration, trusted-device duration, MFA enforcement, and password-policy values require formal security and product approval.
- Enterprise single sign-on and automated provisioning are out of scope for Version 1.0.

### Examples

- A Security Analyst signs in, completes required TOTP verification, and receives a new active session linked to the browser device. The authentication and session creation are auditable.
- A user loses their authenticator and uses one unused recovery code. That code is permanently invalidated, and the user can enroll a replacement authenticator after required verification.
- An Organization Administrator deactivates a departing employee’s membership. The account’s organization access ends and applicable active sessions are invalidated according to policy.

## 5. Organization, Teams, and RBAC Domain

### Purpose

Establish the SecureSphere multi-tenant boundary and control who can access and act on organization-scoped security information.

### Responsibilities

- Manage organization profile information.
- Invite, activate, deactivate, and remove organization users through membership lifecycle management.
- Create, update, archive, and manage teams.
- Add and remove organization members from teams.
- Assign roles and evaluate permissions through RBAC.
- Provide authorized review of users, roles, teams, and memberships.

### Business Rules

- An organization is the tenant boundary for its security records, settings, policies, dashboards, and operational activity.
- A user must have an active organization membership to access that organization’s data.
- A membership may hold one or more roles; permissions are granted through those roles.
- A role may contain one or more permissions, and permissions are evaluated on the server for every protected action.
- Teams contain only members of the same organization and support work ownership and response coordination.
- Removing or deactivating a membership removes its effective organization access; historic ownership, updates, and audit facts remain attributable to the former membership.
- An organization-scoped role cannot be assigned to a membership in another organization.

### Lifecycle

1. An organization is created and configured by an authorized administrator.
2. Users are invited and become active members after the approved access process.
3. Administrators create teams and assign members and roles.
4. Members perform authorized business actions in the organization context.
5. Memberships, teams, and roles may be updated, deactivated, or archived while preserving history.

### State Transitions

| Concept | Valid Transitions |
| --- | --- |
| Organization | active → archived; archived → active only through authorized restoration if approved |
| Organization membership | invited or pending → active; active → deactivated; deactivated → active only through authorized reactivation |
| Team | active → archived; archived → active only through authorized restoration |
| Role | active → archived; archived roles grant no new effective access |
| Team membership | active → removed; removal ends team membership but retains historic attribution |

### Validation Rules

- Organization names and slugs must satisfy approved uniqueness and format rules.
- A membership must reference one existing user and one organization.
- Team names must be unique within the organization where required by organization policy.
- A team member must hold an active membership in the same organization as the team.
- Every role assignment must reference a role that is valid for the membership’s organization or an approved platform-level role.
- Role and permission changes must not create a cross-organization grant.

### Permission Rules

- Organization Administrators manage organization profile information, membership lifecycle, teams, and organization-level access within their organization.
- Security Managers and Security Analysts receive only the access granted by their roles.
- Team Members may perform assigned work only within their authorized teams and organization scope.
- Read-Only Viewers may review authorized information but cannot change it.
- Platform Administrators perform only authorized platform-level administration and do not bypass tenant isolation for ordinary organization workflows.

### Relationships

- One user may have many organization memberships; each membership belongs to one user and one organization.
- An organization has many memberships, teams, roles, and organization-owned business records.
- Memberships and teams are many-to-many through team membership.
- Memberships and roles are many-to-many through role assignment.
- Roles and permissions are many-to-many through role-permission grants.
- Memberships may be owners, assignees, actors, recipients, or dashboard configurators for organization-scoped domains.

### Events Generated

- Organization created, updated, archived, or restored.
- User invited, membership activated, deactivated, removed, or reactivated.
- Team created, updated, archived, restored, member added, or member removed.
- Role created, changed, archived, assigned, or removed.
- Permission grant changed.

### Constraints

- Tenant isolation is mandatory and applies to every database query, file action, search result, background task, and API response.
- Direct commits or presentation-layer state cannot grant a permission; all authorization is evaluated server-side.
- Cross-tenant collaboration and platform-administrator search are out of scope for Version 1.0.

### Examples

- An Organization Administrator creates a response team and adds active Security Analysts from the same organization.
- A Security Manager receives a role that permits vulnerability assignment but not organization membership administration.
- A Read-Only Viewer can review an incident dashboard but cannot change an incident’s status or owner.

## 6. Asset Management Domain

### Purpose

Maintain a reliable organization-scoped inventory of security-relevant technology resources and provide the context required to assess vulnerabilities and incidents.

### Responsibilities

- Create, view, update, archive, and restore asset records.
- Capture asset identity, type, owner, status, business context, and relevant technical metadata.
- Support authorized search, filtering, and sorting.
- Preserve an asset’s associations with vulnerabilities and incidents.

### Business Rules

- Every asset belongs to exactly one organization.
- An asset may have an accountable owner membership, but ownership is optional when not yet assigned.
- An asset may be associated with many vulnerabilities and incidents, and each vulnerability or incident may affect many assets.
- Archiving an asset does not remove its historic relationship to vulnerabilities or incidents.
- Asset metadata supports security context but must not become a channel for secrets or unvalidated content.

### Lifecycle

1. An authorized user records an asset with its required context.
2. The asset is maintained as its ownership, status, business context, or technical metadata changes.
3. Vulnerabilities and incidents are associated as relevant.
4. The asset is archived when no longer active and may be restored through an authorized workflow.

### State Transitions

| Concept | Valid Transitions |
| --- | --- |
| Asset record | active → archived; archived → active through authorized restoration |
| Asset ownership | unassigned → assigned; assigned → reassigned; assigned → unassigned when permitted |
| Asset operational status | transitions among approved organization-defined statuses while the record remains active |

### Validation Rules

- An asset name, type, and status are required.
- Any owner membership must be active and belong to the same organization as the asset.
- Business context and technical metadata must satisfy approved format, size, and content validation rules.
- An asset-vulnerability or asset-incident association must reference records within the same organization.
- Archived assets are excluded from default active-inventory views but remain visible to authorized historical workflows.

### Permission Rules

- Authorized Security Analysts and Security Managers may manage assets according to their RBAC permissions.
- Team Members may update assets only when their assigned permissions grant that action.
- Read-Only Viewers may review only the assets and fields permitted by their role.
- Organization Administrators manage access but do not receive asset-edit rights unless granted by role.

### Relationships

- An organization has many assets.
- An asset may have one owner membership.
- Assets and vulnerabilities are many-to-many.
- Assets and incidents are many-to-many.
- Assets contribute approved context to organizational risk scoring and dashboard summaries.

### Events Generated

- Asset created, updated, archived, restored, or ownership changed.
- Asset associated with or disassociated from a vulnerability or incident.
- Asset technical or business context changed.

### Constraints

- Version 1.0 is not a discovery or scanning product; assets are managed records rather than automatically discovered infrastructure.
- External asset-ingestion integrations are out of scope unless separately approved.
- Asset access is always organization-scoped and authorization-filtered.

### Examples

- A Security Analyst records a production application asset with an owner, business context, and technical metadata.
- When the application is decommissioned, an authorized user archives it; previously linked vulnerabilities remain historically connected.

## 7. Vulnerability Management Domain

### Purpose

Track organization-scoped security vulnerabilities from identification through prioritized remediation and closure, with accountable ownership and auditable history.

### Responsibilities

- Create, view, update, assign, prioritize, and close vulnerability records.
- Capture severity, status, description, affected assets, owner, remediation target date, and evidence or references.
- Provide filtering and prioritization by severity, status, ownership, asset, and target date.
- Preserve material status, ownership, and remediation history.

### Business Rules

- Every vulnerability belongs to one organization.
- A vulnerability may affect many assets, and an asset may be affected by many vulnerabilities.
- A vulnerability may be assigned to an accountable membership, a coordinating team, or both when approved workflow requires both forms of ownership.
- All assigned memberships, teams, assets, evidence, and related incidents must belong to the vulnerability’s organization.
- Closing a vulnerability requires an authorized status transition and a resolution outcome consistent with policy.
- Material changes create remediation updates and audit records as required.
- Severity, exposure, remediation state, and approved business context contribute to organizational risk scoring.

### Lifecycle

1. An authorized user records a vulnerability and associates affected assets.
2. The vulnerability is assessed for severity, context, ownership, and remediation target.
3. Work is assigned to a user or team; progress is recorded through remediation updates.
4. Status changes reflect the approved remediation workflow.
5. The record is closed when authorized resolution criteria are met; it remains retained for audit and reporting.

### State Transitions

The exact status vocabulary is governed by approved policy. At minimum, a vulnerability progresses through an active remediation lifecycle and may be closed only by an authorized actor. Valid transitions must prevent arbitrary reopening or closure without a documented business reason.

| Transition | Required Business Condition |
| --- | --- |
| new or recorded → active remediation | Severity, ownership or coordination path, and required context have been established as policy requires. |
| active remediation → updated | A progress, ownership, target-date, status, or evidence change is recorded. |
| active remediation → closed | Authorized resolution criteria and required summary or evidence are present. |
| closed → active remediation | Reopening is authorized and the reason is retained in history. |
| any active state → archived | Retention or administrative workflow authorizes archival without losing history. |

### Validation Rules

- Severity, status, description, and required remediation context must be present according to policy.
- Each affected asset must belong to the same organization.
- Owner memberships must be active and belong to the same organization; owner teams must also be organization-local.
- Remediation target dates use UTC and must be meaningful for the selected workflow state.
- A remediation update must identify exactly one parent vulnerability or incident; in this domain it identifies the vulnerability.
- Evidence or references must be authorized, validated, and scoped to the same organization.

### Permission Rules

- Security Managers may oversee, assign, prioritize, and close vulnerabilities when granted the applicable permissions.
- Security Analysts may create and update vulnerabilities and record remediation work according to role.
- Team Members may update assigned work only within granted permissions and organization scope.
- Read-Only Viewers may review authorized vulnerability records without modifying them.

### Relationships

- An organization has many vulnerabilities.
- Vulnerabilities and assets are many-to-many.
- A vulnerability may have one direct owner membership and one coordinating owner team.
- A vulnerability has many remediation updates and may have many evidence objects.
- A vulnerability may be related to many incidents.
- Vulnerability facts feed dashboard widgets, risk scores, audit records, notifications, and enterprise search.

### Events Generated

- Vulnerability created, updated, assigned, unassigned, reprioritized, target date changed, closed, reopened, archived, or restored.
- Affected asset associated or disassociated.
- Remediation update recorded.
- Evidence attached or archived.
- Notification eligibility created for assignment or material status change.
- Organizational risk score requires recalculation when approved contributing inputs change.

### Constraints

- Version 1.0 manages vulnerability records; it does not perform automated vulnerability scanning, ingestion, enrichment, or remediation orchestration.
- Autonomous changes to customer environments are out of scope.
- Only authorized, organization-scoped information is searchable or reportable.

### Examples

- A Security Analyst records a critical vulnerability affecting two production assets, assigns it to a remediation team, and sets a remediation target date.
- A Team Member records a remediation update. The history captures the status and ownership changes, and the assigned users receive relevant in-application notifications.

## 8. Incident Management Domain

### Purpose

Coordinate and retain the lifecycle of confirmed or suspected security incidents, from initial tracking through containment and resolution.

### Responsibilities

- Create, view, update, assign, and close incident records.
- Capture severity, status, timeline, affected assets, owner, response team, containment actions, and resolution summary.
- Associate incidents with assets and vulnerabilities.
- Preserve auditable incident activity and status history.

### Business Rules

- Every incident belongs to one organization.
- An incident may reference many affected assets and many related vulnerabilities.
- An incident may have an accountable owner membership and a response team; both must be in the same organization.
- Material timeline, status, ownership, containment, and resolution changes are retained as activity history.
- Closure requires an authorized actor and a resolution summary as required by policy.
- An incident’s status and context contribute to authorized dashboard and risk views according to the approved methodology.

### Lifecycle

1. An authorized user creates an incident for a confirmed or suspected security event.
2. The incident is assessed, assigned, and associated with affected assets and relevant vulnerabilities.
3. Responders update the timeline, containment actions, ownership, and status.
4. The incident is resolved and closed with an authorized resolution summary.
5. The closed record remains available for audit, reporting, and permitted reopening.

### State Transitions

The approved policy defines exact incident statuses. The domain requires a traceable active response lifecycle with containment and resolution milestones.

| Transition | Required Business Condition |
| --- | --- |
| recorded → active response | Incident has sufficient initial context and an authorized response path. |
| active response → contained | Containment action and time are recorded when containment is claimed. |
| active response or contained → resolved | Resolution summary and required investigation context are recorded. |
| resolved → closed | An authorized actor confirms closure under policy. |
| closed → active response | Reopening is authorized and the reason is retained. |

### Validation Rules

- Incident title, severity, status, and required response context must be present.
- Affected assets and related vulnerabilities must belong to the same organization.
- Owner membership and response team must be valid for the organization.
- Containment time cannot precede the incident’s recorded opening time; resolution time cannot precede the relevant incident milestones.
- A resolution summary is required when the incident enters a resolution or closure state if policy requires it.
- Remediation updates must identify the incident as their single parent when they record incident activity.

### Permission Rules

- Security Managers may oversee incident assignment, status, containment, resolution, and closure when authorized.
- Security Analysts may create, investigate, update, and record incident actions according to role.
- Team Members may perform and document assigned response work within their permissions.
- Read-Only Viewers can review only authorized incident information.

### Relationships

- An organization has many incidents.
- Incidents and assets are many-to-many.
- Incidents and vulnerabilities are many-to-many.
- An incident may have one owner membership and one response team.
- An incident has many remediation updates and may have many evidence objects.
- Incident facts feed dashboards, risk summaries, audit records, notifications, and authorized search.

### Events Generated

- Incident created, updated, assigned, severity changed, contained, resolved, closed, reopened, archived, or restored.
- Asset or vulnerability associated or disassociated.
- Containment action, timeline update, resolution summary, or remediation update recorded.
- Notification eligibility created for assignment or material status change.
- Organizational risk score requires recalculation when approved contributing incident inputs change.

### Constraints

- Version 1.0 is an incident-management record and workflow capability, not a security-information and event-management or endpoint-detection-and-response platform.
- Automated incident ingestion and response orchestration are out of scope.
- The domain does not authorize production changes in customer environments.

### Examples

- A Security Manager opens a high-severity incident, assigns a response team, links two affected assets and a related vulnerability, and records containment actions.
- After investigation, an authorized analyst adds a resolution summary. The manager closes the incident, preserving the timeline and audit history.

## 9. Dashboards and Risk Scoring Domain

### Purpose

Provide authorized, actionable views of organization security posture and a documented organizational risk score that helps users prioritize security work.

### Responsibilities

- Present organization-scoped dashboard widgets for assets, vulnerabilities, incidents, remediation, and organizational risk summaries.
- Allow authorized users to configure approved widgets and their layout within role and policy limits.
- Calculate organizational risk scores using the approved, configurable methodology.
- Present the score timestamp and sufficient authorized context to understand material contributors.
- Preserve traceability for risk-score configuration and calculated results.

### Business Rules

- Dashboard data is organization-scoped and filtered to the requesting membership’s permissions.
- A dashboard widget is an instance of an approved widget type; Version 1.0 does not support customer-developed widget types.
- A user’s dashboard configuration affects presentation, not authorization or the underlying record set.
- A risk score is derived from the documented methodology using vulnerability severity, exposure, remediation state, and approved business context.
- A calculated score must retain its calculation time and the configuration version used.
- Changing risk-score configuration does not alter the historic meaning of an already retained score snapshot.

### Lifecycle

1. An authorized user views a dashboard based on their organization and permissions.
2. The user configures permitted widgets and layout.
3. Approved changes to contributing security data or risk configuration cause a recalculation workflow.
4. A timestamped score snapshot is retained and shown with authorized contributor context.
5. Historical configurations and score snapshots remain traceable for reporting and audit.

### State Transitions

| Concept | Valid Transitions |
| --- | --- |
| Dashboard configuration | absent → active; active → updated; active → replaced by a new active configuration under approved workflow |
| Dashboard widget | configured → updated, reordered, or removed; removal affects presentation only |
| Risk-score configuration | draft or inactive → effective; effective → superseded by a new effective configuration; superseded → archived for history |
| Risk-score snapshot | calculated → retained historical result; a snapshot is not overwritten |

### Validation Rules

- A dashboard configuration belongs to one organization membership and organization.
- Widget type, configuration, and display placement must be from the approved Version 1.0 set and comply with the user’s role and organization policy.
- Risk-score configuration values must follow the documented methodology and approved weighting constraints.
- Each score snapshot must identify the organization, calculation time, configuration used, numeric score, and approved contributor summary.
- Dashboard and risk views exclude records outside the requester’s organization or permissions.

### Permission Rules

- Authorized users may view dashboard information allowed by their role.
- A user may configure only their permitted dashboard layout and widgets.
- Organization Administrators or other specifically authorized roles may manage risk-score configuration.
- Read-Only Viewers can view approved widgets and score information but cannot alter configuration.

### Relationships

- A dashboard configuration belongs to one membership in one organization and contains many dashboard widgets.
- An organization has many risk-score configurations and many immutable calculated score snapshots.
- Each score snapshot references the configuration used to calculate it.
- Assets, vulnerabilities, incidents, remediation state, and approved business context are score inputs and dashboard sources.

### Events Generated

- Dashboard configuration created, updated, widget added, removed, or reordered.
- Risk-score configuration created, activated, superseded, or archived.
- Organizational risk score calculated or recalculated.
- Dashboard or score view accessed when audit policy defines the access as auditable.

### Constraints

- Performance targets for dashboards, risk views, and enterprise search require approval before production release.
- Predictive analytics, threat-intelligence correlation, and customer-defined risk models are out of scope.
- Scheduled reporting and custom dashboard-widget development are out of scope for Version 1.0.

### Examples

- A Security Manager configures approved widgets showing overdue vulnerabilities, open incidents, and the current organizational risk score.
- A vulnerability severity change causes the organization’s score to be recalculated under the active methodology, retaining the calculation timestamp and contributor summary.

## 10. Security Policy Management Domain

### Purpose

Allow authorized Organization Administrators to manage configurable organization security policies while preserving an auditable, traceable history of policy changes.

### Responsibilities

- Create, view, update, activate, and deactivate organization security policies.
- Capture policy name, description, status, applicable scope, configured values, owner, and effective date.
- Retain append-only revisions of material policy content and lifecycle changes.
- Supply approved policy values to the account-security, access, and operational workflows that require them.

### Business Rules

- Every security policy belongs to one organization.
- A policy has a named scope and only affects the approved workflows within that scope.
- A policy change creates a traceable revision; historic configured values are not silently overwritten.
- A policy becomes effective only when active and on or after its effective date.
- Policy values cannot weaken mandatory platform security requirements or bypass RBAC and tenant isolation.
- Password rules, session duration, trusted-device duration, MFA enforcement, risk-score weighting, and security-policy defaults require formal approval before production release.

### Lifecycle

1. An authorized Organization Administrator creates a policy with a scope, values, owner, and effective date.
2. The policy is reviewed and activated through the approved organization workflow.
3. Changes create new revisions and may change future effective behavior.
4. The policy is deactivated when no longer applicable; history remains retained.
5. A policy may be archived under retention rules without erasing its revision history or related audit records.

### State Transitions

| Concept | Valid Transitions |
| --- | --- |
| Security policy | inactive → active; active → inactive; active or inactive → archived |
| Policy revision | created → retained historical revision; revisions are not edited in place |
| Effective behavior | not effective → effective when active and effective date is reached; effective → no longer effective when deactivated or superseded |

### Validation Rules

- Policy name, status, scope, configured values, owner, and effective date are required.
- The owner membership must be active in the policy’s organization.
- Scope and configured values must match an approved Version 1.0 policy category and validation rules.
- Effective dates use UTC and cannot be ambiguous.
- Revision ordering must be unique and sequential for one policy.
- Policy values must satisfy mandatory security constraints and cannot permit cross-organization access.

### Permission Rules

- Only Organization Administrators or roles expressly granted policy-management permissions may create, change, activate, deactivate, or archive policies.
- Security Managers and other roles may view policies only when their permissions grant it.
- Read-Only Viewers cannot alter policy content, state, or revisions.
- Every policy change is auditable with the actor and previous and new business context retained through revision and audit history.

### Relationships

- An organization has many security policies.
- A policy has one or many append-only revisions.
- A membership owns a policy and acts as the actor for its revisions.
- Policies guide approved behavior for account security, dashboards, risk scoring, and other in-scope workflows without becoming a substitute for mandatory platform controls.

### Events Generated

- Security policy created, updated, activated, deactivated, archived, or restored.
- Policy revision created.
- Policy effective date reached or policy superseded where applicable.
- Policy change recorded in audit history.

### Constraints

- Policy-as-code, automated enforcement, and policy-exception approval workflows are out of scope for Version 1.0.
- Policies cannot be used to add unapproved modules or bypass the approved SRS security requirements.

### Examples

- An Organization Administrator activates an approved MFA-enforcement policy with an effective date. Subsequent authentication flows apply it according to the approved account-security rules.
- A policy owner updates the configured session duration. The system retains the prior revision and records the change in the audit log.

## 11. Audit, Notifications, and Search Domain

### Purpose

Provide trustworthy operational evidence, relevant in-application awareness, and authorized discovery of organization security records.

### Responsibilities

- Record defined security-relevant and administrative actions in restricted audit logs.
- Allow authorized users to search and filter organization audit logs by time, actor, event type, and affected record where available.
- Generate in-application notifications for vulnerability and incident assignment and material status changes.
- Allow users to view and acknowledge their notifications.
- Provide organization-scoped enterprise search across authorized assets, vulnerabilities, incidents, users, teams, and audit-log records.

### Business Rules

- Audit records are append-only through ordinary workflows and record the actor, time, event type, organization scope where applicable, and affected record context where available.
- Audit records must not contain passwords, access tokens, secrets, or unnecessary sensitive data.
- A notification belongs to one recipient membership and one organization; it is relevant only while that recipient is authorized for the organization.
- A notification can be acknowledged but is retained according to approved policy.
- Enterprise search returns only records, fields, and navigation actions authorized for the requesting membership.
- Search is organization-scoped; it does not provide cross-tenant discovery.
- Eligible notification processing may occur asynchronously through the approved background task workflow without changing the business authorization decision.

### Lifecycle

1. A security-relevant or administrative action occurs in a source domain.
2. The system records an audit event when policy requires it.
3. Assignment or material change events determine notification eligibility.
4. An eligible notification is created and made available to the recipient.
5. The recipient views or acknowledges the notification.
6. An authorized user searches audit logs or enterprise records within the permitted organization context.

### State Transitions

| Concept | Valid Transitions |
| --- | --- |
| Audit record | recorded → retained; ordinary workflows do not edit or delete it |
| Notification | created → viewed or acknowledged; acknowledged remains retained |
| Search request | submitted → authorized results or denied/no-results; search does not change source records |

### Validation Rules

- Audit event type and time are required; actor and target context are recorded when available.
- Notification recipient must be an active membership in the same organization as the source business record at creation time.
- Notification type must be an approved assignment or material-change category.
- Search terms, filters, and pagination values must be validated, normalized, and constrained under approved policy.
- Search candidates and result fields must be filtered by organization scope and permission before presentation.
- Audit-log filters must use valid time ranges and authorized actor, event-type, and record criteria.

### Permission Rules

- Only authorized roles may review organization audit logs.
- A user may view and acknowledge only their own notifications.
- Enterprise search is available only to roles with the relevant search and source-record permissions.
- Read-Only Viewers may search and review only the record types and fields their role permits.
- No role may use search or audit filters to access another organization’s information.

### Relationships

- Audit records may reference a user, organization membership, and typed target business record.
- Notifications belong to an organization and one recipient membership and may reference a source vulnerability, incident, or other approved record.
- Search reads authorized information from asset, vulnerability, incident, user, team, and audit domains; it does not own a separate Version 1.0 system of record.

### Events Generated

- Audit event recorded.
- Notification created, delivered for in-application availability, viewed, or acknowledged.
- Search performed or audit log accessed when defined as auditable by policy.
- Background notification task queued, processed, or failed for operational handling without exposing sensitive content.

### Constraints

- Notifications are in-application for Version 1.0; expanded notification channels require separate approval.
- Advanced search features, full-text evidence indexing, saved queries, natural-language search, and cross-tenant platform-administrator search are out of scope.
- Audit logs are not a replacement for external security-information and event-management platforms.

### Examples

- A vulnerability is assigned to a Team Member. The assignment is audited, an in-application notification is created for the assignee, and the member can acknowledge it.
- A Security Manager searches for open critical vulnerabilities. Results contain only records in their organization and only fields permitted by their role.

## 12. Evidence and Remediation History Cross-Cutting Model

### Purpose

Retain supporting evidence and a clear, accountable record of remediation work across vulnerability and incident domains.

### Responsibilities

- Associate approved uploaded evidence with vulnerabilities or incidents.
- Retain remediation comments, status changes, owner changes, and relevant work context.
- Preserve authoritative relationships to the parent security record and organization.
- Support permitted review without exposing files or sensitive details to unauthorized users.

### Business Rules

- Evidence belongs to one organization and may be attached only to a vulnerability or incident in that organization.
- Remediation history records one parent domain record at a time: either a vulnerability or an incident.
- A remediation update is authored by an organization membership and is retained as historical context.
- Evidence access requires authorization to the parent record and organization; an object-storage location alone is never access authorization.
- Archived evidence is not available through ordinary workflows but remains subject to approved retention and recovery controls.

### Lifecycle

1. An authorized user uploads or attaches evidence to an approved security record.
2. An authorized user records remediation progress, comments, ownership changes, or status changes.
3. The system retains the historical update and creates required audit events.
4. Evidence may be archived under the approved retention workflow while its relationship and history remain traceable.

### State Transitions

| Concept | Valid Transitions |
| --- | --- |
| Evidence object | active → archived; archived → active only through an authorized restoration workflow |
| Remediation update | created → retained historical record; ordinary workflows do not edit it in place |

### Validation Rules

- Evidence file metadata and object references must satisfy approved file-handling policy.
- Evidence and parent records must share organization scope.
- A remediation update must have one valid author membership and exactly one valid parent record.
- Status and ownership changes described in an update must be valid for the parent domain’s lifecycle and authorization rules.
- Upload content and metadata are validated before becoming available to authorized users.

### Permission Rules

- Only users with the parent vulnerability or incident permissions may attach, view, or archive evidence.
- Only authorized users may create remediation updates for the parent record.
- Read-Only Viewers may view only evidence and history available through their permitted parent-record access.
- Object storage never grants direct user access independently of SecureSphere authorization.

### Relationships

- Evidence belongs to one organization and may relate to one approved vulnerability or incident.
- Remediation updates belong to one organization, one author membership, and exactly one vulnerability or incident.
- Evidence and remediation updates contribute to auditability and may be included in authorized record views.

### Events Generated

- Evidence attached, viewed where auditable, archived, or restored.
- Remediation update recorded.
- Parent record status, ownership, or evidence context changed.
- Required audit record created.

### Constraints

- Version 1.0 supports approved object storage through MinIO or AWS S3; it does not introduce a separate document-management module.
- Full-text evidence indexing is out of scope.
- Uploaded content must follow approved file-handling and retention policy.

### Examples

- A Security Analyst attaches approved remediation evidence to a vulnerability. A Security Manager can review it only through authorized access to that vulnerability.
- A responder adds an incident containment update. The update identifies the actor and parent incident and remains in the incident’s history after closure.

## 13. Domain Model Boundaries

The Version 1.0 domain model deliberately excludes autonomous remediation, security scanning, endpoint detection and response, security information and event management, external ticketing integration, enterprise identity-provider integration, hardware-key MFA, device posture assessment, advanced analytics, custom dashboard development, policy-as-code, and regional data-residency capabilities.

Future extensions must retain SecureSphere’s domain-wide rules: explicit organization scope, active membership-based authority, server-side RBAC, auditable change, secure handling of sensitive data, lifecycle preservation, and clear separation between business behavior and presentation.
