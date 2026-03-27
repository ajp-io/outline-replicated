# Outline → Replicated Onboarding Rubric

## Core Platform (Required Baseline)

| Feature | Points | Rationale |
|---|---|---|
| Replicated SDK subchart (`Chart.yaml` dep + `values.yaml`) | 5 | Standard onboarding step; no external setup |
| Image proxying (all 5 images through `proxy.replicated.com`) | 5 | Mechanical but requires understanding pull secrets and Bitnami's split registry/repo pattern |
| `imagePullSecrets` helper in `_helpers.tpl` | 5 | Template authoring; merging global + local + Replicated secret correctly |
| Admin Console config page (`config.yaml`) with app_url + passwords | 5 | Core KOTS skill; auto-generated passwords with `RandomString` |
| `helmchart.yaml` value mapping | 5 | Maps config → Helm values; required for any config to work |
| `application.yaml` (title, icon, statusInformer, port forward) | 3 | Low complexity; just metadata |
| `values.schema.json` updated for `replicated` key | 2 | One-line schema fix; often forgotten until broken |

**Core subtotal: 30 pts**

---

## Infrastructure Features

| Feature | Points | Rationale |
|---|---|---|
| Ingress + TLS wiring in `helmchart.yaml` (strip `https://` from `app_url`, cert-manager annotation) | 8 | Requires understanding KOTS template string manipulation; non-obvious |
| cert-manager + ingress-nginx HelmChart manifests (embedded-cluster only, weight 0) | 6 | Install ordering, distribution-conditional exclusion, DaemonSet + hostNetwork for embedded |
| `ClusterIssuer` template (`certManager.createClusterIssuer`, `customerEmail` injection) | 8 | Custom template, conditional render, uses Replicated-injected values |
| External PostgreSQL toggle (`db_external_enabled`, conditional field visibility) | 6 | Conditional config fields; inverse boolean for `postgresql.enabled`; extra mapping complexity |
| Redis ioredis entrypoint workaround (custom `files/entrypoint.sh`, ConfigMap, Deployment command override) | 10 | Most complex infrastructure item — requires discovering ioredis URL format, writing a shell script, adding a ConfigMap template, modifying Deployment |
| Security contexts (`runAsNonRoot`, `allowPrivilegeEscalation: false`, etc.) | 4 | Good practice; low difficulty |

**Infrastructure subtotal: 42 pts**

---

## Authentication Methods *(pick any)*

| Feature | Points | Rationale |
|---|---|---|
| Magic Link / SMTP (conditional SMTP fields) | 8 | Requires setting up an SMTP provider (e.g. SendGrid, Postmark), configuring conditional field visibility |
| Slack OAuth auth | 10 | Must create Slack app, configure OAuth redirect URIs, add scopes |
| Auth0 OIDC | 10 | Must create Auth0 tenant + application, configure callback URLs |
| GitLab OIDC | 8 | Same as Auth0 but GitLab is self-hostable; simpler tenant story |
| Gitea OIDC | 8 | Same as GitLab; less common so less documentation available |

---

## Third-Party Integrations *(pick any)*

| Feature | Points | Rationale |
|---|---|---|
| Slack integration (slash commands, unfurling) | 10 | Separate from auth — requires a different Slack app setup, bot token scopes, slash command endpoints |
| GitHub integration (GitHub App, PEM private key) | 12 | GitHub App creation is more involved than OAuth; requires PEM key field (large secret), app ID, installation |
| Linear integration | 8 | OAuth app setup on Linear; straightforward compared to GitHub |
| Sentry | 4 | Just a DSN; free account, one config field |

---

## Custom Subchart: Iframely

| Feature | Points | Rationale |
|---|---|---|
| `iframely/` Helm subchart from scratch (Deployment, Service, image proxied) | 15 | Writing a complete subchart; proxying the image; conditional dependency in parent chart |
| `ALLOWED_PRIVATE_IP_ADDRESSES` env var + conditional in `helmchart.yaml` | 5 | Required for Outline to reach the in-cluster service; easy to miss |

**Iframely subtotal: 20 pts**

---

## Scoring Summary

| Category | Max Points |
|---|---|
| Core Platform | 30 |
| Infrastructure | 42 |
| Authentication (any 2) | ~20 |
| Third-Party Integrations (any 3) | ~26 |
| Custom Subchart (Iframely) | 20 |
| **Total (example)** | **~138** |

**Suggested passing bar:** 80 pts — must complete all Core plus at least 2 auth methods, 2 integrations, and one infrastructure feature beyond basics.

---

## Notes

- The **Redis entrypoint** and **ClusterIssuer template** are the hardest pure-engineering tasks — they require discovering undocumented behaviors and writing custom Helm template logic.
- The **GitHub integration** is the hardest third-party integration due to GitHub App complexity vs. simple OAuth.
- **Iframely** is the only task requiring building a chart from scratch, which is a significant skill gate.
