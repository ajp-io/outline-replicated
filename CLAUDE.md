# Outline Replicated

Onboarding the Outline wiki helm chart to Replicated.

## App details
- App slug: `outline-enterprise`
- Test license ID: `3AUjxvP6RUeUACIFOek9aXJjOQC`
- Test username: `alexp@replicated.com`

## Versioning

- **Chart version** (`outline/Chart.yaml`): always kept at the upstream value (e.g. `0.7.3`). Never edit it.
- **Replicated release version**: our own scheme starting at `0.2.0`, independent of the chart version.
  - Increment for every new release (0.2.0 → 0.2.1 → 0.2.2, etc.)
  - This version is visible in the Vendor Portal and channel management only.
  - The OCI registry always tags charts by the Helm chart version (`0.7.3`), so `helm install/pull` will always show the chart version, not the Replicated release version. That's expected.

## Creating a release

The Replicated release version is independent of the chart's upstream version (`Chart.yaml` is
never modified). The chart is packaged as-is (keeping its `0.7.3` version); our version scheme
lives only in `replicated release create --version`.
The `dist/` directory is gitignored and used as a staging area.

**Always run these commands from the repo root**, not from inside `outline/`. Running
`helm package` from inside the chart directory drops a tgz there, which gets bundled into
the next package.

If subchart dependencies have changed, run `helm dependency update ./outline` first.

```bash
VERSION=0.2.3   # increment for each release

# 1. Package outline into dist/ (Chart.yaml version 0.7.3 is preserved — no --version flag)
helm package ./outline
rm -rf dist/outline
tar xzf outline-0.7.3.tgz -C dist
rm outline-0.7.3.tgz

# 2. Pull cert-manager and ingress-nginx charts into dist/
helm repo add jetstack https://charts.jetstack.io || true
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo update jetstack ingress-nginx
helm pull jetstack/cert-manager --version v1.17.2 --untar --untardir dist
helm pull ingress-nginx/ingress-nginx --version 4.11.3 --untar --untardir dist

# 3. Create and promote the release
replicated release create \
  --app outline-enterprise \
  --version $VERSION \
  --promote Unstable
```

`dist/outline` must exist before running `replicated release create` — the CLI does not
fall back to `./outline` if the dist path is missing.

## GCP VM helpers

Use these shell functions/aliases (defined in `~/.zshrc`) for all GCP VM operations — do not use raw `gcloud` equivalents:

- `g-list` — list all GCP VMs
- `g-create <name> [flags]` — create a new GCP VM (zone: us-central1-a)
- `g-create-ssh <name>` — create a VM and open an interactive SSH session once it's ready
- `g-ssh <name> "<cmd>"` — run a command on a VM; omit command for an interactive session
- `g-scp <instance> <local-path> [remote-path]` — copy local file to VM (defaults to `~/`); also supports remote→local and VM→VM
- `g-del <name>` — delete a VM and all its disks
- `g-start <name>` — start a stopped VM and wait until SSH is ready
- `g-airgap <name>` — remove external IP (simulate airgap)
- `g-online <name>` — re-add external IP to a VM
- `g-airgap-access <internal-ip>` — open SSH tunnel to an airgapped VM via jump host

## Testing strategy

- **Embedded cluster installs** — always use a GCP VM (`g-create`, `g-ssh`, `g-scp`)
- **Helm installs** — use a GKE cluster (native LoadBalancer support, customer-representative)

CMX clusters lack cloud load balancers — ingress-nginx won't get an external IP, so DNS/TLS
won't work. GKE is more representative of real customer environments.

Never use GCP VMs or CMX for helm installs.

## Testing a release (Embedded cluster install)

The tarball downloaded from `replicated.app/embedded` contains **both** the installer binary and the license file — no separate license download needed.

### 1. Create a GCP VM
```bash
g-create outline-test
```
Wait for SSH to become available before proceeding.

### 2. Download and extract the embedded cluster installer
```bash
g-ssh outline-test "curl -fL 'https://replicated.app/embedded/outline-enterprise/unstable' -H 'Authorization: 3AUjxvP6RUeUACIFOek9aXJjOQC' | tar -xz"
```
This extracts the `outline-enterprise` binary and `license.yaml` into the home directory.

### 3. Copy config values to the VM
```bash
g-scp outline-test configvalues.yaml
```

### 4. Run the install
```bash
g-ssh outline-test "sudo ./outline-enterprise install --license license.yaml --config-values configvalues.yaml --admin-console-password admin1234"
```
The `--admin-console-password` flag is required — without it the installer prompts interactively and fails over SSH.

### 5. Clean up
```bash
g-del outline-test
```

### Retesting after changes

**Application changed** (manifests, chart templates, values, new release): create a new release, then re-download and reinstall.
If a previous install exists on the VM, reset it first:
```bash
g-ssh outline-test "sudo ./outline-enterprise reset"
```
Then re-download the new binary+license tarball (step 2) and reinstall (step 4). The new binary is required because the release is baked into it.

**Config values only changed** (e.g. `configvalues.yaml`): no new release needed. Just scp the updated file and reinstall:
```bash
g-scp outline-test configvalues.yaml
g-ssh outline-test "sudo ./outline-enterprise reset"
g-ssh outline-test "sudo ./outline-enterprise install --license license.yaml --config-values configvalues.yaml --admin-console-password admin1234"
```

## Testing a release (Helm install)

`helmvalues.yaml` contains test values with all auth methods enabled, mirroring `configvalues.yaml`.

### 1. Create a GKE cluster
```bash
gcloud container clusters create outline-test \
  --zone us-central1-a \
  --num-nodes 2 \
  --machine-type e2-standard-2
```

### 2. Get kubeconfig
```bash
gcloud container clusters get-credentials outline-test --zone us-central1-a
```

### 3. Install prerequisites (customer-provided in real deployments)

cert-manager and ingress-nginx are **not** deployed by the outline chart for helm installs
(they're embedded-cluster-only). Install them first:

```bash
helm repo add jetstack https://charts.jetstack.io || true
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo update jetstack ingress-nginx

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true --wait

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace --wait

# Get the external IP and update DNS before continuing
# outline-1.alexparker.info must point to this IP for cert-manager ACME to work
kubectl -n ingress-nginx get svc ingress-nginx-controller
# Note EXTERNAL-IP — update outline-1.alexparker.info → that IP in your DNS provider, then wait for propagation

# Create the ClusterIssuer (embedded cluster does this via cluster-issuer.yaml template;
# helm installs must do it manually)
kubectl apply -f - <<'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: alex.parker215@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx
EOF
```

### 4. Login to Replicated registry and install
```bash
helm registry login registry.replicated.com \
  --username alexp@replicated.com \
  --password 3AUjxvP6RUeUACIFOek9aXJjOQC

helm install outline \
  oci://registry.replicated.com/outline-enterprise/unstable/outline \
  --namespace outline \
  --create-namespace \
  --values helmvalues.yaml
```

### 5. Clean up
```bash
gcloud container clusters delete outline-test --zone us-central1-a
```

### Smoke test (no DNS/TLS required)

To just verify pods come up without needing a real cluster or DNS (e.g. on CMX):
```bash
helm install outline \
  oci://registry.replicated.com/outline-enterprise/unstable/outline \
  --namespace outline --create-namespace \
  --values helmvalues.yaml \
  --set ingress.enabled=false \
  --set web.forceHttps=false

kubectl -n outline get pods
```

## Chart editing policy

The `outline/` chart is based on community-charts upstream. Changes should be minimal:
- **Allowed without special permission**: `values.yaml` (image repos, Replicated defaults),
  `templates/_helpers.tpl` (adding helpers), `values.schema.json` (allowing new top-level keys
  like `replicated`), `charts/.gitignore`
- **Requires permission**: `Chart.yaml` version, any template logic changes

## Repository structure

```
.replicated          # Replicated CLI config (chart path + manifests glob)
CLAUDE.md            # This file
manifests/
  application.yaml          # Admin Console metadata (title, icon, statusInformers)
  config.yaml               # End-user config page (app_url, passwords, Google OAuth)
  embedded-cluster-config.yaml  # k0s version for embedded cluster installs
  helmchart.yaml            # Maps Config values to Helm values via KOTS templates
  helmchart-cert-manager.yaml   # cert-manager at weight 0, embedded-cluster only
  helmchart-ingress-nginx.yaml  # ingress-nginx at weight 0, embedded-cluster only
outline/
  Chart.yaml         # Upstream chart metadata — do not change version
  values.yaml        # Our customized defaults (proxy images, Replicated settings)
  values.schema.json # JSON schema — we added the `replicated` top-level key
  charts/            # Dependency tarballs only (downloaded by helm dep update)
                     # Unpacked directories are gitignored
  templates/
    _helpers.tpl     # Added replicated.imagePullSecrets helper at end of file
    deployment.yaml  # Uses the helper instead of the original imagePullSecrets block
```
