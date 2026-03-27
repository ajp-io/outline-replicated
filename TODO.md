# Outline Replicated — Feature Backlog

Features identified as gaps against the Replicated onboarding checklist.
Work through these across sessions to achieve full platform coverage.

## To Do

- [ ] **Preflight checks** — Add `manifests/preflight.yaml` with a Preflight resource.
      Useful checks: min memory/CPU, Kubernetes version, storage class exists,
      external PostgreSQL reachability (when `db_external_enabled` is set).

- [ ] **Support bundle** — Add `manifests/support-bundle.yaml` with a SupportBundle resource.
      Collectors: pod logs (outline, redis, postgres, minio), ConfigMaps/Secrets.
      Analyzers: DB connection errors, crashlooping pods, storage issues.

- [ ] **License entitlement gating** — Define a custom license field in the Vendor Portal
      and gate a meaningful Outline feature behind it (e.g. AI/pgvector support, or max
      user seats). Wire the entitlement value into Helm via `LicenseFieldValue` in
      `helmchart.yaml`.

- [ ] **Enterprise Portal** — Enable the customer-facing Enterprise Portal (Vendor Portal
      setting). Understand the install instructions flow, team management, support bundle
      uploads, and instance insights dashboard.

- [ ] **Status informers** — Expand `application.yaml` beyond `deployment/outline` to cover
      all critical workloads: `statefulset/outline-postgresql`, `statefulset/outline-redis`,
      `statefulset/outline-minio`. Admin Console should reflect full app health.

- [ ] **Air gap** — End-to-end test an air gap install. Ensure `builder` in `helmchart.yaml`
      is complete, add any `additionalImages` to `application.yaml` if needed, build an
      air gap bundle, and install on a network-isolated VM.

- [ ] **Custom domains** — Alias Replicated service endpoints to branded domains (e.g.
      `proxy.replicated.com` → `proxy.example.com`, `registry.replicated.com` →
      `registry.example.com`). Configure via the Vendor Portal and wire into the
      `embedded-cluster-config.yaml` domain overrides.

## Done

- [x] Replicated SDK subchart
- [x] Image proxying (all 5 images through `proxy.replicated.com`)
- [x] `imagePullSecrets` helper in `_helpers.tpl`
- [x] Admin Console config page (`config.yaml`)
- [x] `helmchart.yaml` value mapping
- [x] `application.yaml` (title, icon, statusInformer, port forward)
- [x] `values.schema.json` updated for `replicated` key
- [x] Ingress + TLS wiring (cert-manager, ingress-nginx)
- [x] External PostgreSQL toggle
- [x] Custom Iframely subchart
