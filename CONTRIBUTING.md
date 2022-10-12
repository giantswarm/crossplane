## Update from upstream

The CRDs are located at: https://github.com/crossplane/crossplane/tree/master/cluster/crds.

- Copy them over to `helm/crossplane/crd-base` and remove the `pkg.crossplane.io_` prefixes from the file names, because
  they are used as ConfigMap names by the CRD install job, and must be a [valid DNS subdomain name](https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-object).

The original Helm chart is located at: https://github.com/crossplane/crossplane/tree/master/cluster/charts/crossplane.

- Copy all the contents of that folder into `helm/crossplane/`
- Replace `values.yaml` with the contents of the new `values.yaml.tmpl`
  - Keep the `giantswarm` section of the original `values.yaml`
  - Remove `images` section of te upstream `values.yaml`, these are managed under `giantswarm.images` to utilize mirrors
- Update Crossplane image version under `giantswarm.images.crossplane.tag`
- Update all upstream crossplane go templates to use Giant Swarm image mirrors
- You can delete `values.yaml.tmpl`
- When done changing the `values.yaml` please regenerate `values.schema.yaml`
  with `helm schema-gen helm/crossplane/values.yaml > helm/crossplane/values.schema.json`

Update the `Chart.yaml` of the App Chart in `helm/crossplane/Chart.yaml`:

- Update `version` and `appVersion` to the upgraded Crossplane version
