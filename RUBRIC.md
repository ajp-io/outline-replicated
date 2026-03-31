# Outline Replicated Bootcamp Rubric

## Tier 0: Ship It with Helm

| Task | Pts | Acceptance Criteria | Notes |
|------|-----|---------------------|-------|
| Outline installs via `helm install` and is accessible | 2 | `kubectl get pods -n <namespace>` shows all pods Running; open Outline in a browser | |
| Replicated SDK included as a subchart and running | 1 | `kubectl get pods -n <namespace>` shows the SDK pod in Running state | |
| SDK renamed for branding | 1 | `kubectl get deployment outline-sdk -n <namespace>` succeeds | |
| All container images proxied through `proxy.replicated.com` | 2 | Run `kubectl get pods -A -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.image}{"\n"}{end}{range .spec.initContainers[*]}{.image}{"\n"}{end}{end}' \| sort -u` and show every app image starts with `proxy.replicated.com` | cert-manager and ingress-nginx images are not expected to be proxied — filter to your app namespace if needed |
| 3+ preflight checks covering distinct deployment concerns with clear, actionable pass/warn/fail messages | 4 | Show preflights running twice: once with a condition that causes a check to fail (e.g. password too short, invalid external DB credentials), then again with all checks passing. Failure messages must explain what went wrong and how to fix it. | |

**Tier 0 total: 10 pts**

---

## Tier 1: Ship It on a VM

| Task | Pts | Acceptance Criteria | Notes |
|------|-----|---------------------|-------|
| Outline installs on a bare VM using embedded cluster and is accessible | 3 | Starting from a fresh VM, complete the embedded cluster install. Show `sudo k0s kubectl get pods -A` with all pods Running, then open Outline in a browser. | |
| Config screen has at least 3 meaningful capabilities wired through to Helm | — | *Required threshold — no points on its own. Points come from the tables below.* | |

### Database

| Task | Pts | Acceptance Criteria | Notes |
|------|-----|---------------------|-------|
| External PostgreSQL toggle | 1 | Install twice: once with embedded Postgres (show a postgres pod Running in `sudo k0s kubectl get pods -A`), once with external Postgres (show no postgres pod — Outline is using the external DB). | |

### Auth Methods

| Task | Pts | Acceptance Criteria | Notes |
|------|-----|---------------------|-------|
| Magic link / email | 2 | On the Outline login page, enter an email address. Show the magic link email arriving and successfully logging in. | Requires a working SMTP server. |
| Slack OAuth | 1 | Click "Sign in with Slack" on the Outline login page and complete the flow, landing on the Outline dashboard as an authenticated user. | You can create a free Slack workspace at https://slack.com for testing. |
| Auth0 (OIDC) | 1 | Show the Auth0 login option on the Outline login page and complete the login flow end-to-end. | Free developer account at https://auth0.com |
| GitLab (OIDC) | 1 | Show the GitLab login option on the Outline login page and complete the login flow end-to-end. | Free account at https://gitlab.com |
| Gitea (OIDC) | 1 | Show the Gitea login option on the Outline login page and complete the login flow end-to-end. | Free account at https://codeberg.org (Gitea-powered) |

### Integrations

| Task | Pts | Acceptance Criteria | Notes |
|------|-----|---------------------|-------|
| Iframely rich embeds | 3 | Show the iframely pod Running in `kubectl get pods -n <namespace>`. In an Outline document, paste a YouTube or Twitter/X URL and show it rendering as a rich embedded preview. | No official Helm chart exists for iframely — you'll need to write one from scratch and add it as a local dependency in your chart's `Chart.yaml`. It must deploy the iframely container and expose it on a named ClusterIP service reachable by Outline. |
| Slack integration — slash commands | 1 | In Slack, run `/outline search <term>` and show results returned from your Outline instance. | You can create a free Slack workspace at https://slack.com for testing. |
| Slack integration — message actions | 1 | Open the context menu on a Slack message (hover → "More actions"), show an Outline action available, invoke it, and show the result (e.g. the message content saved to an Outline document). | Same Slack workspace as above. |
| Linear link unfurling | 1 | Paste a Linear issue URL into an Outline document and show it rendering as a rich link preview. | |
| GitHub App link previews | 1 | Paste a GitHub URL (repo, issue, or PR) into an Outline document and show the link preview rendering. | |
| Sentry error tracking | 1 | Configure a Sentry DSN. Scale the database to 0 replicas, then attempt to load Outline. Show the resulting error appearing in the Sentry dashboard. | Free account at https://sentry.io. Scaling the database to 0 is a reliable way to trigger a visible error. |

### Config Screen Enhancements

| Task | Pts | Acceptance Criteria | Notes |
|------|-----|---------------------|-------|
| Generated default value | 1 | Leave the embedded DB password blank in the config screen and show Outline installs and runs successfully — the password was auto-generated. | A common failure: the generated value changes on upgrade, the DB pod can't connect, and the pod fails to start. Your upgrades demo (Tier 2) must show all pods still Running after upgrade. |
| Input validation | 1 | Attempt to proceed with an invalid config value and show the config screen blocking progress with a clear validation message. | |

**Tier 1 total: 3 pts fixed + up to 15 pts from capabilities tables**

---

## Tier 2: Production Readiness

| Task | Pts | Acceptance Criteria | Notes |
|------|-----|---------------------|-------|
| App icon and name set correctly | 1 | Screenshot of the KOTS Admin Console showing the correct Outline icon and app name. | |
| Enterprise portal custom branding | 1 | Screenshot of the Enterprise Portal showing custom branding applied. | |
| License entitlement that gates a real product feature | 3 | Show the license field defined in the Vendor Portal. Install with the entitlement disabled — show the feature is unavailable. Update the license to enable it — show the feature becomes available. The feature must be user-visible. | The feature you gate is your choice. |
| Air-gapped install | 3 | Build an air gap bundle from your release. Transfer it to a VM. Complete the install using only the bundle. Show all pods Running with `sudo k0s kubectl get pods -A` and open Outline's login page in a browser. | Online network access during the demo is fine — the test is that the install uses only the bundle. To fully simulate air gap, remove the VM's external IP after transferring the bundle, then install. |
| In-place upgrade without data loss | 3 | Install release 1. Create a document in Outline. Trigger the upgrade to release 2 via the Admin Console. Show the document still present and all pods Running after upgrade. | If your DB password changes on upgrade, the database pod won't be able to connect and will fail to start. All pods Running after upgrade confirms the password persisted correctly. |
| Support bundle with 2+ actionable analyzers | 3 | Run the support bundle and show the analyzer results with at least 2 checks surfacing meaningful pass/warn/fail states. Briefly explain what each analyzer checks and why it matters for debugging Outline. | |
| Custom domains configured | 2 | Screenshot of all custom domains configured in the Vendor Portal. | You'll need a domain you own or can purchase (expense it). Create the appropriate DNS records pointing to your installation. |

**Tier 2 total: 16 pts**
