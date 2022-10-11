## Update from upstream

The CRDs are located at: https://github.com/crossplane/crossplane/tree/master/cluster/crds.

- Copy them over to `helm/crossplane/crd-base` and remove the `pkg.crossplane.io_` prefixes from the file names, because
  they are used as ConfigMap names by the CRD install job, and must be a [valid DNS subdomain name](https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-object).

The original Helm chart is located at: https://github.com/crossplane/crossplane/tree/master/cluster/charts/crossplane.

- Copy all the contents of that folder into `helm/crossplane/charts/crossplane`
- Replace `values.yaml` with the contents of the new `values.yaml.tmpl` and update `image.tag`

Update the `Chart.yaml` of the App Chart in `helm/crossplane/Chart.yaml`:

- Update `appVersion`
- Update `crossplane` version under the `dependencies`
